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
    @State private var runningApps: [SourceAppList.App] = []
    // Non-private so the tester extension (in another file) can bind the field.
    @State var testURL: String = ""
    @State private var newChipText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                editorHeader

                Section(header: sectionHeader("When a link goes to")) {
                    hostMatcherCard
                }

                Section(header: sectionHeader("And comes from")) {
                    sourceAppCard
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
            runningApps = SourceAppList.runningApps()
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
    //
    // `sectionHeader` and `card` are deliberately non-private — the
    // editor is broken up across multiple files (extensions), and all of
    // them lean on these two helpers for consistent look-and-feel.

    func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .kerning(0.6)
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)
    }

    func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
            .overlay(
                // .separatorColor adapts to dark mode and to the
                // Increase Contrast accessibility setting for free —
                // a fixed black-opacity hairline does neither.
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
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

                if initialChips.hosts.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                    emptyHostsHint
                }

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
                        Text(HostChipMatcher.subdomainHint(initialChips))
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
            }
        }
    }

    /// Shown when the host list is empty. With no hosts the rule matches
    /// *every* URL — only sensible when paired with a "From app" condition,
    /// so the message adapts to whether one is set.
    @ViewBuilder
    private var emptyHostsHint: some View {
        let hasSource = !(rule.sourceApp ?? "").isEmpty
        Label {
            Text(hasSource
                 ? "No hosts — this rule matches every link from the app above."
                 : "No hosts and no \u{201C}From app\u{201D} — this rule would catch "
                   + "every link. Add a host, or pick a source app above.")
                .font(.system(size: 11))
                .foregroundStyle(hasSource ? Color.secondary : Color.orange)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: hasSource ? "info.circle" : "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(hasSource ? Color.secondary : Color.orange)
        }
        .labelStyle(.titleAndIcon)
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
                    // Accept full URLs (https://github.com/foo) the same
                    // as bare hosts (github.com) — extract the hostname
                    // either way. Silent rejection of pasted URLs was
                    // the v1 bug here.
                    guard let host = HostChipMatcher.normalizedHost(from: committed) else { return }
                    var newHosts = chips.hosts
                    if !newHosts.contains(host) {
                        newHosts.append(host)
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
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
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
        case .any:                return "any URL"
        }
    }

    // MARK: - Section: source app

    /// "Any app" plus every running regular app. If the rule already
    /// references an app that isn't running, surface it too (flagged) so
    /// the selection never silently disappears.
    private var sourceAppOptions: [SourceAppList.App] {
        var apps = runningApps
        if let current = rule.sourceApp, !current.isEmpty,
           !apps.contains(where: { $0.bundleID == current }) {
            apps.insert(
                SourceAppList.App(
                    bundleID: current,
                    displayName: SourceAppList.displayName(for: current) + " (not running)"
                ),
                at: 0
            )
        }
        return apps
    }

    /// Bridges the optional `rule.sourceApp` to the Picker, which needs a
    /// non-optional tag. Empty string is the "Any app" sentinel.
    private var sourceAppBinding: Binding<String> {
        Binding(
            get: { rule.sourceApp ?? "" },
            set: { rule.sourceApp = $0.isEmpty ? nil : $0 }
        )
    }

    private var sourceAppCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("From app")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 64, alignment: .leading)
                    Picker("", selection: sourceAppBinding) {
                        Text("Any app").tag("")
                        Divider()
                        ForEach(sourceAppOptions) { app in
                            Text(app.displayName).tag(app.bundleID)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                Text(sourceAppNote)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sourceAppNote: String {
        if let source = rule.sourceApp, !source.isEmpty {
            return "Only links opened from \(SourceAppList.displayName(for: source)) "
                 + "match this rule. Junction uses the app that was frontmost when "
                 + "the link was clicked — accurate for normal clicks, best-effort "
                 + "for links delivered by background helpers."
        }
        return "The rule applies no matter which app the link came from. "
             + "Pick an app to make it fire only for links opened from there "
             + "(e.g. \u{201C}links from Slack \u{2192} Chrome\u{201D})."
    }

    // MARK: - Section B: target

    private var targetCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Browser")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                        .frame(width: 64, alignment: .leading)
                    profilePicker
                }
                if let note = profileSelectionNote {
                    Label {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
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

    // Tester section + host-chip helper views moved to
    // RuleEditorView+Tester.swift and RuleEditorChips.swift to keep this
    // file under the SwiftLint type/file length budgets.
}
