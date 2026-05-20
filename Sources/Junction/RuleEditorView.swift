import SwiftUI
import AppKit

/// The right pane of the Rules settings tab. Edits a single Rule in place
/// via Binding — every change persists immediately through `RuleStore`.
///
/// Three sections, top to bottom:
///   A. "When a link goes to" — the visual host-chip matcher
///   B. "Open it in"           — browser + profile + new-window
///   C. "Test a URL"            — live match indicator
struct RuleEditorView: View {

    @Binding var rule: Rule

    @State private var allBrowsers: [DetectedBrowser] = []
    @State private var detectedProfiles: [ProfileDetector.ProfileInfo] = []
    @State private var testURL: String = ""
    @State private var newChipText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                editorHeader

                Section(header: sectionHeader("When a link goes to")) {
                    hostMatcherCard
                }

                Section(header: sectionHeader("Open it in")) {
                    targetCard
                }

                Section(header: sectionHeader("Test a URL")) {
                    testerCard
                }
            }
            .padding(22)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            allBrowsers = BrowserDetector.shared.detectAll()
            refreshProfiles()
        }
        .onChange(of: rule.target.browserBundleID) { _, _ in refreshProfiles() }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            TextField("Rule name", text: $rule.name)
                .textFieldStyle(.plain)
                .font(.system(size: 19, weight: .semibold))
            Spacer()
            Text("Enabled")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Toggle("", isOn: $rule.enabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }

    // MARK: - Section card chrome

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .kerning(0.6)
            .foregroundStyle(.black.opacity(0.55))
            .padding(.bottom, 4)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.025))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
    }

    // MARK: - Section A: host chip matcher

    @ViewBuilder
    private var hostMatcherCard: some View {
        if let chips = HostChipMatcher.chips(from: rule.match) {
            chipMatcherEditor(initialChips: chips)
        } else {
            rawMatcherFallback
        }
    }

    private func chipMatcherEditor(initialChips: HostChipMatcher.Chips) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                hostChipFlow(chips: initialChips)

                Divider()
                    .padding(.top, 2)

                Toggle(isOn: Binding(
                    get: { initialChips.includeSubdomains },
                    set: { newValue in
                        let updated = HostChipMatcher.Chips(
                            hosts: initialChips.hosts,
                            includeSubdomains: newValue
                        )
                        rule.match = HostChipMatcher.matcher(from: updated)
                    }
                )) {
                    HStack(spacing: 6) {
                        Text("Include subdomains")
                            .font(.system(size: 12.5, weight: .medium))
                        Text("— so `m.mail.google.com` matches too")
                            .font(.system(size: 12.5))
                            .foregroundStyle(.black.opacity(0.45))
                    }
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
            }
        }
    }

    private func hostChipFlow(chips: HostChipMatcher.Chips) -> some View {
        WrappingHStack(spacing: 6, lineSpacing: 6) {
            ForEach(Array(chips.hosts.enumerated()), id: \.offset) { index, host in
                HostChipView(host: host) {
                    var newHosts = chips.hosts
                    newHosts.remove(at: index)
                    let updated = HostChipMatcher.Chips(
                        hosts: newHosts,
                        includeSubdomains: chips.includeSubdomains
                    )
                    rule.match = HostChipMatcher.matcher(from: updated)
                }
            }

            AddChipField(
                text: $newChipText,
                onCommit: { committed in
                    let trimmed = committed.trimmingCharacters(in: .whitespaces)
                    guard HostChipMatcher.isValidHost(trimmed) else { return }
                    var newHosts = chips.hosts
                    if !newHosts.contains(trimmed) {
                        newHosts.append(trimmed)
                    }
                    let updated = HostChipMatcher.Chips(
                        hosts: newHosts,
                        includeSubdomains: chips.includeSubdomains
                    )
                    rule.match = HostChipMatcher.matcher(from: updated)
                    newChipText = ""
                }
            )
        }
    }

    private var rawMatcherFallback: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom matcher")
                    .font(.system(size: 12.5, weight: .semibold))
                Text("This rule uses a matcher Junction's visual editor can't yet "
                     + "represent — it's a raw regex or a URL-contains pattern. Edit it "
                     + "as JSON via the rules.json button below for now; full raw-mode "
                     + "editing lands in a follow-up.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(matcherSummary)
                    .font(.system(size: 11.5, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
                    .padding(.top, 2)
            }
        }
    }

    private var matcherSummary: String {
        switch rule.match {
        case .host(let v):        return "host = \(v)"
        case .hostRegex(let v):   return "regex = \(v)"
        case .urlContains(let v): return "urlContains = \(v)"
        }
    }

    // MARK: - Section B: target

    private var targetCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Browser")
                        .font(.system(size: 12))
                        .foregroundStyle(.black.opacity(0.6))
                        .frame(width: 64, alignment: .leading)
                    Picker("", selection: $rule.target.browserBundleID) {
                        ForEach(allBrowsers) { browser in
                            Text(browser.displayName).tag(browser.bundleID)
                        }
                        if !allBrowsers.contains(where: { $0.bundleID == rule.target.browserBundleID }) {
                            Text("\(rule.target.browserBundleID) (not installed)")
                                .tag(rule.target.browserBundleID)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("Profile")
                        .font(.system(size: 12))
                        .foregroundStyle(.black.opacity(0.6))
                        .frame(width: 64, alignment: .leading)
                    profilePicker
                }
                if let note = profileSelectionNote {
                    Label {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundStyle(.black.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(.black.opacity(0.4))
                    }
                    .labelStyle(.titleAndIcon)
                    .padding(.leading, 64 + 4)  // align with profile picker's left edge
                    .padding(.top, -2)
                }

                Toggle(isOn: Binding(
                    get: { rule.target.openInNewWindow },
                    set: { rule.target.openInNewWindow = $0 }
                )) {
                    Text("Open in a new window")
                        .font(.system(size: 12.5))
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var profilePicker: some View {
        if detectedProfiles.isEmpty {
            TextField("Default", text: profileBinding)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12.5, design: .monospaced))
                .controlSize(.small)
        } else {
            Picker("", selection: profileBinding) {
                Text("(default)").tag("")
                ForEach(detectedProfiles) { profile in
                    Text(profileLabel(profile)).tag(profile.id)
                }
                if !profileBinding.wrappedValue.isEmpty
                    && !detectedProfiles.contains(where: { $0.id == profileBinding.wrappedValue }) {
                    Text("\(profileBinding.wrappedValue) (not detected)")
                        .tag(profileBinding.wrappedValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }

    private var profileBinding: Binding<String> {
        Binding(
            get: { rule.target.profile ?? "" },
            set: { rule.target.profile = $0.isEmpty ? nil : $0 }
        )
    }

    private func profileLabel(_ p: ProfileDetector.ProfileInfo) -> String {
        p.id == p.displayName ? p.id : "\(p.displayName) — \(p.id)"
    }

    private func refreshProfiles() {
        detectedProfiles = ProfileDetector.detect(forBundleID: rule.target.browserBundleID)
    }

    /// Informational note shown below the profile picker for browsers
    /// that don't support external profile selection. nil = no note
    /// (Chromium and Firefox handle profiles cleanly).
    ///
    /// Background: Safari has profiles (since 17/macOS Sonoma) but no
    /// command-line flag or scripting API to target one externally; Arc
    /// uses Spaces with a similar limitation. Tracking issue: #13.
    private var profileSelectionNote: String? {
        switch rule.target.browserBundleID {
        case "com.apple.Safari":
            return "Safari doesn't expose external profile selection. "
                 + "The link opens in your active Safari profile — switch "
                 + "profiles in Safari first if you need a different one."
        case "company.thebrowser.Browser", "company.thebrowser.dia":
            return "Arc uses Spaces instead of profiles, with no external "
                 + "API to target one. The link opens in your active Space."
        default:
            return nil
        }
    }

    // MARK: - Section C: live URL tester

    private var testerCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                TextField("https://mail.google.com/mail/u/0/", text: $testURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12.5, design: .monospaced))
                testerResult
            }
        }
    }

    @ViewBuilder
    private var testerResult: some View {
        let trimmed = testURL.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            Text("Paste a URL above to see whether it matches this rule.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        } else if let url = URL(string: trimmed), url.scheme != nil {
            if RuleEvaluator.matches(url, rule.match) {
                resultChip(
                    icon: "checkmark.circle.fill",
                    text: "Matches \(url.host ?? trimmed) — routes to \(browserDisplayName(rule.target.browserBundleID))\(profileSuffix)",
                    foreground: Color(red: 31/255, green: 122/255, blue: 74/255),
                    background: Color(red: 52/255, green: 168/255, blue: 83/255).opacity(0.12)
                )
            } else {
                resultChip(
                    icon: "arrow.down.right.circle",
                    text: "Falls through (no match) — picker would show",
                    foreground: Color.black.opacity(0.55),
                    background: Color.black.opacity(0.04)
                )
            }
        } else {
            resultChip(
                icon: "exclamationmark.triangle.fill",
                text: "Not a valid URL",
                foreground: Color.orange,
                background: Color.orange.opacity(0.12)
            )
        }
    }

    private var profileSuffix: String {
        if let profile = rule.target.profile, !profile.isEmpty {
            return " (\(profile))"
        }
        return ""
    }

    private func resultChip(icon: String, text: String, foreground: Color, background: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(background)
        )
    }

    private func browserDisplayName(_ bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default
                .displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }
}

