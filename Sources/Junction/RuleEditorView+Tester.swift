import SwiftUI
import AppKit

/// Section C of the rule editor: live URL tester. Pulled out of
/// `RuleEditorView.swift` to keep that file under the SwiftLint
/// type/file length budgets.
extension RuleEditorView {

    var testerCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                TextField("https://mail.google.com/mail/u/0/", text: $testURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12.5, design: .monospaced))
                testerResult
                if !rule.sourceApps.isEmpty {
                    let names = rule.sourceApps.map(SourceAppList.displayName(for:))
                    let formatted = ListFormatter.localizedString(byJoining: names)
                    Label {
                        Text("This tester checks the URL only — the rule also "
                             + "requires the link to come from \(formatted).")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .labelStyle(.titleAndIcon)
                }
            }
        }
    }

    @ViewBuilder
    var testerResult: some View {
        let trimmed = testURL.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            Text("Paste a URL above to see whether it matches this rule.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        } else if let url = URL(string: trimmed), url.scheme != nil {
            if RuleEvaluator.matches(url, rule.match) {
                resultChip(
                    icon: "checkmark.circle.fill",
                    text: "Matches \(url.host ?? trimmed) — routes to "
                        + "\(browserDisplayName(rule.target.browserBundleID))\(profileSuffix)",
                    foreground: Color.green,
                    background: Color.green.opacity(0.15)
                )
            } else {
                resultChip(
                    icon: "arrow.down.right.circle",
                    text: "Falls through (no match) — picker would show",
                    foreground: Color.secondary,
                    background: Color.primary.opacity(0.06)
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

    var profileSuffix: String {
        if let profile = rule.target.profile, !profile.isEmpty {
            return " (\(profile))"
        }
        return ""
    }

    func resultChip(icon: String, text: String, foreground: Color, background: Color) -> some View {
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

    func browserDisplayName(_ bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default
                .displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }
}
