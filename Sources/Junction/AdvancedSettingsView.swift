import SwiftUI

/// Settings → Advanced tab.
///
/// M6 hosts the URL rewriter controls. Future stages (shortener
/// expansion, custom regex rewrites, log-level toggle) plug in here.
struct AdvancedSettingsView: View {

    @ObservedObject private var rewriter = RewriterSettings.shared
    @ObservedObject private var handoffs = AppHandoffSettings.shared

    @State private var draftParam: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                trackingSection
                handoffSection
            }
            .formStyle(.grouped)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Advanced")
                .font(.title2.weight(.semibold))
            Text("URL rewriting runs before rule matching, so cleaned URLs are what your rules see.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
    }

    @ViewBuilder
    private var trackingSection: some View {
        Section {
            Toggle("Strip tracking parameters", isOn: $rewriter.stripTrackingParams)
            Text("Removes utm_*, fbclid, gclid, and other common tracking-only query parameters. Page content is unaffected.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Tracking parameters")
        }

        Section {
            if rewriter.trackingParams.isEmpty {
                Text("No parameters in the strip list.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Button("Restore defaults") {
                    rewriter.resetTrackingParamsToDefaults()
                }
            } else {
                ForEach(Array(rewriter.trackingParams).sorted(), id: \.self) { param in
                    HStack {
                        Text(param)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            rewriter.trackingParams.remove(param)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    TextField("Add parameter (e.g. fbclid)", text: $draftParam)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit(addDraft)
                    Button("Add", action: addDraft)
                        .disabled(draftParam.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Button("Restore defaults") {
                    rewriter.resetTrackingParamsToDefaults()
                }
                .buttonStyle(.borderless)
            }
        } header: {
            Text("Parameters to strip")
        } footer: {
            Text("Case-insensitive. Matching is exact — `utm_source` strips `utm_source` but not `utm_sources`.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .disabled(!rewriter.stripTrackingParams)
        .opacity(rewriter.stripTrackingParams ? 1 : 0.5)
    }

    private func addDraft() {
        let trimmed = draftParam.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        rewriter.trackingParams.insert(trimmed)
        draftParam = ""
    }

    // MARK: - Hand off to native apps

    @ViewBuilder
    private var handoffSection: some View {
        Section {
            ForEach(AppHandoff.allCases) { handoff in
                handoffRow(handoff)
            }
        } header: {
            Text("Hand off to native apps")
        } footer: {
            Text("When on, matching URLs open in the native macOS app instead of a browser. Handoff takes priority over rules.")
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

#Preview { AdvancedSettingsView().frame(width: 720, height: 480) }
