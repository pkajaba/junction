import SwiftUI
import AppKit

/// Picker — v2 design (handoff Phase B).
///
/// 560 px wide floating panel with a 26 px corner radius. Liquid Glass
/// chrome — a system blur (`NSVisualEffectView` / `.glassEffect()`) with
/// a white-tinted gradient overlay for the sheen. Vertical numbered
/// rows; the first row is the "default" and gets a saturated blue
/// gradient highlight with a `DEFAULT` eyebrow.
///
/// Each row carries a pin button — click it to save a rule that always
/// routes this host to that browser. ⌥↩ does the same from the keyboard.
struct PickerView: View {
    let url: URL
    let browsers: [DetectedBrowser]
    let onResolve: (PickerController.Outcome) -> Void

    @State private var selectedIndex: Int = 0
    @State private var optionHeld: Bool = false
    @FocusState private var hasFocus: Bool
    @State private var modifierMonitor: Any?

    /// Panel corner radius. Shared by the SwiftUI clip/border, the
    /// visual-effect view's mask, *and* the window's contentView layer
    /// rounding (in `PickerController`) so the blur, content, stroke, and
    /// the window edge all round to the same shape.
    static let panelCornerRadius: CGFloat = 26

    // Accessibility: faint hairlines disappear under Increase Contrast and
    // under Reduce Transparency (where the panel goes opaque and a 0.5 pt
    // edge stops reading). Bump edge weight in those modes.
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var emphasizeEdges: Bool {
        contrast == .increased || reduceTransparency
    }
    private var panelBorderColor: Color {
        Color.primary.opacity(emphasizeEdges ? 0.5 : 0.14)
    }
    private var panelBorderWidth: CGFloat {
        emphasizeEdges ? 1 : 0.5
    }
    private var dividerColor: Color {
        Color.primary.opacity(emphasizeEdges ? 0.45 : 0.12)
    }

