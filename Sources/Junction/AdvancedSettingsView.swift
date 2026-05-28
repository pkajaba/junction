import SwiftUI

/// Settings → Advanced tab.
///
/// Round 2 ⑤ restructure:
/// - Appearance lives in its own compact card.
/// - Tracking's toggle is the *section header* (not a peer of the param
///   list); the params themselves sit in an indented card that dims to
///   50% when the toggle is off.
/// - Params support `*` globs (e.g. `utm_*` matches every utm_* variant).
/// - The "add a parameter" row is the last item of the list itself,
///   tinted blue, with a `⏎` keycap — pressing return adds + clears.
struct AdvancedSettingsView: View {

    @ObservedObject private var rewriter = RewriterSettings.shared
    @ObservedObject private var appearance = AppearanceSettings.shared
    @ObservedObject private var loginItem = LoginItemSettings.shared

    @State private var draftParam: String = ""
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    launchAtLoginCard
                    appearanceCard
                    trackingSection
                }
                .padding(20)
            }
        }
        // Re-sync the login-item toggle in case the user changed it in
        // System Settings while Junction was running.
        .onAppear { loginItem.refresh() }
    }

    // MARK: - Launch at login

    private var launchAtLoginCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch at login")
                        .font(.system(size: 13, weight: .medium))
                    Text("Start Junction automatically when you log in, so links "
                         + "route from the moment you sign in.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { loginItem.isEnabled },
                    set: { loginItem.setEnabled($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Launch Junction at login")
            }
            if loginItem.requiresApproval {
                Label(
                    "Approve Junction in System Settings → General → Login Items to finish.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.system(size: 11))
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            }
            if let error = loginItem.lastError {
                Label(error, systemImage: "xmark.octagon")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
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

    // MARK: - Appearance card

    private var appearanceCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Theme")
                    .font(.system(size: 13, weight: .medium))
                Text("\"System\" follows macOS. Light and Dark override it for Junction only.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Picker("", selection: $appearance.appearance) {
                ForEach(AppearanceSettings.Appearance.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    // MARK: - Tracking section

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            trackingSectionHeader
            trackingCard
                .opacity(rewriter.stripTrackingParams ? 1 : 0.5)
                .disabled(!rewriter.stripTrackingParams)
        }
    }

    /// The toggle IS the section header — title + subtitle + a full-size
    /// switch, with no surrounding card. Sets the visual hierarchy: the
    /// big decision (strip or not?) is one row; the *list* below is a
    /// detail of that decision.
    private var trackingSectionHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Strip tracking parameters")
                    .font(.system(size: 14, weight: .semibold))
                Text("Removes utm_*, fbclid, gclid, and other tracking-only "
                     + "params before the URL hits a rule.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: $rewriter.stripTrackingParams)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Strip tracking parameters")
        }
    }

    /// The indented param card. Mini-header up top, then a nested
    /// surface for the param list + add-input. Dims and disables as a
    /// unit when the toggle is off.
    private var trackingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            paramsCardHeader
            paramList
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private var paramsCardHeader: some View {
        HStack {
            Text("Parameters to strip")
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(sortedParams.count) params · `*` is a wildcard")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    private var paramList: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedParams.enumerated()), id: \.element) { index, param in
                ParamRow(param: param) {
                    rewriter.trackingParams.remove(param)
                }
                if index < sortedParams.count - 1 {
                    Divider()
                }
            }
            if !sortedParams.isEmpty {
                Divider()
            }
            addParamRow
        }
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    /// Last row of the list is the add-input — tinted blue so it reads as
    /// the "live edge" of the list and not just another row.
    private var addParamRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 18)
            TextField("Add a parameter… (e.g. ref, source_id, *_token)",
                      text: $draftParam)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, design: .monospaced))
                .focused($addFieldFocused)
                .onSubmit(addDraft)
            keycap("⏎")
                .opacity(draftParam.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.accentColor.opacity(0.08))
    }

    private func keycap(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
    }

    // MARK: - Helpers

    private var sortedParams: [String] {
        Array(rewriter.trackingParams).sorted()
    }

    private func addDraft() {
        let trimmed = draftParam.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        rewriter.trackingParams.insert(trimmed)
        draftParam = ""
        addFieldFocused = true
    }
}

// MARK: - Param row

/// One param in the strip list — monospaced name on the left, circular
/// `−` button on the right (20×20). Hover lifts the button so users
/// know it's interactive without having to mouse over each row.
private struct ParamRow: View {
    let param: String
    let onRemove: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Text(param)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(.primary)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(hovering
                                      ? Color.primary.opacity(0.08)
                                      : Color.primary.opacity(0.04))
                    )
                    .overlay(
                        Circle().strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
            .help("Remove \(param)")
            .accessibilityLabel("Remove \(param)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

#Preview { AdvancedSettingsView().frame(width: 720, height: 540) }
