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

    /// How much of each URL the Activity log stores. Lower levels drop more
    /// of the URL *before* it's written, so secrets carried outside the
    /// query string (e.g. a reset token in the path) never hit disk.
    enum LogDetail: String, CaseIterable, Identifiable {
        /// Full URL — host, path, and query. Secret query/fragment params
        /// and embedded credentials are still redacted (`SensitiveURLRedactor`).
        case full
        /// Host + path, query dropped. Kills query-string tokens; a token
        /// in the *path* still survives (that's the trade-off for keeping
        /// path-based rules legible).
        case hostPath
        /// Host only — path and query both dropped. No URL token can ever
        /// be stored.
        case hostOnly
        /// Don't record activity at all. Links still route; nothing is logged.
        case off

        var id: String { rawValue }

        var label: String {
            switch self {
            case .full:     return "Full URL"
            case .hostPath: return "Host + path"
            case .hostOnly: return "Host only"
            case .off:      return "Off"
            }
        }

        /// One-line description of what this level stores, for the caption.
        var caption: String {
            switch self {
            case .full:     return "Stores host, path, and query (secret params redacted)."
            case .hostPath: return "Stores host and path; drops the query string."
            case .hostOnly: return "Stores only the host — no path or query, so no URL tokens."
            case .off:      return "Records nothing. The Activity tab stays empty."
            }
        }

        /// The URL to actually store at this level, or `nil` for `.off`
        /// (meaning: don't store the entry). Pure — unit-testable without
        /// touching `URLLog` or disk.
        func storedURL(for url: URL) -> URL? {
            switch self {
            case .off:
                return nil
            case .full:
                return SensitiveURLRedactor.redact(url)
            case .hostPath:
                return Self.reduce(url, keepPath: true)
            case .hostOnly:
                return Self.reduce(url, keepPath: false)
            }
        }

        /// Rebuild `url` keeping only scheme + host (+ path if `keepPath`),
        /// dropping query, fragment, and any embedded credentials. Falls
        /// back to the original if it can't be reconstructed (e.g. no host).
        private static func reduce(_ url: URL, keepPath: Bool) -> URL {
            var components = URLComponents()
            components.scheme = url.scheme
            components.host = url.host
            if keepPath { components.path = url.path }
            return components.url ?? url
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

    @Published var detail: LogDetail {
        didSet {
            UserDefaults.standard.set(detail.rawValue, forKey: Keys.detail)
            // Re-scrub existing entries to the new (possibly stricter) level
            // immediately, so dialing privacy up purges history now.
            URLLog.shared.applyDetail()
        }
    }

    private init() {
        let storedRetention = UserDefaults.standard.string(forKey: Keys.retention)
        self.retention = storedRetention.flatMap(Retention.init(rawValue:)) ?? .days90
        let storedDetail = UserDefaults.standard.string(forKey: Keys.detail)
        self.detail = storedDetail.flatMap(LogDetail.init(rawValue:)) ?? .full
    }

    private enum Keys {
        static let retention = "ActivityLogSettings.retention"
        static let detail = "ActivityLogSettings.detail"
    }
}
