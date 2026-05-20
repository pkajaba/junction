import Foundation

/// Bidirectional conversion between a rule's `Matcher` and a UI-friendly
/// list of host chips + an "include subdomains" toggle.
///
/// The chip list is a **projection** of the underlying matcher — the
/// chips don't add new persistent state. If the user has a rule whose
/// matcher is too complex to express as chips (e.g. a raw `urlContains`
/// or a regex that doesn't follow our host-list shape), `chips(from:)`
/// returns `nil` and the editor falls back to a raw-regex view (which
/// Phase C v1 doesn't implement; the editor just shows an explanatory
/// stub for those rules).
enum HostChipMatcher {

    /// The chip representation of a matcher.
    struct Chips: Equatable {
        var hosts: [String]
        var includeSubdomains: Bool
    }

    /// Try to read a matcher as a chip list. Returns nil for matchers
    /// that don't have a clean host-list interpretation.
    static func chips(from match: Matcher) -> Chips? {
        switch match {
        case .host(let host):
            // Our `host` matcher does parent-domain matching natively,
            // so single host == includeSubdomains true.
            return Chips(hosts: [host], includeSubdomains: true)
        case .hostRegex(let regex):
            return parseHostListRegex(regex)
        case .urlContains:
            return nil
        }
    }

    /// Build a matcher from a chip list. Picks the most efficient
    /// representation: a single host with subdomains becomes `.host`,
    /// everything else becomes a `.hostRegex`.
    static func matcher(from chips: Chips) -> Matcher {
        let hosts = chips.hosts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !hosts.isEmpty else {
            // Empty chip list — fall back to a regex that matches nothing.
            // The editor's validation should keep this from being saved.
            return .hostRegex("$.^")
        }

        if hosts.count == 1, chips.includeSubdomains {
            // Cheapest representation: single host with parent-domain semantics.
            return .host(hosts[0])
        }

        let alternation = hosts.map(escapeHost).joined(separator: "|")

        if chips.includeSubdomains {
            return .hostRegex("(^|\\.)(\(alternation))$")
        } else {
            return .hostRegex("^(\(alternation))$")
        }
    }

    /// Returns true if the given host string looks like a valid hostname.
    /// Conservative — letters, digits, dots, hyphens, must contain at
    /// least one dot.
    static func isValidHost(_ s: String) -> Bool {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.contains(".") else { return false }
        let allowed: Set<Character> = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
        return trimmed.allSatisfy { allowed.contains($0) }
    }

    // MARK: - Internals

    private static func escapeHost(_ host: String) -> String {
        // Hosts can only contain letters/digits/dots/hyphens. Only `.`
        // and `-` are regex-special in this character set, and only `.`
        // actually matters (`-` is literal outside character classes).
        host.replacingOccurrences(of: ".", with: "\\.")
    }

    private static func parseHostListRegex(_ regex: String) -> Chips? {
        // Patterns we generated ourselves:
        //   (^|\.)(host1|host2|...)$   → includeSubdomains = true,  N hosts
        //   ^(host1|host2|...)$         → includeSubdomains = false, N hosts
        //   ^host$                       → includeSubdomains = false, 1 host

        if let inner = match(regex, prefix: "(^|\\.)(", suffix: ")$") {
            return chipsFromAlternation(inner, includeSubdomains: true)
        }
        if let inner = match(regex, prefix: "^(", suffix: ")$") {
            return chipsFromAlternation(inner, includeSubdomains: false)
        }
        if let inner = match(regex, prefix: "^", suffix: "$") {
            let unescaped = inner.replacingOccurrences(of: "\\.", with: ".")
            if isValidHost(unescaped) {
                return Chips(hosts: [unescaped], includeSubdomains: false)
            }
        }
        return nil
    }

    /// If `s` starts with `prefix` and ends with `suffix`, return the
    /// portion in between. Otherwise nil.
    private static func match(_ s: String, prefix: String, suffix: String) -> String? {
        guard s.hasPrefix(prefix), s.hasSuffix(suffix),
              s.count >= prefix.count + suffix.count
        else { return nil }
        let start = s.index(s.startIndex, offsetBy: prefix.count)
        let end = s.index(s.endIndex, offsetBy: -suffix.count)
        return String(s[start..<end])
    }

    private static func chipsFromAlternation(_ alternation: String, includeSubdomains: Bool) -> Chips? {
        let parts = alternation.split(separator: "|").map(String.init)
        let hosts = parts.map { $0.replacingOccurrences(of: "\\.", with: ".") }
        // Reject if any "host" doesn't look like a host — that means the
        // regex contains operators we can't represent as chips.
        guard hosts.allSatisfy(isValidHost) else { return nil }
        return Chips(hosts: hosts, includeSubdomains: includeSubdomains)
    }
}
