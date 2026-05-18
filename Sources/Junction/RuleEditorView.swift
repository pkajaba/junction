import SwiftUI

/// Modal sheet for adding or editing a single rule.
///
/// Works on a `@State` copy so changes are discarded if the user hits
/// Cancel. The "Test URL" field lets you paste a URL and see at a glance
/// whether the rule (with current settings) matches it.
struct RuleEditorView: View {

    let initial: Rule
    let isNew: Bool
    let onSave: (Rule) -> Void
    let onCancel: () -> Void

    // Working copy.
    @State private var name: String
    @State private var enabled: Bool
    @State private var matcherType: MatcherType
    @State private var matcherValue: String
    @State private var browserBundleID: String
    @State private var profile: String
    @State private var openInNewWindow: Bool
    @State private var testURL: String = ""

    @State private var allBrowsers: [DetectedBrowser] = []

    private enum MatcherType: String, CaseIterable, Identifiable {
        case host
        case hostRegex
        case urlContains
        var id: String { rawValue }

        var label: String {
            switch self {
            case .host:        return "Host (exact or subdomain)"
            case .hostRegex:   return "Host regex"
            case .urlContains: return "URL contains"
            }
        }

        var placeholder: String {
            switch self {
            case .host:        return "github.com"
            case .hostRegex:   return "^(mail|calendar|docs)\\.google\\.com$"
            case .urlContains: return "/issues/"
            }
        }
    }

    init(initial: Rule, isNew: Bool, onSave: @escaping (Rule) -> Void, onCancel: @escaping () -> Void) {
        self.initial = initial
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: initial.name)
        _enabled = State(initialValue: initial.enabled)
        switch initial.match {
        case .host(let v):
            _matcherType = State(initialValue: .host)
            _matcherValue = State(initialValue: v)
        case .hostRegex(let v):
            _matcherType = State(initialValue: .hostRegex)
            _matcherValue = State(initialValue: v)
        case .urlContains(let v):
            _matcherType = State(initialValue: .urlContains)
            _matcherValue = State(initialValue: v)
        }
        _browserBundleID = State(initialValue: initial.target.browserBundleID)
        _profile = State(initialValue: initial.target.profile ?? "")
        _openInNewWindow = State(initialValue: initial.target.openInNewWindow)
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            form
            Divider()
            actionBar
        }
        .frame(width: 540)
        .onAppear { allBrowsers = BrowserDetector.shared.detectAll() }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack {
            Text(isNew ? "Add Rule" : "Edit Rule")
                .font(.headline)
            Spacer()
            Toggle("Enabled", isOn: $enabled)
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Form

    private var form: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $name)
            }

            Section("Match") {
                Picker("Type", selection: $matcherType) {
                    ForEach(MatcherType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                TextField("Value", text: $matcherValue, prompt: Text(matcherType.placeholder))
                    .font(.system(.body, design: .monospaced))
                if matcherType == .hostRegex, let issue = regexIssue {
                    Label(issue, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            Section("Target") {
                Picker("Browser", selection: $browserBundleID) {
                    ForEach(allBrowsers) { browser in
                        Text(browser.displayName).tag(browser.bundleID)
                    }
                    // Allow keeping a bundle ID even if the browser isn't currently detected.
                    if !allBrowsers.contains(where: { $0.bundleID == browserBundleID }) {
                        Text("\(browserBundleID) (not installed)").tag(browserBundleID)
                    }
                }
                TextField("Profile", text: $profile, prompt: Text("Default"))
                    .font(.system(.body, design: .monospaced))
                Text("Honored for Chromium browsers as `--profile-directory=<value>`. Leave blank to use the default.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Open in new window", isOn: $openInNewWindow)
            }

            Section("Test") {
                TextField("Paste a URL to test against this rule", text: $testURL, prompt: Text("https://example.com"))
                    .font(.system(.body, design: .monospaced))
                testResultRow
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var testResultRow: some View {
        let trimmed = testURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            EmptyView()
        } else if let url = URL(string: trimmed), url.scheme != nil {
            if let preview = buildPreviewRule(), RuleEvaluator.matches(url, preview.match) {
                Label("Match", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Does not match", systemImage: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
        } else {
            Label("Not a valid URL", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack {
            Spacer()
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button(isNew ? "Add" : "Save") {
                if let rule = buildSaveRule() {
                    onSave(rule)
                }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!isValid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Validation

    private var regexIssue: String? {
        guard matcherType == .hostRegex, !matcherValue.isEmpty else { return nil }
        do {
            _ = try NSRegularExpression(pattern: matcherValue, options: [.caseInsensitive])
            return nil
        } catch {
            return "Invalid regex: \(error.localizedDescription)"
        }
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard !matcherValue.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard !browserBundleID.isEmpty else { return false }
        if regexIssue != nil { return false }
        return true
    }

    // MARK: - Build

    private func buildPreviewRule() -> Rule? {
        guard !matcherValue.isEmpty else { return nil }
        let match: Matcher
        switch matcherType {
        case .host:        match = .host(matcherValue)
        case .hostRegex:   match = .hostRegex(matcherValue)
        case .urlContains: match = .urlContains(matcherValue)
        }
        return Rule(
            id: initial.id,
            name: name,
            enabled: enabled,
            match: match,
            target: Target(browserBundleID: browserBundleID)
        )
    }

    private func buildSaveRule() -> Rule? {
        guard isValid else { return nil }
        let match: Matcher
        switch matcherType {
        case .host:        match = .host(matcherValue)
        case .hostRegex:   match = .hostRegex(matcherValue)
        case .urlContains: match = .urlContains(matcherValue)
        }
        let target = Target(
            browserBundleID: browserBundleID,
            profile: profile.isEmpty ? nil : profile,
            extraArgs: initial.target.extraArgs,
            openInNewWindow: openInNewWindow
        )
        return Rule(
            id: initial.id,
            name: name,
            enabled: enabled,
            match: match,
            target: target
        )
    }
}
