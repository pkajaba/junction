import Foundation
import Combine

/// In-memory, observable log of URLs Junction has received since launch.
///
/// Singleton: the URL-receiving code paths (`AppDelegate`, Apple Event
/// handlers) live outside the SwiftUI view graph, so we need a globally
/// addressable instance they can post to. `@MainActor` ensures all
/// publishing happens on the main thread, which SwiftUI requires.
@MainActor
final class URLLog: ObservableObject {

    /// Where the URL came from — useful to verify both code paths fire.
    /// (We'll drop this once we're past the M1 plumbing-check phase.)
    enum Source: String {
        case openURLs    = "openURL"      // NSApplicationDelegate.application(_:open:)
        case appleEvent  = "AppleEvent"   // kAEGetURL handler
    }

    /// Why a URL ended up where it did. Helps debug "why did this go to
    /// Chrome silently?" — was it a rule match, did I click in the picker,
    /// or did Junction hand it off to a native app?
    enum RouteReason: Equatable {
        case picker
        case rule(name: String)
        case handoff(name: String)
    }

    /// Outcome of attempting to route a received URL to a browser.
    /// Each entry starts `.pending`; the `Router` updates it asynchronously
    /// once the open call resolves (or the user dismisses the picker).
    enum Routing: Equatable {
        case pending
        case routed(to: String, via: RouteReason)
        case failed(reason: String)
        case unsupported
        case cancelled
    }

    struct Entry: Identifiable, Equatable {
        let id = UUID()
        /// URL as received from macOS, before any rewriting.
        let url: URL
        /// URL after `URLRewriter` ran, if it changed anything. The rule
        /// engine and the open call both use this when present.
        var rewritten: URL?
        /// Query-parameter names the rewriter removed, in original order.
        /// Powers the Activity tab's `· cleaned (utm_source stripped)`
        /// callout — surfaces what Junction did to the URL.
        var strippedParams: [String] = []
        let source: Source
        /// Bundle ID of the app the link was opened from, when known
        /// (`NSWorkspace.shared.frontmostApplication` at receive time).
        /// Empty for legacy entries and for openers Junction couldn't
        /// identify. Drives `from <App>` in the Activity row subline.
        let sourceApp: String?
        let receivedAt: Date
        var routing: Routing = .pending
        /// Profile of the target browser at the moment of routing, if
        /// any. Stored separately from `Routing` so we can show
        /// `Chrome · Work` in the outcome block without bloating the
        /// `Routing` enum's associated values.
        var routedProfile: String?
    }

    static let shared = URLLog()

    @Published private(set) var entries: [Entry] = []

    private init() {}

    /// Append a freshly received URL. Returns the entry's id so the caller
    /// (typically the `Router`) can update its routing status later.
    ///
    /// `sourceApp` is the opener's bundle ID, recorded eagerly at append
    /// time because `NSWorkspace.frontmostApplication` is only reliable
    /// the instant the URL arrives — by the time the router decides
    /// where to send it, focus may have shifted.
    @discardableResult
    func append(_ url: URL, source: Source, sourceApp: String? = nil) -> UUID {
        let entry = Entry(url: url, source: source, sourceApp: sourceApp, receivedAt: Date())
        entries.append(entry)
        return entry.id
    }

    /// Mutate the routing field of an existing entry, optionally also
    /// recording the target browser's profile. No-op if the id is
    /// unknown (e.g., the entry was cleared between receipt and routing).
    func updateRouting(for id: UUID, to routing: Routing, profile: String? = nil) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].routing = routing
        entries[idx].routedProfile = profile
    }

    /// Record the post-rewrite URL and the list of params we removed.
    /// Called only when the rewriter actually changed the URL.
    func updateRewritten(for id: UUID, to rewritten: URL, strippedParams: [String] = []) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].rewritten = rewritten
        entries[idx].strippedParams = strippedParams
    }

    func clear() {
        entries.removeAll()
    }
}
