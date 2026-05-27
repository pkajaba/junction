import SwiftUI
import AppKit

/// Settings → Handoff tab.
///
/// Promoted out of the Advanced tab because it's the section users tweak
/// most often. The Round 2 ③ redesign branches the row layout by
/// installation state: installed apps show a real icon + toggle, missing
/// ones show a dashed placeholder + "Not installed ↗" pill that opens
/// the vendor's download page. The footnote went away — the UI now
/// self-explains.
///
/// Handoff runs *before* rules in the router — see `Router.route` — so
/// these toggles can override even a perfectly-good rule.
struct HandoffSettingsView: View {

    @ObservedObject private var handoffs = AppHandoffSettings.shared

    private var installedCount: Int {
        AppHandoff.allCases.filter(\.isInstalled).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader
                    appsCard
                }
                .padding(20)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Handoff")
                .font(.title2.weight(.semibold))
            Text("Send specific links straight to a native app instead of a browser. "
                 + "Handoff takes priority over your rules.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
    }

    // MARK: - Section

    private var sectionHeader: some View {
        HStack {
            Text("Hand off to native apps")
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(installedCount) installed · \(AppHandoff.allCases.count) available")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    /// Single rounded container holds every app row with hairline dividers
    /// between them. Per the Round 2 spec — section header sits outside
    /// the container, above it.
    private var appsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(AppHandoff.allCases.enumerated()), id: \.element) { index, handoff in
                handoffRow(handoff)
                if index < AppHandoff.allCases.count - 1 {
                    Divider()
                        .padding(.leading, 60)   // align with text column
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func handoffRow(_ handoff: AppHandoff) -> some View {
        if handoff.isInstalled {
            InstalledHandoffRow(
                handoff: handoff,
                isEnabled: handoffs.isEnabled(handoff),
                toggle: { handoffs.setEnabled(handoff, $0) }
            )
        } else {
            NotInstalledHandoffRow(handoff: handoff)
        }
    }
}

// MARK: - Row variants

/// Row for handoffs whose app is actually on disk. Real icon + sample
/// URL subtitle + working toggle.
private struct InstalledHandoffRow: View {
    let handoff: AppHandoff
    let isEnabled: Bool
    let toggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            appIcon(for: handoff)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(handoff.displayName)
                    .font(.system(size: 13, weight: .medium))
                Text(handoff.sampleURL)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: Binding(get: { isEnabled }, set: toggle))
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Hand off \(handoff.displayName) links")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func appIcon(for handoff: AppHandoff) -> some View {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: handoff.bundleID)
            ?? handoff.alternateBundleIDs
                .compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) })
                .first {
            Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                .resizable()
                .interpolation(.high)
        } else {
            // Fallback shouldn't fire — `isInstalled` already gated us.
            Image(systemName: "app.dashed")
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
        }
    }
}

/// Row for handoffs whose app *isn't* installed. Dashed placeholder
/// icon + "Not installed ↗" pill that opens the vendor download page in
/// the system default browser. Row at 55% opacity so the eye skips
/// straight to the installed apps.
private struct NotInstalledHandoffRow: View {
    let handoff: AppHandoff
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            dashedPlaceholder
            VStack(alignment: .leading, spacing: 2) {
                Text(handoff.displayName)
                    .font(.system(size: 13, weight: .medium))
                Text(handoff.sampleURL)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 12)
            installButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .opacity(0.55)
    }

    private var dashedPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .foregroundStyle(Color(nsColor: .separatorColor))
            .frame(width: 28, height: 28)
    }

    private var installButton: some View {
        Button {
            // Force-route through the system default browser so we never
            // recurse into Junction. (NSWorkspace.open does the right
            // thing for http(s) — it consults LaunchServices defaults.)
            NSWorkspace.shared.open(handoff.downloadURL)
        } label: {
            HStack(spacing: 4) {
                Text("Not installed")
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 9, weight: .semibold))
            }
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(.primary.opacity(0.65))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(hovering
                               ? Color.primary.opacity(0.08)
                               : Color.primary.opacity(0.04))
            )
            .overlay(
                Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Open the \(handoff.displayName) download page")
        .accessibilityLabel("Install \(handoff.displayName)")
    }
}

// MARK: - AppHandoff sample-URL hint

private extension AppHandoff {
    /// Short example URL shown beside each handoff row so the user
    /// knows what kind of link triggers it.
    var sampleURL: String {
        switch self {
        case .zoom:    return "*.zoom.us/j/..."
        case .teams:   return "teams.microsoft.com/l/..."
        case .slack:   return "app.slack.com/client/..."
        case .notion:  return "notion.so/..."
        case .linear:  return "linear.app/..."
        case .spotify: return "open.spotify.com/track/..."
        case .discord: return "discord.com/channels/..."
        }
    }
}

#Preview { HandoffSettingsView().frame(width: 760, height: 540) }
