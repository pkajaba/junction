import Foundation

/// Pure-function pipeline for cleaning up URLs before routing.
///
/// Currently only does tracking-parameter stripping. Future stages
/// (shortener expansion, custom regex rewrites) plug in here without
/// changing the call site in `Router`.
///
/// Designed to be a value transform — given the same input and settings,
/// always produces the same output. No I/O, no network.
struct URLRewriter {

    /// Apply all enabled rewrites to `url`. Returns the cleaned URL.
    /// If no rewrite changed anything, returns `url` unchanged (identity).
    ///
    /// `@MainActor` because `RewriterSettings` is main-actor-isolated;
    /// the rewriting itself is pure but reading the settings isn't.
    @MainActor
    static func rewrite(_ url: URL, settings: RewriterSettings) -> URL {
        var rewritten = url

        if settings.stripTrackingParams {
            rewritten = stripQueryParams(rewritten, params: settings.trackingParams)
        }

        return rewritten
    }

    /// Remove query parameters whose names appear in `params` (case-insensitive).
    /// Preserves parameter order for surviving params. Drops the `?` entirely
    /// if the result has no remaining params.
    static func stripQueryParams(_ url: URL, params: Set<String>) -> URL {
        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let items = components.queryItems,
            !items.isEmpty
        else { return url }

        let lower = Set(params.map { $0.lowercased() })
        let filtered = items.filter { item in
            !lower.contains(item.name.lowercased())
        }

        // No change → return original (preserves URL formatting nuances).
        if filtered.count == items.count { return url }

        components.queryItems = filtered.isEmpty ? nil : filtered
        return components.url ?? url
    }
}
