import SwiftUI
import AppKit

/// A single Activity-tab row: time, URL block, and a trailing column that
/// flips between the routing outcome and a "Create rule…" affordance on
/// hover (for no-match rows). Lives in its own file so `DebugLogView`
/// stays under SwiftLint's file_length budget.
struct ActivityRowView: View {
    let entry: URLLog.Entry
    let isSelected: Bool
    let onSelect: () -> Void
    let onCreateRule: () -> Void

    /// Show the create-rule affordance for picker-manual rows that have
    /// a host. Cheap structural check — the actual target resolution
    /// (and any display-name fallback) happens when the button fires,
    /// via `entry.suggestedRule()`.
    private var canCreateRule: Bool {
        guard case .routed(_, .picker) = entry.routing else { return false }
        return (entry.rewritten ?? entry.url).host != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timeColumn
            urlColumn
            trailingColumn
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.10) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }

    // MARK: column: trailing (outcome + optional create-rule button)

    /// Outcome on top; for picker-manual rows, a "Create rule" button
    /// beneath it. Always visible (not hover-gated) — `.onHover` inside
    /// a LazyVStack/ScrollView is unreliable on macOS, and a persistent
    /// button is more discoverable anyway.
    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: 6) {
            outcomeContent
            if canCreateRule {
                createRuleButton
            }
        }
        .frame(width: 220, alignment: .trailing)
    }

    private var createRuleButton: some View {
        Button(action: onCreateRule) {
            Label("Create rule", systemImage: "plus")
                .font(.system(size: 11, weight: .medium))
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
        .help("Make a rule that always sends this site to that browser (⌘R when selected)")
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
/// here (also private) to avoid making that one internal just for the
/// Activity tab.
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
