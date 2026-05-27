import SwiftUI
import AppKit

/// Settings → Browsers tab.
///
/// Round 2 ④ redesign:
/// - Refresh moves to the page header (top-right) — it used to live as a
///   trailing button inside the empty state only.
/// - A `SYSTEM DEFAULT` pill stamps whichever browser is the macOS
///   default `http` handler, so users grok which one catches links when
///   no rule matches.
/// - The list ends with a "That's everything Junction found." empty-
///   state card carrying a `+ Add manually` button that opens a sheet:
///   bundle ID + display name; saved to `ManualBrowserList` and unioned
///   into detection.
struct BrowsersSettingsView: View {

    @ObservedObject private var hideList = BrowserHideList.shared
    @ObservedObject private var extraList = BrowserExtraList.shared
    @ObservedObject private var manualList = ManualBrowserList.shared

    /// Snapshots taken on appear; detection is fast and the user can
    /// hit Refresh. `allBrowsers` is the recognized set; `otherApps` is
    /// the unrecognized `http` handlers offered under "Other apps".
    @State private var allBrowsers: [DetectedBrowser] = []
    @State private var otherApps: [DetectedBrowser] = []
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .onAppear { refresh() }
        .sheet(isPresented: $showAddSheet) {
            ManualBrowserSheet(onSave: { bundleID, name in
                ManualBrowserList.shared.add(bundleID: bundleID, displayName: name)
                refresh()
            })
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Browsers")
                    .font(.title2.weight(.semibold))
                Text("Toggle which browsers appear in the picker. Hidden browsers "
                     + "can still be rule targets — they just won't clutter the picker.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Re-scan /Applications for browsers")
        }
        .padding(20)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if allBrowsers.isEmpty && otherApps.isEmpty && manualList.entries.isEmpty {
            cleanEmpty
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !allBrowsers.isEmpty {
                        browsersSection
                    }
                    if !otherApps.isEmpty {
                        otherAppsSection
                    }
                    addManuallyCard
                }
                .padding(20)
            }
        }
    }

    /// True empty state — nothing on this machine claims to handle
    /// `http`. Different from the "list is fine, you can add more" card
    /// that lives below the detected browsers.
    private var cleanEmpty: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No apps can open links")
                .font(.headline)
            Text("Nothing on this Mac is registered as an http handler — unusual. Try Refresh.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Sections

    private var browsersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Browsers", count: allBrowsers.count)
            browserListCard(allBrowsers, isExtraList: false)
        }
    }

    private var otherAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Other apps", count: otherApps.count)
            Text("Apps that can open links but aren't on Junction's known-browser list. "
                 + "Turn one on if it's a real browser Junction didn't recognize.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            browserListCard(otherApps, isExtraList: true)
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func browserListCard(_ browsers: [DetectedBrowser], isExtraList: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(browsers.enumerated()), id: \.element.bundleID) { index, browser in
                BrowserRow(
                    browser: browser,
                    isSystemDefault: browser.bundleID == systemDefaultBundleID,
                    isManual: isManualEntry(browser.bundleID),
                    isVisible: visibilityBinding(for: browser, isExtraList: isExtraList),
                    onRemoveManual: isManualEntry(browser.bundleID) ? {
                        ManualBrowserList.shared.remove(bundleID: browser.bundleID)
                        refresh()
                    } : nil
                )
                if index < browsers.count - 1 {
                    Divider().padding(.leading, 56)
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

    /// "That's everything Junction found." — sits below the detected
    /// browsers as an invitation rather than an error state.
    private var addManuallyCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "folder.badge")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("That's everything Junction found.")
                    .font(.system(size: 13, weight: .semibold))
                Text("Junction scans `/Applications` and `~/Applications`. "
                     + "Install another browser, then click Refresh — or add one by bundle ID.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Button("+ Add manually") {
                showAddSheet = true
            }
            .controlSize(.small)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .foregroundStyle(Color.primary.opacity(0.18))
        )
    }

    // MARK: - Helpers

    /// Bundle ID of the macOS default `http` handler. If Junction itself
    /// is the default (the expected case), fall through to Safari since
    /// that's the factory default users typically come from.
    /// `URL` doesn't expose `bundleIdentifier` directly — we resolve via
    /// `Bundle(url:)` since that's the only path that always works for
    /// `.app` containers on macOS.
    private var systemDefaultBundleID: String {
        guard let probe = URL(string: "https://example.com"),
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: probe),
              let bundleID = Bundle(url: appURL)?.bundleIdentifier
        else { return "com.apple.Safari" }
        return bundleID == "com.pkajaba.junction" ? "com.apple.Safari" : bundleID
    }

    private func isManualEntry(_ bundleID: String) -> Bool {
        manualList.entries.contains(where: { $0.bundleID == bundleID })
    }

    private func visibilityBinding(for browser: DetectedBrowser, isExtraList: Bool) -> Binding<Bool> {
        if isExtraList {
            return Binding(
                get: { extraList.isEnabled(browser.bundleID) },
                set: { extraList.setEnabled(browser.bundleID, enabled: $0) }
            )
        } else {
            return Binding(
                get: { !hideList.isHidden(browser.bundleID) },
                set: { hideList.setHidden(browser.bundleID, hidden: !$0) }
            )
        }
    }

    private func refresh() {
        allBrowsers = BrowserDetector.shared.detectAll()
        otherApps = BrowserDetector.shared.detectUnrecognized()
    }
}

