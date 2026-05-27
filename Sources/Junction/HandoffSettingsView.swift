import SwiftUI
import AppKit

/// Settings → Handoff tab.
///
/// Promoted out of the Advanced tab because it's the section users tweak
/// most often — toggling Zoom/Slack/etc. on or off is a routine decision,
/// while the URL-rewriter knobs are a one-time setup. Giving Handoff a
/// dedicated tab also makes the toggles breathe a bit more (the Advanced
/// tab was getting busy).
///
/// Handoff runs *before* rules in the router — see `Router.route` — so
/// these toggles can override even a perfectly-good rule. Worth keeping
/// in mind when something's "not opening in Chrome like I told it to."
struct HandoffSettingsView: View {

    @ObservedObject private var handoffs = AppHandoffSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                handoffSection
            }
            .formStyle(.grouped)
        }
    }

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

    @ViewBuilder
    private var handoffSection: some View {
        Section {
            ForEach(AppHandoff.allCases) { handoff in
                handoffRow(handoff)
            }
        } header: {
            Text("Hand off to native apps")
        } footer: {
            Text("Toggles are disabled when the corresponding app isn't installed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func handoffRow(_ handoff: AppHandoff) -> some View {
        let installed = handoff.isInstalled
        return Toggle(isOn: Binding(
            get: { handoffs.isEnabled(handoff) },
            set: { handoffs.setEnabled(handoff, $0) }
        )) {
            HStack(spacing: 10) {
                handoffIcon(handoff)
                VStack(alignment: .leading, spacing: 1) {
                    Text(handoff.displayName)
                    if !installed {
                        Text("Not installed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(handoff.sampleURL)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()
            }
        }
        .toggleStyle(.switch)
        .disabled(!installed)
    }

    /// Resolves an app icon image for the handoff target, or a placeholder
    /// glyph when the app isn't installed.
    @ViewBuilder
    private func handoffIcon(_ handoff: AppHandoff) -> some View {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: handoff.bundleID)
            ?? handoff.alternateBundleIDs
                .compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) })
                .first {
            Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 18))
                .frame(width: 22, height: 22)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - AppHandoff sample-URL hint

private extension AppHandoff {
    /// Short example URL shown beside each handoff toggle so the user
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

#Preview { HandoffSettingsView().frame(width: 720, height: 480) }
