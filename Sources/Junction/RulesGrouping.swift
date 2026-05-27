import Foundation
import AppKit

/// How the Rules sidebar groups rules in the list view. Choice is
/// persisted per-window via `@AppStorage("JunctionRulesGrouping")` so
/// users don't have to re-pick it every time they open Settings.
///
/// The pill in the sidebar header opens a popover that lets the user
/// switch between these.
enum RulesGrouping: String, CaseIterable, Equatable {
    /// Group by `rule.target.browserBundleID`. The default — matches the
    /// most common "I want to see all the things that go to Chrome"
    /// mental model.
    case destination

    /// Group by `rule.sourceApps`. A rule with multiple source apps is
    /// cross-listed in each group (it really does belong to all of
    /// them). Empty `sourceApps` lands in a single "Any source" bucket.
    case sourceApp

    /// Group by the kind of `Matcher` the rule uses — host / regex /
    /// contains / prefix / any. Useful for power users debugging
    /// patterns.
    case matchType

    /// No grouping. Flat list, no headers — the simplest view for
    /// users with a handful of rules.
    case flat

    /// Short word that goes into the "grouped by [X ▾]" pill.
    var pillLabel: String {
        switch self {
        case .destination: return "destination"
        case .sourceApp:   return "source app"
        case .matchType:   return "match type"
        case .flat:        return "nothing"
        }
    }

    /// Secondary text shown under each option in the popover menu.
    var menuSubtitle: String {
        switch self {
        case .destination: return "by target browser"
        case .sourceApp:   return "Slack, Mail…"
        case .matchType:   return "host / regex"
        case .flat:        return "flat list"
        }
    }

    /// Primary title shown for each option in the popover menu.
    var menuTitle: String {
        switch self {
        case .destination: return "Destination"
        case .sourceApp:   return "Source app"
        case .matchType:   return "Match type"
        case .flat:        return "Nothing"
        }
    }
}

// MARK: - RuleGroup

/// One group of rules rendered as a section in the sidebar. The `icon`
/// field tells the section header how to draw its leading glyph — a
/// real browser/app icon, an SF Symbol, or no icon at all.
struct RuleGroup: Identifiable, Equatable {
    let id: String              // stable key per group within a grouping
    let displayName: String     // header text; empty for `.flat`
    let icon: Icon
    let rules: [Rule]

    enum Icon: Equatable {
        case browser(bundleID: String)
        case app(bundleID: String)
        case symbol(String)
        case none
    }

    var hasHeader: Bool { icon != .none && !displayName.isEmpty }
}

// MARK: - Group building

extension RulesGrouping {

    /// Bucket `rules` according to this grouping. Sort order is
    /// stable and human-meaningful (alphabetical for browsers / apps,
    /// declaration order for match types).
    func buckets(of rules: [Rule]) -> [RuleGroup] {
        switch self {
        case .destination: return byDestination(rules)
        case .sourceApp:   return bySourceApp(rules)
        case .matchType:   return byMatchType(rules)
        case .flat:        return flat(rules)
        }
    }

    private func byDestination(_ rules: [Rule]) -> [RuleGroup] {
        let buckets = Dictionary(grouping: rules, by: \.target.browserBundleID)
        return buckets
            .map { bundleID, group in
                RuleGroup(
                    id: bundleID,
                    displayName: appDisplayName(bundleID: bundleID),
                    icon: .browser(bundleID: bundleID),
                    rules: group
                )
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Cross-list rules: a rule with two source apps appears in both
    /// groups. That's the "rule belongs to both" semantics — the rule
    /// fires for either source, so it should be visible under either.
    /// Rules with no source apps land in a single "Any source" group.
    private func bySourceApp(_ rules: [Rule]) -> [RuleGroup] {
        var byApp: [String: [Rule]] = [:]
        var anySource: [Rule] = []
        for rule in rules {
            if rule.sourceApps.isEmpty {
                anySource.append(rule)
            } else {
                for app in rule.sourceApps {
                    byApp[app, default: []].append(rule)
                }
            }
        }
        var groups: [RuleGroup] = byApp
            .map { bundleID, group in
                RuleGroup(
                    id: "src:\(bundleID)",
                    displayName: appDisplayName(bundleID: bundleID),
                    icon: .app(bundleID: bundleID),
                    rules: group
                )
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        if !anySource.isEmpty {
            // "Any source" leads — it's the broadest bucket.
            groups.insert(
                RuleGroup(
                    id: "src:_any",
                    displayName: "Any source",
                    icon: .symbol("globe"),
                    rules: anySource
                ),
                at: 0
            )
        }
        return groups
    }

    /// Definition of one match-type bucket. Lifted out of a 4-tuple
    /// inside `byMatchType` to satisfy SwiftLint's `large_tuple`.
    private struct MatchKindBucket {
        let id: String
        let label: String
        let symbol: String
        let predicate: (Matcher) -> Bool
    }

    private func byMatchType(_ rules: [Rule]) -> [RuleGroup] {
        // Declaration order: host / regex / contains / prefix / any.
        // Stable across runs even if Swift's Dictionary ordering shifts.
        let order: [MatchKindBucket] = [
            MatchKindBucket(id: "host", label: "Host", symbol: "network",
                            predicate: { if case .host = $0 { return true }; return false }),
            MatchKindBucket(id: "hostRegex", label: "Host regex", symbol: "asterisk",
                            predicate: { if case .hostRegex = $0 { return true }; return false }),
            MatchKindBucket(id: "urlContains", label: "URL contains", symbol: "text.magnifyingglass",
                            predicate: { if case .urlContains = $0 { return true }; return false }),
            MatchKindBucket(id: "urlPrefix", label: "URL prefix", symbol: "link",
                            predicate: { if case .urlPrefix = $0 { return true }; return false }),
            MatchKindBucket(id: "any", label: "Any URL", symbol: "globe",
                            predicate: { if case .any = $0 { return true }; return false })
        ]
        return order.compactMap { bucket in
            let matched = rules.filter { bucket.predicate($0.match) }
            guard !matched.isEmpty else { return nil }
            return RuleGroup(
                id: "match:\(bucket.id)",
                displayName: bucket.label,
                icon: .symbol(bucket.symbol),
                rules: matched
            )
        }
    }

    private func flat(_ rules: [Rule]) -> [RuleGroup] {
        guard !rules.isEmpty else { return [] }
        return [RuleGroup(id: "flat", displayName: "", icon: .none, rules: rules)]
    }

    // MARK: - Helpers

    private func appDisplayName(bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default
                .displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }
}