// MARK: - Row

private struct BrowserRow: View {
    let browser: DetectedBrowser
    let isSystemDefault: Bool
    let isManual: Bool
    @Binding var isVisible: Bool
    let onRemoveManual: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: browser.icon)
                .resizable()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(browser.displayName)
                        .font(.body)
                    if isSystemDefault {
                        systemDefaultPill
                    }
                    if isManual {
                        manuallyAddedPill
                    }
                }
                Text(browser.bundleID)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            if let onRemoveManual {
                Button(action: onRemoveManual) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Remove this manually-added browser")
            }
            Toggle("Visible in picker", isOn: $isVisible)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var systemDefaultPill: some View {
        Text("SYSTEM DEFAULT")
            .font(.system(size: 9, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            )
    }

    private var manuallyAddedPill: some View {
        Text("MANUAL")
            .font(.system(size: 9, weight: .semibold))
            .kerning(0.4)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
    }
}

// MARK: - Add-browser sheet

private struct ManualBrowserSheet: View {
    let onSave: (_ bundleID: String, _ name: String) -> Void

    @State private var bundleID: String = ""
    @State private var displayName: String = ""
    @Environment(\.dismiss) private var dismiss

    private var canSave: Bool {
        let id = bundleID.trimmingCharacters(in: .whitespaces)
        let name = displayName.trimmingCharacters(in: .whitespaces)
        return !id.isEmpty && !name.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add browser manually")
                    .font(.system(size: 15, weight: .semibold))
                Text("Use this for browsers Junction's allowlist doesn't know yet, "
                     + "or for ones that aren't registered as an http handler.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                fieldRow(
                    label: "Bundle ID",
                    placeholder: "e.g. com.brave.Browser",
                    text: $bundleID,
                    monospaced: true
                )
                fieldRow(
                    label: "Display name",
                    placeholder: "e.g. Brave",
                    text: $displayName,
                    monospaced: false
                )
            }

            HStack {
                Spacer()
                Button("Cancel", action: { dismiss() })
                    .keyboardShortcut(.cancelAction)
                Button("Add browser") {
                    onSave(bundleID, displayName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private func fieldRow(
        label: String,
        placeholder: String,
        text: Binding<String>,
        monospaced: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(monospaced ? .system(size: 12, design: .monospaced) : .body)
        }
    }
}
