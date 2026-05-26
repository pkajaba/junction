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
        // SwiftUI's `App.body` must return at least one Scene. The
        // Settings window itself is presented imperatively by
        // `SettingsWindowController` from the menu-bar item — see that
        // file for why we don't use SwiftUI's `Settings { ... }` scene.
        // `EmptyView` satisfies the requirement without adding any
        // window of its own.
        Settings {
            EmptyView()
        }
    }
}
