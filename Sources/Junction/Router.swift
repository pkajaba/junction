import AppKit
import Foundation

/// Decides where to send each received URL and asks AppKit to open it.
///
/// M2: hardcoded to Safari. M4 replaces the body of `route(_:entryID:)`
/// with rule-based matching, and the picker arrives at M3 to handle
/// "no rule matched" — but the public surface of this type shouldn't
/// have to change much.
@MainActor
final class Router {

    /// Identifies a browser by its macOS bundle identifier.
    enum Browser: Equatable {
        case safari

        var bundleID: String {
            switch self {
            case .safari: return "com.apple.Safari"
            }
        }

        var displayName: String {
            switch self {
            case .safari: return "Safari"
            }
        }
    }

    static let shared = Router()
    private init() {}

    /// Route a URL to the (hardcoded for M2) target browser. Updates the
    /// log entry's routing status as soon as the result is known.
    func route(_ url: URL, entryID: UUID) {
        guard isRoutableScheme(url) else {
            URLLog.shared.updateRouting(for: entryID, to: .unsupported)
            return
        }

        let target: Browser = .safari

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleID) else {
            URLLog.shared.updateRouting(
                for: entryID,
                to: .failed(reason: "\(target.displayName) not installed")
            )
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
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
                        to: .routed(to: target.displayName)
                    )
                }
            }
        }
    }

    // MARK: - Private

    /// Only `http` and `https` are routable to browsers. Anything else (e.g.
    /// `mailto:`, `file:`, `discord:`) is foreign — record it as unsupported
    /// rather than silently dropping or guessing.
    private func isRoutableScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}
