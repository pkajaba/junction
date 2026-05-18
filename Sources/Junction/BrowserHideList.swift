import Foundation

/// Which detected browsers the user has chosen to hide from the picker.
///
/// Stored in `UserDefaults` — a tiny set of bundle ID strings, no need
/// for the full JSON file machinery. Reactive: `@Published hidden` lets
/// the picker and the Browsers settings tab react to toggles.
@MainActor
final class BrowserHideList: ObservableObject {

    static let shared = BrowserHideList()

    private static let defaultsKey = "BrowserHideList.hidden"

    @Published private(set) var hidden: Set<String> = []

    private init() {
        if let array = UserDefaults.standard.array(forKey: Self.defaultsKey) as? [String] {
            self.hidden = Set(array)
        }
    }

    func isHidden(_ bundleID: String) -> Bool {
        hidden.contains(bundleID)
    }

    func setHidden(_ bundleID: String, hidden isHidden: Bool) {
        if isHidden {
            hidden.insert(bundleID)
        } else {
            hidden.remove(bundleID)
        }
        persist()
    }

    func toggle(_ bundleID: String) {
        setHidden(bundleID, hidden: !isHidden(bundleID))
    }

    private func persist() {
        UserDefaults.standard.set(Array(hidden), forKey: Self.defaultsKey)
    }
}
