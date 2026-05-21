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
        // before windows draw, and load persisted rules.
        Task { @MainActor in
            AppearanceSettings.shared.apply()
            RuleStore.shared.startup()
        }
    }

    // MARK: - Modern API

    /// Called by AppKit when one or more URLs are handed to us — for example
    /// when the user clicks a link in another app and Junction is the
    /// registered default browser.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            Task { @MainActor in
                let id = URLLog.shared.append(url, source: .openURLs)
                Router.shared.route(url, entryID: id)
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

        Task { @MainActor in
            let id = URLLog.shared.append(url, source: .appleEvent)
            Router.shared.route(url, entryID: id)
        }
    }
}
