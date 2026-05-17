import SwiftUI
import AppKit

/// Entry point for the Junction app.
///
/// M4 scope: rule-based silent routing with picker fallback. Every URL is
/// run against `rules.json`; matches open directly in the rule's target,
/// non-matches show the picker.
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
                .frame(minWidth: 560, minHeight: 400)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Clear Log") { log.clear() }
                    .keyboardShortcut(.delete, modifiers: [.command, .shift])
                    .disabled(log.entries.isEmpty)
                Divider()
                Button("Reload Rules") { RuleStore.shared.load() }
                    .keyboardShortcut("r", modifiers: [.command, .option])
                Button("Reveal rules.json in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([RuleStore.storeURL])
                }
            }
        }
    }
}
