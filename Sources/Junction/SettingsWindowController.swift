import AppKit
import SwiftUI

/// Owns the Settings window and presents it on demand.
///
/// We *could* use SwiftUI's built-in `Settings { ... }` scene + AppKit's
/// `showSettingsWindow:` responder action — that works for regular (Dock)
/// apps. For `LSUIElement` menu-bar apps it's unreliable: the action
/// gets dispatched into a responder chain that doesn't always include
/// the Settings scene's hidden window, so the click silently does
/// nothing. Presenting the window ourselves keeps the trigger path
/// short and predictable.
@MainActor
final class SettingsWindowController {

    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    /// Show the Settings window, creating it on first use. Re-entrant —
    /// if the window already exists, just bring it forward.
    func show() {
        if window == nil {
            window = makeWindow()
        }
        guard let window else { return }

        // LSUIElement apps stay backgrounded until explicitly activated.
        // The deprecated `ignoringOtherApps: true` variant is still the
        // only call that reliably steals focus from a frontmost app —
        // macOS 14's cooperative `.activate()` declines in this scenario.
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: SettingsScene())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Junction Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 760, height: 540))
        window.center()
        // Keep the window around when closed — re-opening should keep the
        // user's last tab + size, and skip re-construction.
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("JunctionSettings")
        // Show on every Space the user switches to, like other agent apps
        // (Bartender, Magnet). Falls back to the active Space if pinned.
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        return window
    }
}
