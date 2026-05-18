import SwiftUI
import AppKit

/// The picker UI itself: a URL header, a grid of browser tiles, and a
/// keyboard-shortcut footer. The whole thing is keyboard-driven so a power
/// user never needs to reach for the mouse.
///
/// Two affordances for the "always for this domain" path:
///
/// 1. **Pin button** (visible). Each tile has a small pin icon in the
///    top-right corner. Clicking it saves a rule for the URL's host and
///    routes the current URL via that rule.
/// 2. **⌥ modifier** (power user). Hold Option while clicking, pressing a
///    digit, or pressing Return — same effect.
struct PickerView: View {
    let url: URL
    let browsers: [DetectedBrowser]
    let onResolve: (PickerController.Outcome) -> Void

    @State private var selectedIndex: Int = 0
    @State private var optionHeld: Bool = false
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
        .junctionPickerBackground(cornerRadius: 14, optionHeld: optionHeld)
        .frame(width: 540)
        .focusable()
        .focused($hasFocus)
        .focusEffectDisabled()
        .onAppear {
            hasFocus = true
            startModifierMonitor()
        }
        .onDisappear { stopModifierMonitor() }
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
            if optionHeld, let host = url.host {
                Label("always for \(host)", systemImage: "pin.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
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
                    isSelected: index == selectedIndex,
                    optionHeld: optionHeld,
                    pinTooltip: pinTooltip,
                    onOpenOnce: {
                        selectedIndex = index
                        commitOnce(browser: browser)
                    },
                    onOpenAlways: {
                        selectedIndex = index
                        commitAlways(browser: browser)
                    }
                )
                .help(browser.displayName)
            }
        }
        .padding(16)
    }

    private var pinTooltip: String {
        if let host = url.host {
            return "Always open \(host) here"
        }
        return "Always open this site here"
    }

    // MARK: - Empty state

    private var noBrowsersDetected: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No recognized browsers installed")
                .font(.headline)
            Text("Junction's known-browser list didn't match any installed app.\nOpen Settings → Browsers to see what's detected.")
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
                KeyHint(keys: "↩", text: "open once")
                Label {
                    Text("or click pin for always")
                } icon: {
                    Image(systemName: "pin.fill")
                }
                .labelStyle(.titleAndIcon)
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

    /// Keyboard commit path — Enter / digit. Reads ⌥ to decide once vs always.
    private func commitSelected() {
        guard browsers.indices.contains(selectedIndex) else {
            onResolve(.cancelled)
            return
        }
        let browser = browsers[selectedIndex]
        if NSEvent.modifierFlags.contains(.option) {
            commitAlways(browser: browser)
        } else {
            commitOnce(browser: browser)
        }
    }

    private func commitOnce(browser: DetectedBrowser) {
        onResolve(.picked(browser))
    }

    private func commitAlways(browser: DetectedBrowser) {
        onResolve(.pickedAlways(browser))
    }

    // MARK: - Modifier key monitor

    @State private var modifierMonitor: Any?

    private func startModifierMonitor() {
        modifierMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            optionHeld = event.modifierFlags.contains(.option)
            return event
        }
        // Seed initial state.
        optionHeld = NSEvent.modifierFlags.contains(.option)
    }

    private func stopModifierMonitor() {
        if let monitor = modifierMonitor {
            NSEvent.removeMonitor(monitor)
            modifierMonitor = nil
        }
    }
}

// MARK: - Tile

private struct BrowserTile: View {
    let browser: DetectedBrowser
    let number: Int
    let isSelected: Bool
    let optionHeld: Bool
    let pinTooltip: String
    let onOpenOnce: () -> Void
    let onOpenAlways: () -> Void

    @State private var hoveringPin: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main tile body — clicking anywhere here opens once.
            Button(action: onOpenOnce) {
                tileBody
            }
            .buttonStyle(.plain)

            // Pin button — clicking opens AND saves a rule.
            // SwiftUI's Button-inside-Button is handled correctly by the
            // hit-test system: clicks on the pin reach this Button, not
            // the parent.
            Button(action: onOpenAlways) {
                Image(systemName: "pin.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(
                        Color.accentColor.opacity(pinProminence),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .padding(6)
            .onHover { hoveringPin = $0 }
            .help(pinTooltip)
        }
    }

    /// How loud the pin should look right now. Subtle by default so it
    /// doesn't fight the icon; bold when the user is interacting with it
    /// or holding ⌥ (signalling intent).
    private var pinProminence: Double {
        if hoveringPin { return 1.0 }
        if optionHeld && isSelected { return 1.0 }
        if isSelected { return 0.55 }
        return 0.35
    }

    private var tileBody: some View {
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
        .junctionTileBackground(isSelected: isSelected)
        .contentShape(Rectangle())
        .accessibilityLabel("\(browser.displayName), press \(number) or Return to open once. Press the pin button to always open this domain here.")
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
