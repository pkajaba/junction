import Foundation

/// Scrubs secret-bearing material out of a URL before it is recorded in the
/// Activity log — and therefore before it's written to `activity.jsonl` or
/// handed to the Export button.
///
/// Links routinely carry credentials, and not only in the query string:
/// - **Query params** — Zoom `pwd=`, OAuth `code`/`token`, reset tokens.
/// - **Fragment** — OAuth *implicit-flow* responses put `access_token=…`
///   after the `#`, which `URLComponents.queryItems` does **not** see.
/// - **Userinfo** — `https://user:password@host/…` embeds a password.
/// - **Signed-URL params** — `X-Amz-Signature`, `sig`, …
///
/// The Activity log only needs the host and path to be useful, so we redact
/// the rest. The transform is pure: it keeps each parameter *name*
/// (`pwd=REDACTED`) so the log still shows that a credential was present,
/// and never touches the scheme, host, or path — so host-keyed logic (rule
/// suggestions, display) is unaffected.
enum SensitiveURLRedactor {

    /// Replacement value written in place of a secret.
    static let marker = "REDACTED"

    /// Parameter names (matched case-insensitively, in query *and*
    /// fragment) whose values get scrubbed. Deliberately broad: over-
    /// redacting a value in a local log is harmless, under-redacting leaks
    /// a credential.
    static let sensitiveKeys: Set<String> = [
        "password", "passwd", "pwd", "pass",
        "token", "access_token", "refresh_token", "id_token",
        "auth", "auth_token", "authorization", "bearer", "oauth_token",
        "secret", "client_secret",
        "api_key", "apikey", "key",
        "code", "code_verifier",
        "session", "sessionid", "sid",
        "otp", "state",
        "signature", "sig",
        "x-amz-signature", "x-amz-security-token", "x-amz-credential",
        "x-goog-signature",
    ]

    /// Return a copy of `url` with secret query/fragment values and any
    /// embedded password replaced by `marker`. URLs with nothing sensitive
    /// (or that can't be parsed) are returned unchanged.
    static func redact(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var changed = false

        // 1. Query parameters.
        if let items = components.queryItems, !items.isEmpty {
            var didRedact = false
            let scrubbed = items.map { item -> URLQueryItem in
                // Only redact params that actually carry a value — `?token`
                // with no `=` has nothing to leak.
                if item.value != nil, isSensitive(item.name) {
                    didRedact = true
                    return URLQueryItem(name: item.name, value: marker)
                }
                return item
            }
            if didRedact {
                components.queryItems = scrubbed
                changed = true
            }
        }

        // 2. Fragment carrying `key=value` pairs (OAuth implicit flow).
        if let fragment = components.percentEncodedFragment,
           fragment.contains("="),
           let redactedFragment = redactPairs(fragment) {
            components.percentEncodedFragment = redactedFragment
            changed = true
        }

        // 3. Embedded credentials (`user:password@host`).
        if components.password != nil {
            components.password = marker
            changed = true
        }

        guard changed else { return url }
        return components.url ?? url
    }

    // MARK: - Internals

    private static func isSensitive(_ name: String) -> Bool {
        sensitiveKeys.contains(name.lowercased())
    }

    /// Redact sensitive values in an `a=1&b=2`-style string (used for the
    /// fragment). Returns the rebuilt string, or `nil` if nothing changed.
    /// Operates on the already-encoded form and only substitutes the plain
    /// `marker`, so it never double-encodes the surviving pairs.
    private static func redactPairs(_ encoded: String) -> String? {
        var changed = false
        let rebuilt = encoded
            .split(separator: "&", omittingEmptySubsequences: false)
            .map { pair -> String in
                guard let eq = pair.firstIndex(of: "=") else { return String(pair) }
                let name = String(pair[..<eq])
                guard isSensitive(name) else { return String(pair) }
                changed = true
                return "\(name)=\(marker)"
            }
            .joined(separator: "&")
        return changed ? rebuilt : nil
    }
}