// MARK: - Host chip pill

private struct HostChipView: View {
    let host: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HostGlyph(host: host)
            Text(host)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.5))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - Add chip input

private struct AddChipField: View {
    @Binding var text: String
    let onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
            TextField("Add host", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .focused($isFocused)
                .onSubmit { onCommit(text) }
                .onChange(of: text) { _, newValue in
                    // Commit on space or comma to match typical chip-input UX.
                    if newValue.hasSuffix(" ") || newValue.hasSuffix(",") {
                        let stripped = String(newValue.dropLast())
                        onCommit(stripped)
                    }
                }
                .frame(minWidth: 100, maxWidth: 160)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 0.5, dash: [3, 3])
                )
                .foregroundStyle(.black.opacity(0.22))
        )
    }
}

// MARK: - Host glyph (colored circle with first letter)

private struct HostGlyph: View {
    let host: String

    private var firstChar: String {
        String(host.prefix(1)).uppercased()
    }

    private var tint: Color {
        let hash = host.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.65)
    }

    var body: some View {
        Text(firstChar.isEmpty ? "?" : firstChar)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 12, height: 12)
            .background(tint)
            .clipShape(Circle())
    }
}

// MARK: - Simple wrapping HStack for the chip flow

/// A minimal flow layout — wraps children to a new row when they exceed
/// the container width. SwiftUI's `Layout` protocol makes this
/// straightforward.
private struct WrappingHStack: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let arrangement = arrange(subviews: subviews, in: width)
        let height = arrangement.last.map { $0.maxY } ?? 0
        return CGSize(width: width.isFinite ? width : arrangement.maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews: subviews, in: bounds.width)
        for (index, frame) in arrangement.frames.enumerated() {
            let proposal = ProposedViewSize(width: frame.width, height: frame.height)
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                  proposal: proposal)
        }
    }

    private struct Arrangement {
        var frames: [CGRect] = []
        var maxWidth: CGFloat = 0
        var last: CGRect? { frames.last }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> Arrangement {
        var result = Arrangement()
        var cursorX: CGFloat = 0
        var cursorY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let usableWidth = width.isFinite ? width : .infinity

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if cursorX > 0, cursorX + size.width > usableWidth {
                cursorX = 0
                cursorY += lineHeight + lineSpacing
                lineHeight = 0
            }
            let frame = CGRect(x: cursorX, y: cursorY, width: size.width, height: size.height)
            result.frames.append(frame)
            result.maxWidth = max(result.maxWidth, frame.maxX)
            cursorX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return result
    }
}
