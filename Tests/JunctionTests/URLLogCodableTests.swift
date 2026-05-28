import XCTest
@testable import Junction

/// Locks the JSONL persistence shape for the Activity log. If these
/// break, existing `activity.jsonl` files won't decode after an update.
@MainActor
final class URLLogCodableTests: XCTestCase {

    func test_entry_routedViaRule_roundTrips() throws {
        let entry = makeEntry(
            routing: .routed(to: "Chrome", via: .rule(name: "github → work")),
            profile: "Work"
        )
        try assertRoundTrip(entry)
    }

    func test_entry_pickerManual_roundTrips() throws {
        try assertRoundTrip(makeEntry(routing: .routed(to: "Safari", via: .picker)))
    }

    func test_entry_handoff_roundTrips() throws {
        try assertRoundTrip(makeEntry(routing: .routed(to: "Zoom", via: .handoff(name: "Zoom"))))
    }

    func test_entry_unsupported_roundTrips() throws {
        try assertRoundTrip(makeEntry(routing: .unsupported))
    }

    func test_entry_withStrippedParamsAndSourceApp_roundTrips() throws {
        var entry = makeEntry(routing: .pending)
        entry.rewritten = URL(string: "https://example.com/")!
        entry.strippedParams = ["utm_source", "fbclid"]
        try assertRoundTrip(entry)
    }

    // MARK: - Helpers

    private func makeEntry(
        routing: URLLog.Routing,
        profile: String? = nil
    ) -> URLLog.Entry {
        URLLog.Entry(
            url: URL(string: "https://example.com/path?x=1")!,
            source: .openURLs,
            sourceApp: "com.tinyspeck.slackmacgap",
            receivedAt: Date(timeIntervalSince1970: 1_700_000_000),
            routing: routing,
            routedProfile: profile
        )
    }

    private func assertRoundTrip(_ entry: URLLog.Entry, file: StaticString = #filePath, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(URLLog.Entry.self, from: data)
        XCTAssertEqual(entry, decoded, file: file, line: line)
    }
}