    var body: some View {
        VStack(spacing: 0) {
            urlBar
            list
            footer
        }
        .frame(width: 560)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: Self.panelCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Self.panelCornerRadius, style: .continuous)
                .strokeBorder(panelBorderColor, lineWidth: panelBorderWidth)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 30, y: 16)
        .focusable()
        .focused($hasFocus)
        .focusEffectDisabled()
        .onAppear {
            hasFocus = true
            startModifierMonitor()
        }
        .onDisappear { stopModifierMonitor() }
        .onKeyPress(.escape) { onResolve(.cancelled); return .handled }
        .onKeyPress(.return) { commitSelected(); return .handled }
        .onKeyPress(.upArrow)   { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection( 1); return .handled }
        .onKeyPress { press in
            guard let digit = Int(press.characters),
                  digit >= 1, digit <= browsers.count
            else { return .ignored }
            selectedIndex = digit - 1
            commitSelected()
            return .handled
        }
    }

    // MARK: - Panel material

    @ViewBuilder
    private var panelBackground: some View {
        // Clean system blur, no white sheen overlay — reads like Spotlight:
        // you see through it, it doesn't go milky. `.hudWindow` is the
        // material macOS uses for floating HUD panels; it's neutral and
        // adapts to light/dark. On macOS 26 it composites with Liquid Glass.
        //
        // `cornerRadius` matches the SwiftUI clipShape below. It's applied
        // as the visual-effect view's `maskImage`, because a
        // `.behindWindow` blur is composited by the WindowServer across the
        // whole window rect — SwiftUI's `.clipShape` can't round it, so
        // without the mask the blurred corners read as square behind the
        // rounded content.
        VisualEffectBackground(
            material: .hudWindow,
            blendingMode: .behindWindow,
            cornerRadius: Self.panelCornerRadius
        )
    }

    // MARK: - URL bar

    private var urlBar: some View {
        HStack(spacing: 10) {
            HostFavicon(host: url.host ?? "")
            urlText
            Spacer(minLength: 8)
            noRuleMatchBadge
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var urlText: some View {
        let host = url.host ?? ""
        let pathQuery: String = {
            var s = url.path
            if let q = url.query, !q.isEmpty { s += "?\(q)" }
            return s
        }()

        return HStack(spacing: 0) {
            Text(host)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(pathQuery)
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 12.5, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
    }

    private var noRuleMatchBadge: some View {
        Text("no rule match")
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
    }

    // MARK: - List

    /// Above this row count we switch to a `ScrollView`-backed list with a
    /// max height. Below it the natural VStack is used as-is — a bare
    /// ScrollView in our borderless, size-to-content window collapses to
    /// ~0 pt because nothing in the chain hands it a definite vertical
    /// size to work with.
    private static let scrollThreshold = 8

    @ViewBuilder
    private var list: some View {
        if browsers.isEmpty {
            emptyState
        } else if browsers.count > Self.scrollThreshold {
            scrollableRows
        } else {
            rowsStack
        }
    }

    /// The shared row stack. Used directly for short lists (so it can
    /// report its intrinsic height to the window) and wrapped in a
    /// ScrollView for long ones.
    private var rowsStack: some View {
        VStack(spacing: 4) {
            ForEach(Array(browsers.enumerated()), id: \.element.bundleID) { index, browser in
                PickerRow(
                    browser: browser,
                    number: index + 1,
                    isSelected: index == selectedIndex,
                    isDefault: index == 0,
                    onTap: {
                        selectedIndex = index
                        commitSelected()
                    },
                    onPin: {
                        // Pin = "always": open here AND save a host rule.
                        onResolve(.pickedAlways(browser))
                    }
                )
                .id(browser.bundleID)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    /// Capped, scrollable list for users with 9+ browsers. Selection
    /// stays in view as the user arrows through.
    private var scrollableRows: some View {
        ScrollViewReader { proxy in
            ScrollView {
                rowsStack
            }
            .frame(maxHeight: 380)
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: selectedIndex) { _, newIndex in
                guard browsers.indices.contains(newIndex) else { return }
                proxy.scrollTo(browsers[newIndex].bundleID, anchor: .center)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No recognized browsers installed")
                .font(.headline)
            Text("Open Settings → Browsers to see what's detected.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }

    // MARK: - Keyboard footer

    private var footer: some View {
        HStack(spacing: 14) {
            if !browsers.isEmpty {
                KeyHint(keys: "1-\(min(browsers.count, 9))", text: "pick")
                KeyHint(keys: "↑↓", text: "move")
                KeyHint(keys: "↩", text: "open")
                KeyHint(keys: "⌥↩", text: "always")
            }
            Spacer()
            KeyHint(keys: "esc", text: "cancel")
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        // The footer tint must round its own bottom corners to match the
        // panel's 26 pt radius — a plain Color fill leaves square corners
        // that poke past the panel's clip at the bottom edge.
        .background(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 26,
                bottomTrailingRadius: 26,
                style: .continuous
            )
            .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            Rectangle()
                .fill(dividerColor)
                .frame(height: emphasizeEdges ? 1 : 0.5),
            alignment: .top
        )
    }

    // MARK: - Selection logic

    private func moveSelection(_ delta: Int) {
        guard !browsers.isEmpty else { return }
        let count = browsers.count
        selectedIndex = ((selectedIndex + delta) % count + count) % count
    }

    private func commitSelected() {
        guard browsers.indices.contains(selectedIndex) else {
            onResolve(.cancelled)
            return
        }
        let browser = browsers[selectedIndex]
        let isAlways = NSEvent.modifierFlags.contains(.option)
        onResolve(isAlways ? .pickedAlways(browser) : .picked(browser))
    }

    private func startModifierMonitor() {
        modifierMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            optionHeld = event.modifierFlags.contains(.option)
            return event
        }
        optionHeld = NSEvent.modifierFlags.contains(.option)
    }

    private func stopModifierMonitor() {
        if let monitor = modifierMonitor {
            NSEvent.removeMonitor(monitor)
            modifierMonitor = nil
        }
    }
}

// MARK: - Row

private struct PickerRow: View {
    let browser: DetectedBrowser
    let number: Int
    let isSelected: Bool
    let isDefault: Bool
    let onTap: () -> Void
    let onPin: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: browser.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(browser.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .lineLimit(1)
                if isDefault {
                    Text("DEFAULT")
                        .font(.system(size: 10.5, weight: .semibold))
                        .kerning(0.4)
                        .foregroundStyle(isSelected
                                         ? Color.white.opacity(0.85)
                                         : Color.secondary)
                }
            }
            Spacer()
            PinButton(isSelected: isSelected, browserName: browser.displayName, action: onPin)
            KeyCap(text: "\(number)", isSelected: isSelected)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 30/255, green: 109/255, blue: 255/255).opacity(0.85),
                        Color(red: 30/255, green: 109/255, blue: 255/255).opacity(0.95),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Inset top highlight to give the selected row physical depth.
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 1)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .shadow(color: Color(red: 30/255, green: 109/255, blue: 255/255).opacity(0.3),
                    radius: 5, y: 2)
        } else {
            Color.clear
        }
    }
}

// MARK: - Pin button (per-row "always for this site" affordance)

/// Clicking the pin opens the link AND saves a host rule, so the same
/// domain skips the picker next time. The keyboard equivalent is ⌥↩.
/// Subtle at rest, accent-filled on hover so it's discoverable without
/// shouting on every row.
private struct PinButton: View {
    let isSelected: Bool
    let browserName: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "pin.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)
                .background(Circle().fill(circleColor))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Always open this site in \(browserName)")
    }

    private var iconColor: Color {
        if hovering { return .white }
        return isSelected ? .white.opacity(0.9) : .secondary
    }

    private var circleColor: Color {
        if hovering { return .accentColor }
        return isSelected ? Color.white.opacity(0.18) : Color.primary.opacity(0.08)
    }
}

// MARK: - Keycap (the "1" on the right of each row)

private struct KeyCap: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(isSelected ? Color.white : Color.black.opacity(0.7))
            .frame(minWidth: 16)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isSelected
                          ? Color.white.opacity(0.18)
                          : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(isSelected
                                  ? Color.white.opacity(0.25)
                                  : Color.black.opacity(0.1),
                                  lineWidth: 0.5)
            )
    }
}

