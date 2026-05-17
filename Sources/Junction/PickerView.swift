import SwiftUI
import AppKit

/// The picker UI itself: a URL header, a grid of browser tiles, and a
/// keyboard-shortcut footer. The whole thing is keyboard-driven so a power
/// user never needs to reach for the mouse.
struct PickerView: View {
    let url: URL
    let browsers: [DetectedBrowser]
    let onResolve: (PickerController.Outcome) -> Void

    @State private var selectedIndex: Int = 0
    @FocusState private var hasFocus: Bool

    private let columnCount = 4
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            urlBar
            Divider()
            if browsers.isEmpty {
                noBrowsersDetected
            } else {
                grid
            }
            Divider()
            footer
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        )
        .frame(width: 540)
        .focusable()
        .focused($hasFocus)
        .focusEffectDisabled()
        .onAppear { hasFocus = true }
        .onKeyPress(.escape) {
            onResolve(.cancelled)
            return .handled
        }
        .onKeyPress(.return) {
            commitSelected()
            return .handled
        }
        .onKeyPress(.leftArrow)  { move(by: -1);            return .handled }
        .onKeyPress(.rightArrow) { move(by:  1);            return .handled }
        .onKeyPress(.upArrow)    { move(by: -columnCount); return .handled }
        .onKeyPress(.downArrow)  { move(by:  columnCount); return .handled }
        // Number keys 1-9: jump straight to that tile and open it.
        .onKeyPress { press in
            guard
                let digit = Int(press.characters),
                digit >= 1, digit <= browsers.count
            else { return .ignored }
            selectedIndex = digit - 1
            commitSelected()
            return .handled
        }
    }

    // MARK: - Header

    private var urlBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .foregroundStyle(.secondary)
            Text(url.absoluteString)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Grid

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(browsers.enumerated()), id: \.element.bundleID) { index, browser in
                BrowserTile(
                    browser: browser,
                    number: index + 1,
                    isSelected: index == selectedIndex
                )
                .onTapGesture {
                    selectedIndex = index
                    commitSelected()
                }
                .help(browser.displayName)
            }
        }
        .padding(16)
    }

    // MARK: - Empty state

    private var noBrowsersDetected: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No recognized browsers installed")
                .font(.headline)
            Text("Junction's known-browser list didn't match any installed app.\nA settings UI to add unlisted apps is coming in M5.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            if !browsers.isEmpty {
                KeyHint(keys: "1–\(min(browsers.count, 9))", text: "pick")
                KeyHint(keys: "←→", text: "move")
                if browsers.count > columnCount {
                    KeyHint(keys: "↑↓", text: "rows")
                }
                KeyHint(keys: "↩", text: "open")
            }
            Spacer()
            KeyHint(keys: "esc", text: "cancel")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Selection logic

    private func move(by delta: Int) {
        guard !browsers.isEmpty else { return }
        let count = browsers.count
        // Modulo with wrap-around in both directions.
        selectedIndex = ((selectedIndex + delta) % count + count) % count
    }

    private func commitSelected() {
        guard browsers.indices.contains(selectedIndex) else {
            onResolve(.cancelled)
            return
        }
        onResolve(.picked(browsers[selectedIndex]))
    }
}

// MARK: - Tile

private struct BrowserTile: View {
    let browser: DetectedBrowser
    let number: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                Image(nsImage: browser.icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 64, height: 64)
                Text("\(number)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.6), in: Capsule())
                    .padding(2)
            }
            Text(browser.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .accessibilityLabel("\(browser.displayName), press \(number) or Return to open")
    }
}

// MARK: - Footer pill

private struct KeyHint: View {
    let keys: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Text(keys)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 4))
            Text(text)
        }
    }
}

// MARK: - Previews

#Preview("Many browsers") {
    PickerView(
        url: URL(string: "https://news.ycombinator.com/item?id=123456")!,
        browsers: [
            DetectedBrowser(bundleID: "com.apple.Safari",
                            displayName: "Safari",
                            appURL: URL(fileURLWithPath: "/Applications/Safari.app")),
            DetectedBrowser(bundleID: "com.google.Chrome",
                            displayName: "Google Chrome",
                            appURL: URL(fileURLWithPath: "/Applications/Google Chrome.app")),
            DetectedBrowser(bundleID: "company.thebrowser.Browser",
                            displayName: "Arc",
                            appURL: URL(fileURLWithPath: "/Applications/Arc.app")),
            DetectedBrowser(bundleID: "org.mozilla.firefox",
                            displayName: "Firefox",
                            appURL: URL(fileURLWithPath: "/Applications/Firefox.app")),
        ],
        onResolve: { _ in }
    )
    .padding(20)
}

#Preview("None detected") {
    PickerView(
        url: URL(string: "https://example.com")!,
        browsers: [],
        onResolve: { _ in }
    )
    .padding(20)
}
