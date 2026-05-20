import Foundation
import Combine

/// Which handoffs the user has turned on. Persisted in UserDefaults as a
/// sorted array of `AppHandoff.rawValue` strings.
///
/// Defaults to **empty** (no handoffs enabled). The user explicitly opts
/// in per app from Settings → Advanced. This is the safe default — the
/// existing rule-based routing keeps working unchanged for anyone who
/// doesn't touch this section.
@MainActor
final class AppHandoffSettings: ObservableObject {

    static let shared = AppHandoffSettings()

    @Published var enabled: Set<AppHandoff> {
        didSet { persist() }
    }

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: Keys.enabled) ?? []
        self.enabled = Set(stored.compactMap(AppHandoff.init(rawValue:)))
    }

    func isEnabled(_ handoff: AppHandoff) -> Bool {
        enabled.contains(handoff)
    }

    func setEnabled(_ handoff: AppHandoff, _ value: Bool) {
        if value {
            enabled.insert(handoff)
        } else {
            enabled.remove(handoff)
        }
    }

    /// Find the first enabled handoff whose `transform` matches `url`.
    /// Returns both the handoff and the rewritten URL.
    /// Nil = no enabled handoff claims this URL.
    func handoff(for url: URL) -> (AppHandoff, URL)? {
        for handoff in AppHandoff.allCases where enabled.contains(handoff) {
            if let rewritten = handoff.transform(url) {
                return (handoff, rewritten)
            }
        }
        return nil
    }

    private func persist() {
        let raw = enabled.map(\.rawValue).sorted()
        UserDefaults.standard.set(raw, forKey: Keys.enabled)
    }

    private enum Keys {
        static let enabled = "AppHandoffSettings.enabled"
    }
}
