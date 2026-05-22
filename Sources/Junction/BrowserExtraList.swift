import Foundation
import Combine

/// Apps the user has manually promoted into the picker even though they
/// aren't on `BrowserDetector`'s built-in known-browser allowlist.
///
/// The allowlist keeps non-browsers (Slack, BetterTouchTool, …) out of
/// the picker by default. The flip side: a genuine browser Junction
/// doesn't recognize yet — a new release, a niche Chromium fork — would
/// be invisible with no recourse. This list is that recourse. Settings →
/// Browsers → "Other apps" surfaces every unrecognized `http` handler
/// and lets the user toggle a real browser in.
///
/// Stored in `UserDefaults` as a small array of bundle-ID strings.
@MainActor
final class BrowserExtraList: ObservableObject {

    static let shared = BrowserExtraList()

    private static let defaultsKey = "BrowserExtraList.enabled"

    @Published private(set) var enabled: Set<String> = []

    private init() {
        if let array = UserDefaults.standard.array(forKey: Self.defaultsKey) as? [String] {
            self.enabled = Set(array)
        }
    }

    func isEnabled(_ bundleID: String) -> Bool {
        enabled.contains(bundleID)
    }

    func setEnabled(_ bundleID: String, enabled isEnabled: Bool) {
        if isEnabled {
            enabled.insert(bundleID)
        } else {
            enabled.remove(bundleID)
        }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(enabled), forKey: Self.defaultsKey)
    }
}
