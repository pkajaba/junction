import SwiftUI
import AppKit

/// Settings → Activity tab.
///
/// Reads `URLLog.shared` for the in-memory list of every URL Junction has
/// handled since launch and renders it as a row-per-entry log: time on
/// the left, host + path + source-app subline in the middle, and an
/// outcome block on the right (rule match / picker / skipped). A filter
/// bar above the list narrows the view by outcome; counts on each chip
/// surface how many entries fall into each bucket.
///
/// Hover-to-create-rule + persistence + the manual-pick suggestion
/// counter are tracked separately — see `design/handoff_round2/`. This
/// pass lands the row shape, filter chips, and the new copy.
struct DebugLogView: View {
    // URLLog.shared is the canonical, app-wide instance — observed
    // directly so the tab works standalone inside the Settings TabView.
    @ObservedObject private var log = URLLog.shared
    @ObservedObject private var ruleStore = RuleStore.shared
    @State private var filter: ActivityFilter = .all
    /// Selected row, so ⌘R knows which entry to turn into a rule.
    @State private var selectedEntryID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let error = ruleStore.lastError {
                errorBanner(error)
            }
            filterBar
            Divider()
            content
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.title2.weight(.semibold))
                Text("Every link Junction has handled. Hover any row to make it into a rule.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button("Export…", action: exportLog)
                .disabled(log.entries.isEmpty)
                .controlSize(.small)
            Button("Clear", action: log.clear)
                .disabled(log.entries.isEmpty)
                .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    /// Write the activity log to a user-chosen `.jsonl` file. Same format
    /// Junction persists internally — one JSON object per line — so it's
    /// easy to grep or pipe into jq.
    private func exportLog() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "junction-activity.jsonl"
        panel.canCreateDirectories = true
        panel.title = "Export Activity Log"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? log.exportJSONL().write(to: url, atomically: true, encoding: .utf8)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.08))
    }

    // MARK: - Filter chips

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(ActivityFilter.allCases, id: \.self) { kind in
                FilterChip(
                    filter: kind,
                    count: kind.count(in: log.entries),
                    isSelected: filter == kind
                ) {
                    filter = kind
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if log.entries.isEmpty {
            empty
        } else {
            list
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.circle")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No URLs yet")
                .font(.title3.weight(.semibold))
            VStack(spacing: 4) {
                Text("Set Junction as your default browser, then click a link anywhere.")
                Text("Matching rules route silently; the rest pop up the picker — and end up here.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var list: some View {
        let entries = filtered
        return Group {
            if entries.isEmpty {
                filteredEmpty
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            ActivityRowView(
                                entry: entry,
                                isSelected: entry.id == selectedEntryID,
                                onSelect: { selectedEntryID = entry.id },
                                onCreateRule: { createRule(from: entry) }
                            )
                            Divider()
                        }
                    }
                }
                // Invisible ⌘R trigger — creates a rule from the selected
                // no-match row. Lives here (not per-row) so the shortcut
                // is registered once and routed to the selection.
                .background(
                    Button("", action: createRuleFromSelected)
                        .keyboardShortcut("r", modifiers: .command)
                        .opacity(0)
                        .accessibilityHidden(true)
                )
            }
        }
    }

    private func createRule(from entry: URLLog.Entry) {
        guard let rule = entry.suggestedRule() else { return }
        SettingsCoordinator.shared.createRuleAndReveal(rule)
    }

    private func createRuleFromSelected() {
        guard let id = selectedEntryID,
              let entry = log.entries.first(where: { $0.id == id })
        else { return }
        createRule(from: entry)
    }

    private var filteredEmpty: some View {
        VStack(spacing: 6) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("Nothing matches this filter")
                .font(.callout.weight(.medium))
            Text("Pick a different chip above or click **Clear** in the upper-right.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var filtered: [URLLog.Entry] {
        log.entries.reversed().filter(filter.includes)
    }
}

// MARK: - Filter model

/// Which outcomes the Activity tab shows. Drives the chip bar above the
/// list and the per-chip counts.
enum ActivityFilter: String, CaseIterable, Equatable {
    case all
    case matched
    case pickerNoMatch
    case errors

