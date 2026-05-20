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
/// Pin button is gone — Smart Suggestion mode (which would surface the
/// explicit "Always" button) is deferred; "always" is ⌥↩ in this mode,
/// documented in the keyboard footer.
struct PickerView: View {
    let url: URL
    let browsers: [DetectedBrowser]
    let onResolve: (PickerController.Outcome) -> Void

    @State private var selectedIndex: Int = 0
    @State private var optionHeld: Bool = false
    @FocusState private var hasFocus: Bool
    @State private var modifierMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            urlBar
            list
            footer
        }
        .frame(width: 560)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.white.opacity(0.55), lineWidth: 0.5)
        )
        .shadow(color: Color(red: 0.08, green: 0.16, blue: 0.12).opacity(0.38),
                radius: 40, y: 20)
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
        ZStack {
            // System blur. NSVisualEffectView works on all supported macOS
            // versions; on macOS 26 it composites with the new Liquid Glass
            // post-processing for free.
            VisualEffectBackground(material: .popover, blendingMode: .behindWindow)

            // Sheen gradient on top of the blur — gives the panel a subtle
            // brightness curve from top to bottom (the design spec calls
            // this out as the visual signature of the new chrome).
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.38), location: 0.0),
                    .init(color: Color.white.opacity(0.18), location: 0.6),
                    .init(color: Color.white.opacity(0.22), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Inset top highlight — barely visible but reads as "physical glass".
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: 1)
                Spacer()
            }
            .allowsHitTesting(false)
        }
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
                .foregroundStyle(.black)
            Text(pathQuery)
                .foregroundStyle(.black.opacity(0.5))
        }
        .font(.system(size: 12.5, design: .monospaced))
        .lineLimit(1)
        .truncationMode(.middle)
    }

    private var noRuleMatchBadge: some View {
        Text("no rule match")
            .font(.system(size: 10.5, weight: .medium))
            .foregroundStyle(.black.opacity(0.55))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.4))
            )
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if browsers.isEmpty {
            emptyState
        } else {
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
                        }
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 14)
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
        .foregroundStyle(.black.opacity(0.6))
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.18))
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5),
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

// MARK: - NSVisualEffectView bridge

/// SwiftUI wrapper for `NSVisualEffectView` so we can use the same blur
/// material the system Settings windows and menus use. Backed by AppKit,
/// works on every supported macOS version.
private struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
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
