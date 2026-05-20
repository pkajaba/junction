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
        let source: Source
        let receivedAt: Date
        var routing: Routing = .pending
    }

    static let shared = URLLog()

    @Published private(set) var entries: [Entry] = []

    private init() {}

    /// Append a freshly received URL. Returns the entry's id so the caller
    /// (typically the `Router`) can update its routing status later.
    @discardableResult
    func append(_ url: URL, source: Source) -> UUID {
        let entry = Entry(url: url, source: source, receivedAt: Date())
        entries.append(entry)
        return entry.id
    }

    /// Mutate the routing field of an existing entry. No-op if the id is
    /// unknown (e.g., the entry was cleared between receipt and routing).
    func updateRouting(for id: UUID, to routing: Routing) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].routing = routing
    }

    /// Record the post-rewrite URL on an entry. Called only when the
    /// rewriter actually changed the URL.
    func updateRewritten(for id: UUID, to rewritten: URL) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].rewritten = rewritten
    }

    func clear() {
        entries.removeAll()
    }
}
