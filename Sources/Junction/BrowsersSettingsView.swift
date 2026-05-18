import SwiftUI
import AppKit

/// Settings → Browsers tab.
///
/// Lists every browser Junction recognizes as installed and lets the user
/// hide unwanted ones from the picker. Hidden state is persisted via
/// `BrowserHideList`.
struct BrowsersSettingsView: View {

    @ObservedObject private var hideList = BrowserHideList.shared

    /// Snapshot taken on appear; we don't need this to be reactive — the
    /// user can re-open Settings to refresh, and detection is fast.
    @State private var allBrowsers: [DetectedBrowser] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            list
        }
        .onAppear { refresh() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Browsers")
                .font(.title2.weight(.semibold))
            Text("Toggle which browsers appear in the picker. Hidden browsers can still be rule targets — they just won't clutter the picker for unmatched URLs.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") { refresh() }
                    .buttonStyle(.borderless)
            }
        }
        .padding(20)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if allBrowsers.isEmpty {
            empty
        } else {
            List {
                ForEach(allBrowsers) { browser in
                    BrowserRow(
                        browser: browser,
                        isVisible: Binding(
                            get: { !hideList.isHidden(browser.bundleID) },
                            set: { hideList.setHidden(browser.bundleID, hidden: !$0) }
                        )
                    )
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No recognized browsers detected")
                .font(.headline)
            Text("Junction looks for a hardcoded set of known browser bundle IDs.\nIf you have one installed that isn't recognized, open an issue.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func refresh() {
        allBrowsers = BrowserDetector.shared.detectAll()
    }
}

// MARK: - Row

private struct BrowserRow: View {
    let browser: DetectedBrowser
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: browser.icon)
                .resizable()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(browser.displayName)
                    .font(.body)
                Text(browser.bundleID)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            Spacer()
            Toggle("Visible in picker", isOn: $isVisible)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}
