import Foundation

/// Evaluates a URL against a list of rules, in order, and returns the
/// first match. Stateless and pure — easy to unit-test once we have a test
/// target.
struct RuleEvaluator {

    /// Returns the rule that matched, or `nil` if no enabled rule matches.
    ///
    /// Convenience overload for callers that don't track the opener app —
    /// equivalent to "the link came from an unknown source".
    static func evaluate(_ url: URL, against rules: [Rule]) -> Rule? {
        evaluate(url, sourceApp: nil, against: rules)
    }

    /// Returns the first enabled rule whose URL matcher **and** source-app
    /// condition both pass, or `nil` if none match.
    ///
    /// - Parameter sourceApp: bundle ID of the app the URL was opened from,
    ///   or `nil` if unknown. A rule with an empty `sourceApps` matches
    ///   any source; a rule with non-empty `sourceApps` only matches when
    ///   `sourceApp` is one of them.
    static func evaluate(_ url: URL, sourceApp: String?, against rules: [Rule]) -> Rule? {
        for rule in rules where rule.enabled {
            if matches(url, rule.match), sourceMatches(rule.sourceApps, sourceApp) {
                return rule
            }
        }
        return nil
    }

    // MARK: - Matchers

    static func matches(_ url: URL, _ matcher: Matcher) -> Bool {
        switch matcher {
        case .host(let pattern):
            return hostMatches(url.host, pattern: pattern)
        case .hostRegex(let pattern):
            return hostMatchesRegex(url.host, pattern: pattern)
        case .urlContains(let substring):
            return url.absoluteString.range(of: substring, options: .caseInsensitive) != nil
        case .urlPrefix(let prefix):
            // Case-insensitive prefix match on the full URL string. Lower-
            // case both sides; `hasPrefix` doesn't have a case-insensitive
            // variant on String. Anchored to the start — won't false-
            // match URLs that mention the prefix mid-string.
            return url.absoluteString.lowercased().hasPrefix(prefix.lowercased())
        case .any:
            return true
        }
    }

    /// A rule's source-app condition. An empty `ruleSourceApps` means
    /// "any source" and always passes. Otherwise `actual` must be one of
    /// the listed bundle IDs (logical OR — links from any of these apps
    /// route through this rule).
    static func sourceMatches(_ ruleSourceApps: [String], _ actual: String?) -> Bool {
        guard !ruleSourceApps.isEmpty else { return true }
        guard let actual else { return false }
        return ruleSourceApps.contains(actual)
    }

    /// `pattern` matches `host` exactly OR is a parent domain of `host`.
    /// Examples with `pattern = "github.com"`:
    ///
    /// - `github.com`        → ✓
    /// - `api.github.com`    → ✓
    /// - `notgithub.com`     → ✗
    /// - `github.com.evil`   → ✗ (must be a parent, not a prefix)
    private static func hostMatches(_ host: String?, pattern: String) -> Bool {
        guard let host = host?.lowercased(), !host.isEmpty else { return false }
        let pattern = pattern.lowercased()
        if host == pattern { return true }
        if host.hasSuffix("." + pattern) { return true }
        return false
    }

    private static func hostMatchesRegex(_ host: String?, pattern: String) -> Bool {
        guard
            let host = host,
            !host.isEmpty,
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        else { return false }
        let range = NSRange(host.startIndex..<host.endIndex, in: host)
        return regex.firstMatch(in: host, options: [], range: range) != nil
    }
}
