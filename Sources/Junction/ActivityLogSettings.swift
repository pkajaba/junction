import Foundation
import Combine

/// How long the Activity log keeps entries before they age out.
///
/// Backed by `UserDefaults`. `URLLog` reads `retention.maxAge` on load and
/// on every append; the Advanced settings tab observes + edits it. The
/// 1000-entry count cap always applies on top of this — the window only
/// adds *time*-based expiry so old plaintext browsing history doesn't
/// linger on a low-traffic machine that never hits the cap.
@MainActor
final class ActivityLogSettings: ObservableObject {

    enum Retention: String, CaseIterable, Identifiable {
        case days7
        case days30
        case days90
        case forever

        var id: String { rawValue }

        var label: String {
            switch self {
            case .days7:   return "7 days"
            case .days30:  return "30 days"
            case .days90:  return "90 days"
            case .forever: return "Forever"
            }
        }

        /// Maximum age of a retained entry. `.forever` maps to ~100 years —
        /// effectively no time limit, but a finite value so date arithmetic
        /// in `URLLog.retained` can't overflow.
        var maxAge: TimeInterval {
            let day: TimeInterval = 24 * 60 * 60
            switch self {
            case .days7:   return 7 * day
            case .days30:  return 30 * day
            case .days90:  return 90 * day
            case .forever: return 100 * 365 * day
            }
        }
    }

    static let shared = ActivityLogSettings()

    @Published var retention: Retention {
        didSet {
            UserDefaults.standard.set(retention.rawValue, forKey: Keys.retention)
            // Re-trim immediately so shrinking the window takes effect now,
            // not just on the next received URL.
            URLLog.shared.applyRetention()
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Keys.retention)
        self.retention = stored.flatMap(Retention.init(rawValue:)) ?? .days90
    }

    private enum Keys {
        static let retention = "ActivityLogSettings.retention"
    }
}
