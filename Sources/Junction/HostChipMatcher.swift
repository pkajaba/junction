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
        case .urlPrefix(let prefix):
            // Strip the scheme so the chip reads `github.com/NBTSolutions`,
            // not `https://github.com/NBTSolutions`. Subdomains don't
            // expand for path-prefix chips — the prefix is literal.
            let stripped = stripScheme(prefix)
            return Chips(hosts: [stripped], includeSubdomains: false)
        case .urlContains:
            return nil
        case .any:
            // No host constraint — an empty chip list. Used by source-app
            // rules ("everything from Slack → Chrome").
            return Chips(hosts: [], includeSubdomains: true)
        }
    }

    /// Build a matcher from a chip list. Picks the most efficient
    /// representation:
    /// - empty → `.any`
    /// - single chip with a path (`github.com/NBT/`) → `.urlPrefix` so the
    ///   route only fires for URLs starting with that prefix
    /// - single host chip with subdomains → `.host`
    /// - multiple host chips → `.hostRegex` alternation
    ///
    /// Mixing path chips with host chips collapses to "use the first path
    /// chip's prefix" — combining a path-prefix with N more hosts in a
    /// single matcher isn't expressible cleanly; we treat that as a
    /// user-error pattern and the editor steers them toward one path
    /// chip per rule (split the rule if they need both).
    static func matcher(from chips: Chips) -> Matcher {
        let hosts = chips.hosts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !hosts.isEmpty else {
            // Empty chip list — no URL constraint. Becomes `.any`, which
            // is only meaningful when paired with a `sourceApps` condition;
            // the editor's validation rejects a rule with neither.
            return .any
        }

        if let pathChip = hosts.first(where: { hasPath($0) }) {
            // Path-prefix mode. We default to `https://` because every
            // routable URL Junction sees is http(s) and the prefix is
            // matched case-insensitively; an http link to the same path
            // will still match via `.urlPrefix` because the path tail is
            // identical (the scheme is fixed but the user can edit
            // rules.json to swap if they really want http only).
            return .urlPrefix("https://" + pathChip)
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

    /// True for chips that carry a path component (`github.com/NBT`).
    /// A chip is "host-only" if it has no slash; the chip add UI uses
    /// this to decide whether to disable "Include subdomains" and to
    /// warn that more chips aren't supported in path-prefix mode.
    static func hasPath(_ chip: String) -> Bool {
        chip.contains("/")
    }

    private static func stripScheme(_ s: String) -> String {
        guard let range = s.range(of: "://") else { return s }
        return String(s[range.upperBound...])
    }

    /// Caption text for the "Include subdomains" toggle, grounded in the
    /// user's actual hosts so it doesn't read like a copy-paste leftover.
    /// If the chip list has at least one host, the example uses *that*
    /// host (`— so app.vetro.io matches too`); empty list falls back to a
    /// generic illustration so the message still makes sense.
    static func subdomainHint(_ chips: Chips) -> String {
        let host = chips.hosts.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        return host.map { "— so app.\($0) matches too" }
            ?? "— so app.example.com matches example.com too"
    }

    /// Best-effort coercion from "whatever the user typed" to a chip
    /// value. The chip field accepts:
    /// - bare hosts (`github.com`)
    /// - full URLs with a non-trivial path
    ///   (`https://github.com/NBTSolutions/foo`) — in this case the chip
    ///   carries `host/path`, the matcher becomes `.urlPrefix`, and the
    ///   rule only fires for URLs starting with that prefix
    /// - full URLs whose path is just `/` or empty — equivalent to a
    ///   bare host, the path is dropped
    ///
    /// Returns nil for anything we can't extract a sensible chip from.
    static func normalizeChip(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // URL-shaped input — extract host and (optionally) path.
        if trimmed.contains("://") || trimmed.contains("/") {
            let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
            guard let components = URLComponents(string: candidate),
                  let host = components.host,
                  isValidHost(host)
            else { return nil }

            let path = components.path
            if !path.isEmpty && path != "/" {
                // Keep the query string off — query params usually carry
                // session info that shouldn't gate routing. Path is the
                // intent-bearing part.
                return host + path
            }
            return host
        }
        return isValidHost(trimmed) ? trimmed : nil
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
