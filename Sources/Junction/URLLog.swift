import Foundation
import Combine

/// Observable log of URLs Junction has received, persisted across
/// launches as append-style JSONL.
///
/// Singleton: the URL-receiving code paths (`AppDelegate`, Apple Event
/// handlers) live outside the SwiftUI view graph, so we need a globally
/// addressable instance they can post to. `@MainActor` ensures all
/// publishing happens on the main thread, which SwiftUI requires.
///
/// Persistence: the whole (capped) entries array is written to
/// `~/Library/Application Support/Junction/activity.jsonl` on every
/// change. Entries get *updated* after they're appended (routing
/// resolves asynchronously), so a strict append-only file would carry
/// stale rows — rewriting the small file each time keeps it correct.
/// Capped at `maxEntries`; oldest dropped first.
@MainActor
final class URLLog: ObservableObject {

    /// Where the URL came from — useful to verify both code paths fire.
    enum Source: String, Codable {
        case openURLs    = "openURL"      // NSApplicationDelegate.application(_:open:)
        case appleEvent  = "AppleEvent"   // kAEGetURL handler
    }

    /// Why a URL ended up where it did. Helps debug "why did this go to
    /// Chrome silently?" — was it a rule match, did I click in the picker,
    /// or did Junction hand it off to a native app?
    enum RouteReason: Equatable, Codable {
        case picker
        case rule(name: String)
        case handoff(name: String)
    }

    /// Outcome of attempting to route a received URL to a browser.
    /// Each entry starts `.pending`; the `Router` updates it asynchronously
    /// once the open call resolves (or the user dismisses the picker).
    enum Routing: Equatable, Codable {
        case pending
        case routed(to: String, via: RouteReason)
        case failed(reason: String)
        case unsupported
        case cancelled
    }

    struct Entry: Identifiable, Equatable, Codable {
        var id = UUID()
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
        /// Bundle ID of the browser this URL was routed to (the
        /// `Routing` enum only carries the display name, which isn't
        /// enough to build a rule from). Lets the Activity tab's
        /// "Create rule" action prefill the target precisely. Optional
        /// + decoded-if-present, so older `activity.jsonl` files load.
        var routedBundleID: String?
    }

    static let shared = URLLog()

    /// Hard cap on retained entries. The Activity tab is a recent-history
    /// view, not an archive — 1000 rows is plenty and keeps the file
    /// small (a few hundred KB).
    private static let maxEntries = 1000

    @Published private(set) var entries: [Entry] = []

    private init() {
        loadFromDisk()
    }

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
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
        persist()
        return entry.id
    }

    /// Mutate the routing field of an existing entry, optionally also
    /// recording the target browser's profile. No-op if the id is
    /// unknown (e.g., the entry was cleared between receipt and routing).
    func updateRouting(
        for id: UUID,
        to routing: Routing,
        profile: String? = nil,
        bundleID: String? = nil
    ) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].routing = routing
        entries[idx].routedProfile = profile
        entries[idx].routedBundleID = bundleID
        persist()
    }

    /// Record the post-rewrite URL and the list of params we removed.
    /// Called only when the rewriter actually changed the URL.
    func updateRewritten(for id: UUID, to rewritten: URL, strippedParams: [String] = []) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].rewritten = rewritten
        entries[idx].strippedParams = strippedParams
        persist()
    }

    func clear() {
        entries.removeAll()
        persist()
    }

    /// Current log as JSONL text — used by the Activity tab's Export
    /// button. One JSON object per line, oldest first.
    func exportJSONL() -> String {
        Self.encodeLines(entries)
    }

    // MARK: - Persistence

    private static let ioQueue = DispatchQueue(label: "com.pkajaba.junction.activitylog")

    private static var fileURL: URL? {
        guard let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return nil }
        return base.appendingPathComponent("Junction/activity.jsonl")
    }

    // `nonisolated` — pure encoding, safe to run on the IO queue. Without
    // this it inherits `URLLog`'s @MainActor isolation and the off-main
    // `persist()` write would hop back to the main thread.
    nonisolated private static func encodeLines(_ entries: [Entry]) -> String {
        let encoder = JSONEncoder()
        return entries.compactMap { entry -> String? in
            guard let data = try? encoder.encode(entry) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        .joined(separator: "\n")
    }

    private func loadFromDisk() {
        guard let url = Self.fileURL,
              let text = try? String(contentsOf: url, encoding: .utf8),
              !text.isEmpty
        else { return }
        let decoder = JSONDecoder()
        let decoded = text.split(separator: "\n").compactMap { line -> Entry? in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(Entry.self, from: data)
        }
        entries = Array(decoded.suffix(Self.maxEntries))
    }

    /// Snapshot the (value-type) array on the main actor, then write it
    /// off-main on a serial queue so file IO never blocks the UI and
    /// writes stay ordered.
    private func persist() {
        guard let url = Self.fileURL else { return }
        let snapshot = entries
        Self.ioQueue.async {
            let dir = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true
            )
            let text = Self.encodeLines(snapshot)
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
