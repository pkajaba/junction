import AppKit
import Combine

/// The user's preferred app appearance — follow the system, or force
/// Light / Dark for Junction only. Applied app-wide via
/// `NSApplication.appearance`.
@MainActor
final class AppearanceSettings: ObservableObject {

    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }

        /// The `NSAppearance` to force, or nil to follow the system.
        var nsAppearance: NSAppearance? {
            switch self {
            case .system: return nil
            case .light:  return NSAppearance(named: .aqua)
            case .dark:   return NSAppearance(named: .darkAqua)
            }
        }
    }

    static let shared = AppearanceSettings()

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance)
            apply()
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Keys.appearance)
        self.appearance = stored.flatMap(Appearance.init(rawValue:)) ?? .system
    }

    /// Push the current preference onto `NSApplication`. Setting
    /// `NSApp.appearance` to nil means "follow the system", which is
    /// also the macOS default — so this is safe to call at every launch.
    func apply() {
        NSApp.appearance = appearance.nsAppearance
    }

    private enum Keys {
        static let appearance = "AppearanceSettings.appearance"
    }
}
