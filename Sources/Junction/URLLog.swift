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

    /// Outcome of attempting to route a received URL to a browser.
    /// Each entry starts `.pending`; the `Router` updates it asynchronously
    /// once the open call resolves.
    enum Routing: Equatable {
        case pending
        case routed(to: String)
        case failed(reason: String)
        case unsupported
    }

    struct Entry: Identifiable, Equatable {
        let id = UUID()
        let url: URL
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

    func clear() {
        entries.removeAll()
    }
}