// MARK: - Footer keyboard hint

private struct KeyHint: View {
    let keys: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Text(keys)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.75))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                )
            Text(text)
        }
    }
}

// MARK: - Host favicon placeholder

/// 18×18 colored square with the first letter of the host — a lightweight
/// stand-in for real per-site favicons. The design handoff suggests
/// fetching `https://www.google.com/s2/favicons?domain=<host>&sz=64` as a
/// follow-up; that introduces a network dependency we want to weigh
/// carefully (privacy: each picker pop sends a request to Google). Local
/// glyph for v2; favicon-fetch can be a later opt-in.
private struct HostFavicon: View {
    let host: String

    private var firstChar: String {
        String(host.prefix(1)).uppercased()
    }

    private var tint: Color {
        // Deterministic-but-pretty color from the host string. Hash → hue.
        let hash = host.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.55)
    }

    var body: some View {
        Text(firstChar.isEmpty ? "?" : firstChar)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

// MARK: - Previews

#Preview("Two browsers (fallback)") {
    PickerView(
        url: URL(string: "https://news.ycombinator.com/item?id=39842110")!,
        browsers: [
            DetectedBrowser(bundleID: "com.apple.Safari",
                            displayName: "Safari",
                            appURL: URL(fileURLWithPath: "/Applications/Safari.app")),
            DetectedBrowser(bundleID: "com.google.Chrome",
                            displayName: "Google Chrome",
                            appURL: URL(fileURLWithPath: "/Applications/Google Chrome.app")),
        ],
        onResolve: { _ in }
    )
    .padding(24)
}

#Preview("Many browsers") {
    PickerView(
        url: URL(string: "https://example.com/some/long/path?query=value")!,
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
    .padding(24)
}
