import SwiftUI

/// Settings → Advanced tab.
///
/// M6 hosts the URL rewriter controls. Future stages (shortener
/// expansion, custom regex rewrites, log-level toggle) plug in here.
struct AdvancedSettingsView: View {

    @ObservedObject private var rewriter = RewriterSettings.shared

    @State private var draftParam: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                trackingSection
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
}

#Preview { AdvancedSettingsView().frame(width: 720, height: 480) }
