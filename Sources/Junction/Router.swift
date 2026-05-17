import AppKit
import Foundation

/// Decides where to send each received URL.
///
/// M2 hardcoded Safari. M3 (this) shows the picker for every URL — there
/// are no rules yet. M4 introduces a rule engine that short-circuits the
/// picker for matched domains.
@MainActor
final class Router {

    static let shared = Router()
    private init() {}

    /// Route a URL: show the picker, then on user choice, open in the
    /// chosen browser. Updates the log entry's routing status throughout.
    func route(_ url: URL, entryID: UUID) {
        guard isRoutableScheme(url) else {
            URLLog.shared.updateRouting(for: entryID, to: .unsupported)
            return
        }

        PickerController.shared.present(url: url) { [weak self] outcome in
            Task { @MainActor in
                switch outcome {
                case .picked(let browser):
                    self?.open(url: url, in: browser, entryID: entryID)
                case .cancelled:
                    URLLog.shared.updateRouting(for: entryID, to: .cancelled)
                }
            }
        }
    }

    // MARK: - Open in a specific browser

    private func open(url: URL, in browser: DetectedBrowser, entryID: UUID) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: browser.appURL,
            configuration: config
        ) { _, error in
            Task { @MainActor in
                if let error {
                    URLLog.shared.updateRouting(
                        for: entryID,
                        to: .failed(reason: error.localizedDescription)
                    )
                } else {
                    URLLog.shared.updateRouting(
                        for: entryID,
                        to: .routed(to: browser.displayName)
                    )
                }
            }
        }
    }

    // MARK: - Scheme guard

    /// Only `http` and `https` are routable to browsers. Anything else (e.g.
    /// `mailto:`, `file:`, `discord:`) is foreign — record it as unsupported
    /// rather than silently dropping or guessing.
    private func isRoutableScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}
