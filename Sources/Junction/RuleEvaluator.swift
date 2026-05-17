import Foundation

/// Evaluates a URL against a list of rules, in order, and returns the
/// first match. Stateless and pure — easy to unit-test once we have a test
/// target.
struct RuleEvaluator {

    /// Returns the rule that matched, or `nil` if no enabled rule matches.
    static func evaluate(_ url: URL, against rules: [Rule]) -> Rule? {
        for rule in rules where rule.enabled {
            if matches(url, rule.match) {
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
        }
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
