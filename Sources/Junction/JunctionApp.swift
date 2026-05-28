import SwiftUI
import AppKit

/// Entry point for the Junction app.
///
/// Junction is a menu-bar agent (`LSUIElement = true` in Info.plist) — no
/// Dock icon, no app-switcher entry. The visible surfaces are:
///
/// 1. **The status item** (`MenuBarController`, owned by `AppDelegate`) —
///    the persistent affordance for opening Settings and quitting.
/// 2. **The picker window** — borderless, on demand, when a URL has no
///    matching rule.
/// 3. **The Settings window** — standard `Settings` scene, opened from
///    the status menu or ⌘, while Settings is key.
///
/// There's no `WindowGroup` on purpose: the Debug Log is now an "Activity"
/// tab inside Settings, so the app has a single, predictable settings
/// surface instead of a separate window the user has to track.
@main
struct JunctionApp: App {
    /// Bridge to AppKit so we can hook into URL events at the application
    /// level (rather than only when a window happens to be foregrounded).
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // `App.body` must return at least one Scene. The actual Settings
        // window is built imperatively by `SettingsWindowController`
        // (a manual `NSWindow` + `NSToolbar`) because SwiftUI's
        // `Settings` scene won't open for an `LSUIElement` app — see that
        // file. `EmptyView` here just satisfies the protocol.
        Settings {
            EmptyView()
        }
    }
}
