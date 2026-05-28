import Foundation

/// Scrubs secret-bearing query-parameter **values** out of a URL before it
/// is recorded in the Activity log — and therefore before it's written to
/// `activity.jsonl` or handed to the Export button.
///
/// Links routinely carry credentials in the query string: Zoom `pwd=`,
/// OAuth `code`/`token`, password-reset tokens, signed-URL signatures,
/// API keys. The Activity log only needs the host and path to be useful;
/// the secret values are noise at best and a leak at worst, because the
/// file can be backed up, synced, or exported and shared.
///
/// The transform is pure. It keeps the parameter *name* (`pwd=REDACTED`)
/// so the log still shows that a credential was present, and never touches
/// the scheme, host, or path — so host-keyed logic (rule suggestions,
/// display, dedup) is unaffected.
enum SensitiveURLRedactor {

    /// Replacement value written in place of a secret.
    static let marker = "REDACTED"

    /// Query-param names (matched case-insensitively) whose values are
    /// scrubbed. Deliberately broad: over-redacting a value in a local log
    /// is harmless, under-redacting leaks a credential.
    static let sensitiveKeys: Set<String> = [
        "password", "passwd", "pwd", "pass",
        "token", "access_token", "refresh_token", "id_token",
        "auth", "authorization", "bearer",
        "secret", "client_secret",
        "api_key", "apikey", "key",
        "code", "code_verifier",
        "session", "sessionid", "sid",
        "otp", "state",
        "signature", "sig",
    ]

    /// Return a copy of `url` with the values of any sensitive query
    /// parameters replaced by `marker`. URLs with no query string (or that
    /// can't be parsed) are returned unchanged.
    static func redact(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty
        else { return url }

        var didRedact = false
        let scrubbed = items.map { item -> URLQueryItem in
            // Only redact params that actually carry a value — `?token` with
            // no `=` has nothing to leak.
            if item.value != nil, sensitiveKeys.contains(item.name.lowercased()) {
                didRedact = true
                return URLQueryItem(name: item.name, value: marker)
            }
            return item
        }

        guard didRedact else { return url }
        components.queryItems = scrubbed
        return components.url ?? url
    }
}