    var label: String {
        switch self {
        case .all:           return "All"
        case .matched:       return "Matched a rule"
        case .pickerNoMatch: return "No rule · picker"
        case .errors:        return "Errors"
        }
    }

    func includes(_ entry: URLLog.Entry) -> Bool {
        switch self {
        case .all:
            return true
        case .matched:
            if case .routed(_, .rule) = entry.routing { return true }
            if case .routed(_, .handoff) = entry.routing { return true }
            return false
        case .pickerNoMatch:
            if case .routed(_, .picker) = entry.routing { return true }
            return false
        case .errors:
            switch entry.routing {
            case .failed, .unsupported: return true
            default: return false
            }
        }
    }

    func count(in entries: [URLLog.Entry]) -> Int {
        entries.lazy.filter(self.includes).count
    }
}

// MARK: - Filter chip

private struct FilterChip: View {
    let filter: ActivityFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(filter.label)
                Text("\(count)")
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
            }
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.07))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color(nsColor: .separatorColor),
                                  lineWidth: isSelected ? 0 : 0.5)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("\(filter.label) — \(count) ^[\(count) entry](inflect: true)")
    }
}

// MARK: - Create-rule suggestion

extension URLLog.Entry {
    /// A rule prefilled from this entry — the payload behind the
    /// Activity tab's "Create rule" affordance. Returns nil unless this
    /// was a *picker-manual* outcome (the only case where the user made
    /// a choice no rule captured) with a resolvable host and target.
    ///
    /// Target bundle ID comes from `routedBundleID` when present; for
    /// entries logged before that field existed, we fall back to
    /// resolving the recorded display name against the detected browser
    /// list. Uses `.host(host)`, which matches subdomains natively — the
    /// "include subdomains = on" the handoff spec asks for.
    ///
    /// `@MainActor` because the display-name fallback touches
    /// `BrowserDetector.shared`; it's only ever called from view code.
    @MainActor
    func suggestedRule() -> Rule? {
        guard case let .routed(browserName, .picker) = routing,
              let host = (rewritten ?? url).host, !host.isEmpty
        else { return nil }
        let bundleID = routedBundleID
            ?? BrowserDetector.shared.detectAll()
                .first(where: { $0.displayName == browserName })?.bundleID
        guard let bundleID else { return nil }
        return Rule(
            name: "\(host) → \(browserName)",
            match: .host(host),
            target: Target(browserBundleID: bundleID, profile: routedProfile)
        )
    }
}

// MARK: - Previews

#Preview("With entries") {
    let log = URLLog.shared
    log.clear()
    let id1 = log.append(URL(string: "https://github.com/pkajaba/junction")!,
                         source: .openURLs, sourceApp: "com.tinyspeck.slackmacgap")
    let id2 = log.append(URL(string: "https://docs.google.com/document/d/abc")!,
                         source: .openURLs, sourceApp: "com.apple.mail")
    let id3 = log.append(URL(string: "https://news.ycombinator.com")!,
                         source: .appleEvent, sourceApp: nil)
    let id4 = log.append(URL(string: "https://example.com/failing")!,
                         source: .openURLs, sourceApp: nil)
    let id5 = log.append(URL(string: "mailto:hello@example.com")!,
                         source: .openURLs, sourceApp: nil)
    log.updateRouting(for: id1, to: .routed(to: "Chrome", via: .rule(name: "github → work Chrome")),
                      profile: "Work")
    log.updateRouting(for: id2, to: .routed(to: "Chrome", via: .rule(name: "Google Workspace")))
    log.updateRouting(for: id3, to: .routed(to: "Safari", via: .picker))
    log.updateRouting(for: id4, to: .failed(reason: "Safari not installed"))
    log.updateRouting(for: id5, to: .unsupported)
    return DebugLogView()
        .frame(width: 760, height: 480)
}

#Preview("Empty") {
    URLLog.shared.clear()
    return DebugLogView()
        .frame(width: 760, height: 480)
}
