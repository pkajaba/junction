import SwiftUI

/// Entry point for the Junction app.
///
/// M1 scope: launch, register as `http://` / `https://` URL handler (via
/// `Info.plist` `CFBundleURLTypes`), receive URL events, and display them in
/// a debug window. No routing, no rules, no picker yet — that's M2+.
@main
struct JunctionApp: App {
    /// Bridge to AppKit so we can hook into URL events at the application
    /// level (rather than only when a window happens to be foregrounded).
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Shared, app-wide log of URLs Junction has received since launch.
    /// Singleton because the URL-receiving path (`AppDelegate`, Apple Event
    /// handlers) needs to reach it from outside the SwiftUI view graph.
    @StateObject private var log = URLLog.shared

    var body: some Scene {
        WindowGroup("Junction — Debug Log", id: "debug") {
            DebugLogView()
                .environmentObject(log)
                .frame(minWidth: 520, minHeight: 360)
        }
        .windowResizability(.contentMinSize)
        .commands {
            // Hide menu items we don't use yet so the menu bar looks intentional.
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Clear Log") { log.clear() }
                    .keyboardShortcut(.delete, modifiers: [.command, .shift])
                    .disabled(log.entries.isEmpty)
            }
        }
    }
}
