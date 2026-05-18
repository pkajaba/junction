import Foundation
import Combine

/// User-tunable settings for the URL rewriter.
///
/// Backed by `UserDefaults`. Reactive so the Advanced settings tab can
/// observe and edit it, and `Router` reads it on every URL.
@MainActor
final class RewriterSettings: ObservableObject {

    static let shared = RewriterSettings()

    @Published var stripTrackingParams: Bool {
        didSet { UserDefaults.standard.set(stripTrackingParams, forKey: Keys.stripTrackingParams) }
    }

    /// Names of query parameters to strip when `stripTrackingParams` is on.
    @Published var trackingParams: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(trackingParams).sorted(),
                                      forKey: Keys.trackingParams)
        }
    }

    private init() {
        let strip = UserDefaults.standard.object(forKey: Keys.stripTrackingParams) as? Bool ?? true
        self.stripTrackingParams = strip

        if let stored = UserDefaults.standard.stringArray(forKey: Keys.trackingParams),
           !stored.isEmpty {
            self.trackingParams = Set(stored)
        } else {
            self.trackingParams = Self.defaultTrackingParams
        }
    }

    /// Reset tracking params to the built-in default list.
    func resetTrackingParamsToDefaults() {
        trackingParams = Self.defaultTrackingParams
    }

    // MARK: - Defaults

    /// Common tracking parameters across major ad networks and marketing
    /// platforms. Conservative — only params that are virtually never
    /// load-bearing for page content.
    static let defaultTrackingParams: Set<String> = [
        // UTM (Google Analytics, widely adopted)
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "utm_id", "utm_name", "utm_brand", "utm_social",
        // Facebook
        "fbclid",
        // Google Ads / DoubleClick
        "gclid", "gclsrc", "dclid", "gbraid", "wbraid",
        // Microsoft / Bing
        "msclkid",
        // HubSpot
        "_hsenc", "_hsmi", "hsCtaTracking",
        // Mailchimp
        "mc_cid", "mc_eid",
        // Instagram
        "igshid",
        // Generic GA
        "_ga",
        // LinkedIn
        "li_fat_id",
        // TikTok
        "ttclid",
        // Twitter / X
        "twclid",
    ]

    private enum Keys {
        static let stripTrackingParams = "RewriterSettings.stripTrackingParams"
        static let trackingParams      = "RewriterSettings.trackingParams"
    }
}
