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
                            ActivityRowView(entry: entry)
                            Divider()
                        }
                    }
                }
            }
        }
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

// MARK: - Activity row

/// A single Activity row: time, URL block, outcome block. Designed to
/// stay legible down to ~700pt window width — host/path truncates,
/// outcome block stays right-anchored.
struct ActivityRowView: View {
    let entry: URLLog.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timeColumn
            urlColumn
            outcomeColumn
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: column: time

    private var timeColumn: some View {
        Text(entry.receivedAt.formatted(date: .omitted, time: .standard))
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 64, alignment: .leading)
            .padding(.top, 2)
    }

    // MARK: column: URL block

    @ViewBuilder
    private var urlColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            urlLine
            subline
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayURL: URL { entry.rewritten ?? entry.url }

    private var urlLine: some View {
        HStack(spacing: 6) {
            HostFavicon(host: displayURL.host ?? "")
            (Text(displayURL.host ?? "—").fontWeight(.semibold)
             + Text(pathAndQuery).foregroundStyle(.secondary))
                .font(.system(size: 12.5))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var pathAndQuery: String {
        var s = displayURL.path
        if let q = displayURL.query, !q.isEmpty { s += "?\(q)" }
        return s
    }

    @ViewBuilder
    private var subline: some View {
        HStack(spacing: 6) {
            if let source = entry.sourceApp, !source.isEmpty {
                Text("from \(SourceAppList.displayName(for: source))")
            }
            if !entry.strippedParams.isEmpty {
                if entry.sourceApp != nil { dot }
                Text("cleaned (\(formatStripped(entry.strippedParams)) stripped)")
                    .foregroundStyle(Color(red: 0.20, green: 0.66, blue: 0.33))
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.tail)
    }

    private var dot: some View {
        Text("·").foregroundStyle(.tertiary)
    }

    private func formatStripped(_ names: [String]) -> String {
        // One name → that name. Many → "utm_source +2 more" to keep the
        // subline compact at narrow window widths.
        if names.count == 1 { return names[0] }
        return "\(names[0]) +\(names.count - 1) more"
    }

    // MARK: column: outcome

    private var outcomeColumn: some View {
        outcomeContent
            .frame(width: 220, alignment: .trailing)
    }

    @ViewBuilder
    private var outcomeContent: some View {
        switch entry.routing {
        case .pending:
            outcomeChip(
                icon: "ellipsis.circle",
                iconColor: .secondary,
                title: "Routing…",
                subtitle: nil
            )
        case .routed(let target, let reason):
            routedOutcome(target: target, reason: reason)
        case .failed(let reason):
            outcomeChip(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Failed",
                subtitle: reason
            )
        case .unsupported:
            outcomeChip(
                icon: "xmark.circle",
                iconColor: .secondary,
                title: "Skipped",
                subtitle: "not an http(s) link"
            )
        case .cancelled:
            outcomeChip(
                icon: "hand.raised.fill",
                iconColor: .secondary,
                title: "Cancelled",
                subtitle: "picker dismissed"
            )
        }
    }

    @ViewBuilder
    private func routedOutcome(target: String, reason: URLLog.RouteReason) -> some View {
        switch reason {
        case .rule(let ruleName):
            outcomeChip(
                icon: "checkmark.circle.fill",
                iconColor: Color(red: 0.20, green: 0.66, blue: 0.33),
                title: targetWithProfile(target),
                subtitle: "via \(ruleName)"
            )
        case .handoff(let appName):
            outcomeChip(
                icon: "arrow.up.right.square.fill",
                iconColor: Color(red: 0.12, green: 0.43, blue: 1.0),
                title: appName,
                subtitle: "native handoff"
            )
        case .picker:
            outcomeChip(
                icon: "circle.fill",
                iconColor: Color(red: 0.96, green: 0.65, blue: 0.14),
                title: targetWithProfile(target),
                subtitle: "picked manually"
            )
        }
    }

    private func targetWithProfile(_ target: String) -> String {
        if let profile = entry.routedProfile, !profile.isEmpty {
            return "\(target) · \(profile)"
        }
        return target
    }

    private func outcomeChip(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?
    ) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(iconColor)
                .padding(.top, 2)
            VStack(alignment: .trailing, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }
}

// MARK: - Host favicon glyph

/// Tiny colored badge with the host's first letter. Matches the picker's
/// `HostFavicon` (defined privately in `PickerView.swift`); duplicated
/// here to avoid making that one internal just for the Activity tab.
private struct HostFavicon: View {
    let host: String

    private var firstChar: String {
        String(host.prefix(1)).uppercased()
    }

    private var tint: Color {
        let hash = host.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.55)
    }

    var body: some View {
        Text(firstChar.isEmpty ? "?" : firstChar)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
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
