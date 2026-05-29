import AppKit

/// Application-level URL receiver.
///
/// macOS delivers URLs to the default browser via two paths:
///
/// 1. `NSApplicationDelegate.application(_:open:)` — modern API, called with
///    an array of URLs at launch and while running.
/// 2. `kAEGetURL` Apple Event — the older mechanism, still used by some apps
///    (especially older or scripted ones). We register for it as a belt-and-
///    suspenders measure so no URL is dropped.
///
/// Both paths funnel through `URLLog.shared.append` and then `Router.shared.route`.
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for the legacy GetURL Apple Event in addition to the
        // modern openURLs delegate method.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Apply the saved appearance preference (System / Light / Dark)
        // before windows draw, load persisted rules, and stand up the
        // menu-bar item — Junction's only persistent UI now that the
        // app is `LSUIElement`.
        Task { @MainActor in
            AppearanceSettings.shared.apply()
            RuleStore.shared.startup()
            _ = MenuBarController.shared
        }
    }

    // MARK: - Reopen / activation guard

    /// Junction is a menu-bar agent with no primary window. Its only
    /// SwiftUI scene is the placeholder `Settings { EmptyView() }` (the
    /// real Settings is a hand-built `NSWindow`). When the app is
    /// *reactivated* with no visible window — e.g. macOS reopening the
    /// already-running default browser to hand it a link — AppKit's default
    /// reopen handling tries to surface "a" window, and the only scene it
    /// can open is that placeholder Settings window. That's the stray
    /// Settings panel that flashed up on link clicks.
    ///
    /// Returning `false` suppresses the automatic behavior. The picker and
    /// the real Settings window are both shown explicitly via
    /// `makeKeyAndOrderFront`, so nothing the user actually wants is lost.
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        false
    }

    // MARK: - Modern API

    /// Called by AppKit when one or more URLs are handed to us — for example
    /// when the user clicks a link in another app and Junction is the
    /// registered default browser.
    func application(_ application: NSApplication, open urls: [URL]) {
        let sourceApp = Self.openerBundleID()
        for url in urls {
            Task { @MainActor in
                let id = URLLog.shared.append(url, source: .openURLs, sourceApp: sourceApp)
                Router.shared.route(url, sourceApp: sourceApp, entryID: id)
            }
        }
    }

    // MARK: - Legacy Apple Event API

    /// Receives the `kAEGetURL` Apple Event. Extracts the URL string from the
    /// direct-object parameter and forwards it to the log + router.
    @objc func handleGetURLEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        guard
            let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: urlString)
        else { return }

        let sourceApp = Self.openerBundleID()
        Task { @MainActor in
            let id = URLLog.shared.append(url, source: .appleEvent, sourceApp: sourceApp)
            Router.shared.route(url, sourceApp: sourceApp, entryID: id)
        }
    }

    // MARK: - Source-app detection

    /// Best-effort bundle ID of the app the URL was opened *from*.
    ///
    /// When macOS hands Junction a URL, the click's originating app is
    /// still the frontmost process — Junction is a background agent and
    /// doesn't steal focus to receive a URL. So `frontmostApplication`
    /// is a reliable opener heuristic. If it somehow reads back as
    /// Junction itself (defensive), we return `nil` = "unknown source".
    static func openerBundleID() -> String? {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              bundleID != "com.pkajaba.junction"
        else { return nil }
        return bundleID
    }
}
