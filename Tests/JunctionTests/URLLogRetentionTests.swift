import XCTest
@testable import Junction

/// Covers the Activity log's time-based + count-based retention
/// (`URLLog.retained`), the pure helper behind load- and append-time
/// trimming.
@MainActor
final class URLLogRetentionTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let maxAge: TimeInterval = 90 * 24 * 60 * 60

    private func entry(agoDays: Int) -> URLLog.Entry {
        URLLog.Entry(
            url: URL(string: "https://example.com/\(agoDays)")!,
            source: .openURLs,
            sourceApp: nil,
            receivedAt: now.addingTimeInterval(-Double(agoDays) * 86_400)
        )
    }

    func test_dropsEntriesOlderThanMaxAge() {
        let entries = [entry(agoDays: 1), entry(agoDays: 89), entry(agoDays: 91)]
        let kept = URLLog.retained(entries, now: now, maxAge: maxAge, maxEntries: 1000)
        XCTAssertEqual(kept.count, 2)
        XCTAssertFalse(kept.contains { $0.url.absoluteString.hasSuffix("/91") })
    }

    func test_capsToMaxEntriesKeepingNewest() {
        let entries = (0..<5).map { entry(agoDays: $0) }
        let kept = URLLog.retained(entries, now: now, maxAge: maxAge, maxEntries: 3)
        XCTAssertEqual(kept, Array(entries.suffix(3)))
    }

    func test_appliesBothBounds() {
        var entries = (0..<4).map { entry(agoDays: $0) }   // all recent
        entries.append(entry(agoDays: 200))                // expired, appended last
        let kept = URLLog.retained(entries, now: now, maxAge: maxAge, maxEntries: 2)
        XCTAssertEqual(kept.count, 2)
        let cutoff = now.addingTimeInterval(-maxAge)
        XCTAssertTrue(kept.allSatisfy { $0.receivedAt >= cutoff })
    }

    func test_emptyInputStaysEmpty() {
        XCTAssertTrue(URLLog.retained([], now: now, maxAge: maxAge, maxEntries: 1000).isEmpty)
    }
}
