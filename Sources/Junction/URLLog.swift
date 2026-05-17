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

    struct Entry: Identifiable, Equatable {
        let id = UUID()
        let url: URL
        let source: Source
        let receivedAt: Date
    }

    static let shared = URLLog()

    @Published private(set) var entries: [Entry] = []

    private init() {}

    func append(_ url: URL, source: Source) {
        entries.append(Entry(url: url, source: source, receivedAt: Date()))
    }

    func clear() {
        entries.removeAll()
    }
}
