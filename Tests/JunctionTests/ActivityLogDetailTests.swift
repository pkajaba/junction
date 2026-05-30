import XCTest
@testable import Junction

/// Covers the Activity-log detail levels: what each stores, that lower
/// levels strip path/query tokens, and that `URLLog.applyDetail()` scrubs
/// existing entries when the level is dialed up.
@MainActor
final class ActivityLogDetailTests: XCTestCase {

    private typealias Detail = ActivityLogSettings.LogDetail

    // MARK: - storedURL per level

    func test_full_redactsSecretsButKeepsPathAndQuery() {
        let out = Detail.full.storedURL(
            for: URL(string: "https://site.com/reset?token=SECRET&page=2")!
        )!.absoluteString
        XCTAssertTrue(out.contains("site.com/reset"))
        XCTAssertTrue(out.contains("token=REDACTED"))
        XCTAssertFalse(out.contains("SECRET"))
        XCTAssertTrue(out.contains("page=2"))
    }

    func test_hostPath_dropsQueryKeepsPath() {
        let out = Detail.hostPath.storedURL(
            for: URL(string: "https://site.com/a/b?token=SECRET")!
        )!.absoluteString
        XCTAssertEqual(out, "https://site.com/a/b")
        XCTAssertFalse(out.contains("SECRET"))
    }

    func test_hostOnly_dropsPathAndQuery() {
        let out = Detail.hostOnly.storedURL(
            for: URL(string: "https://site.com/reset/TOKEN123?x=1")!
        )!.absoluteString
        XCTAssertEqual(out, "https://site.com")
        XCTAssertFalse(out.contains("TOKEN123"))
    }

    func test_hostOnly_dropsEmbeddedCredentials() {
        let out = Detail.hostOnly.storedURL(
            for: URL(string: "https://alice:hunter2@site.com/x")!
        )!.absoluteString
        XCTAssertFalse(out.contains("hunter2"))
        XCTAssertFalse(out.contains("alice"))
        XCTAssertEqual(out, "https://site.com")
    }

    func test_off_returnsNil() {
        XCTAssertNil(Detail.off.storedURL(for: URL(string: "https://site.com/x")!))
    }

    // MARK: - applyDetail scrubs existing entries

    func test_applyDetail_hostOnly_scrubsExistingPathsAndClearsOnOff() {
        let log = URLLog.shared
        let settings = ActivityLogSettings.shared
        let originalDetail = settings.detail
        defer { settings.detail = originalDetail; log.clear() }

        settings.detail = .full
        log.clear()
        log.append(URL(string: "https://site.com/reset/TOKEN?x=1")!, source: .openURLs)
        XCTAssertTrue(log.entries.first?.url.absoluteString.contains("TOKEN") ?? false)

        // Dial up to host-only: existing path/query must be scrubbed in place.
        settings.detail = .hostOnly
        XCTAssertEqual(log.entries.first?.url.absoluteString, "https://site.com")

        // Off: the log is cleared entirely.
        settings.detail = .off
        XCTAssertTrue(log.entries.isEmpty)
    }
}
