import SwiftUI

/// Settings → Advanced tab.
///
/// Appearance + the URL rewriter knobs. Handoff lived here until it got
/// busy enough to deserve its own tab — see `HandoffSettingsView`.
struct AdvancedSettingsView: View {

    @ObservedObject private var rewriter = RewriterSettings.shared
    @ObservedObject private var appearance = AppearanceSettings.shared

    @State private var draftParam: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                appearanceSection
                trackingSection
            }
            .formStyle(.grouped)
        }
    }

    // MARK: - Appearance

    @ViewBuilder
    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: $appearance.appearance) {
                ForEach(AppearanceSettings.Appearance.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        } footer: {
            Text("\"System\" follows your macOS appearance. Light and Dark override it for Junction only.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
}

#Preview { AdvancedSettingsView().frame(width: 720, height: 480) }
