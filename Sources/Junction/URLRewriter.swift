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

    /// Output of the rewriter pipeline: the cleaned URL plus the list of
    /// query-parameter names that were removed. Callers that just need
    /// the URL can read `.url`; the Activity tab uses `.stripped` for
    /// its `· cleaned (utm_source stripped)` callout.
    struct Result: Equatable {
        let url: URL
        let stripped: [String]
        var changed: Bool { !stripped.isEmpty }
    }

    /// Apply all enabled rewrites to `url`. Returns the cleaned URL plus
    /// the list of stripped params. If nothing changed, `result.url ==
    /// url` and `result.stripped` is empty.
    ///
    /// `@MainActor` because `RewriterSettings` is main-actor-isolated;
    /// the rewriting itself is pure but reading the settings isn't.
    @MainActor
    static func rewrite(_ url: URL, settings: RewriterSettings) -> Result {
        var current = url
        var stripped: [String] = []

        if settings.stripTrackingParams {
            let (newURL, removed) = stripQueryParamsTracking(current, params: settings.trackingParams)
            current = newURL
            stripped.append(contentsOf: removed)
        }

        return Result(url: current, stripped: stripped)
    }

    /// Backward-compat wrapper that returns only the cleaned URL. New
    /// call sites should use `rewrite(_:settings:)` and read the full
    /// result so they can surface the stripped params.
    @MainActor
    static func rewriteURL(_ url: URL, settings: RewriterSettings) -> URL {
        rewrite(url, settings: settings).url
    }

    /// Remove query parameters whose names appear in `params` (case-insensitive).
    /// Preserves parameter order for surviving params. Drops the `?` entirely
    /// if the result has no remaining params. The single-value variant
    /// kept for test code; production now uses `stripQueryParamsTracking`
    /// which also returns which params it removed.
    static func stripQueryParams(_ url: URL, params: Set<String>) -> URL {
        stripQueryParamsTracking(url, params: params).url
    }

    /// Same as `stripQueryParams` but reports which params it removed.
    /// Returning both the URL and the list of stripped names lets the
    /// Activity log show *exactly* what Junction did to the URL.
    static func stripQueryParamsTracking(
        _ url: URL,
        params: Set<String>
    ) -> (url: URL, stripped: [String]) {
        guard
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let items = components.queryItems,
            !items.isEmpty
        else { return (url, []) }

        let lower = Set(params.map { $0.lowercased() })
        var kept: [URLQueryItem] = []
        var stripped: [String] = []
        for item in items {
            if lower.contains(item.name.lowercased()) {
                stripped.append(item.name)
            } else {
                kept.append(item)
            }
        }

        // No change → return original (preserves URL formatting nuances).
        if stripped.isEmpty { return (url, []) }

        components.queryItems = kept.isEmpty ? nil : kept
        return (components.url ?? url, stripped)
    }
}
