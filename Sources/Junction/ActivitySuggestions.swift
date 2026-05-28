import Foundation
import Combine

/// A standing nudge to turn repeated manual picks into a rule.
///
/// Derived purely from the Activity log: when the user manually picks the
/// same browser for the same host 2+ times inside a rolling 7-day window,
/// Junction surfaces a pill on that row; at 3+ it raises a one-time banner
/// above the list ("Make it a rule?"). Nothing extra is persisted — the
/// counts fall out of the entries `URLLog` already stores.
struct PickSuggestion: Equatable {
    let host: String
    /// Display name of the browser the user kept choosing.
    let browser: String
    /// Profile of that browser at the most-recent pick, if any.
    let profile: String?
    /// Bundle ID of that browser at the most-recent pick, if known —
    /// lets the banner build a precise rule target.
    let bundleID: String?
    /// Manual picks for this (host, browser) inside the window.
    let count: Int
    /// Timestamp of the most-recent qualifying pick. Orders competing
    /// suggestions (freshest wins) and dates the "this week" copy.
    let lastPicked: Date
    /// Id of the most-recent qualifying entry, so the banner can reuse
    /// `URLLog.Entry.suggestedRule()` to prefill the Rules editor.
    let entryID: UUID
}

/// Identifies a (host, browser) pair. A struct rather than a tuple so the
/// tally can be a `Dictionary` key (and to stay clear of SwiftLint's
/// `large_tuple` rule).
struct SuggestionKey: Hashable {
    let host: String
    let browser: String
}

/// Pure functions over the activity log. Kept separate from `URLLog` so
/// they're trivially unit-testable with synthetic entries and a fixed
/// `now`.
enum ActivitySuggestions {

    /// Rolling window the counts are measured over: 7 days.
    static let window: TimeInterval = 7 * 24 * 60 * 60

    /// Tally manual picks per (host, browser) inside the trailing window.
    /// Keyed so a row can find its own count in O(1). The carried
    /// `profile`/`bundleID`/`entryID` always reflect the most-recent pick
    /// in the bucket, which is what a rule built from the suggestion
    /// should target.
    static func tally(
        _ entries: [URLLog.Entry],
        now: Date = Date()
    ) -> [SuggestionKey: PickSuggestion] {
        let cutoff = now.addingTimeInterval(-window)
        var result: [SuggestionKey: PickSuggestion] = [:]
        for entry in entries where entry.receivedAt >= cutoff {
            guard case let .routed(browser, .picker) = entry.routing,
                  let host = (entry.rewritten ?? entry.url).host, !host.isEmpty
            else { continue }
            let key = SuggestionKey(host: host, browser: browser)
            guard let existing = result[key] else {
                result[key] = PickSuggestion(
                    host: host, browser: browser,
                    profile: entry.routedProfile, bundleID: entry.routedBundleID,
                    count: 1, lastPicked: entry.receivedAt, entryID: entry.id
                )
                continue
            }
            let newer = entry.receivedAt > existing.lastPicked
            result[key] = PickSuggestion(
                host: host, browser: browser,
                profile: newer ? entry.routedProfile : existing.profile,
                bundleID: newer ? entry.routedBundleID : existing.bundleID,
                count: existing.count + 1,
                lastPicked: newer ? entry.receivedAt : existing.lastPicked,
                entryID: newer ? entry.id : existing.entryID
            )
        }
        return result
    }

    /// The one suggestion worth a banner right now: count ≥ 3, host not
    /// dismissed, strongest first (count, then recency). `nil` when
    /// nothing qualifies.
    static func banner(
        from entries: [URLLog.Entry],
        dismissedHosts: Set<String>,
        now: Date = Date()
    ) -> PickSuggestion? {
        tally(entries, now: now).values
            .filter { $0.count >= 3 && !dismissedHosts.contains($0.host) }
            .max { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count < rhs.count }
                return lhs.lastPicked < rhs.lastPicked
            }
    }
}

/// Remembers which suggestion banners the user dismissed, so they stay
/// hidden for 7 days per host. Backed by `UserDefaults` (a tiny
/// `[host: dismissedAt]` map); observable so a dismissal updates the
/// Activity tab immediately.
@MainActor
final class SuggestionDismissals: ObservableObject {

    static let shared = SuggestionDismissals()

    private let key = "JunctionDismissedSuggestions"
    private let defaults: UserDefaults

    /// Mirror of the persisted map; `@Published` so the view recomputes
    /// the banner when it changes.
    @Published private var dismissedAt: [String: Date]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.dictionary(forKey: key) as? [String: Double] {
            dismissedAt = raw.mapValues { Date(timeIntervalSince1970: $0) }
        } else {
            dismissedAt = [:]
        }
    }

    /// Hosts whose banner is still suppressed at `now`.
    func activeHosts(now: Date = Date()) -> Set<String> {
        let cutoff = now.addingTimeInterval(-ActivitySuggestions.window)
        return Set(dismissedAt.filter { $0.value >= cutoff }.keys)
    }

    /// Suppress this host's banner for the next 7 days. Prunes expired
    /// entries opportunistically so the map can't grow unbounded.
    func dismiss(host: String, now: Date = Date()) {
        let cutoff = now.addingTimeInterval(-ActivitySuggestions.window)
        dismissedAt = dismissedAt.filter { $0.value >= cutoff }
        dismissedAt[host] = now
        defaults.set(
            dismissedAt.mapValues { $0.timeIntervalSince1970 },
            forKey: key
        )
    }
}
