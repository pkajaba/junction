import XCTest
@testable import Junction

/// Covers the Activity tab's "you keep doing this by hand" nudge: the
/// rolling 7-day per-(host, browser) tally, the ≥3 banner selection, and
/// the 7-day per-host dismissal memory.
@MainActor
final class ActivitySuggestionsTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Tally

    func test_tally_countsManualPicksPerHostBrowser() {
        let entries = [
            pick("https://figma.com/a", browser: "Chrome", agoDays: 0),
            pick("https://figma.com/b", browser: "Chrome", agoDays: 1),
            pick("https://figma.com/c", browser: "Chrome", agoDays: 2)
        ]
        let tally = ActivitySuggestions.tally(entries, now: now)
        XCTAssertEqual(tally[key("figma.com", "Chrome")]?.count, 3)
    }

    func test_tally_excludesPicksOlderThanWindow() {
        let entries = [
            pick("https://figma.com/a", browser: "Chrome", agoDays: 1),
            pick("https://figma.com/b", browser: "Chrome", agoDays: 8) // outside
        ]
        let tally = ActivitySuggestions.tally(entries, now: now)
        XCTAssertEqual(tally[key("figma.com", "Chrome")]?.count, 1)
    }

    func test_tally_separatesByBrowser() {
        let entries = [
            pick("https://figma.com/a", browser: "Chrome", agoDays: 0),
            pick("https://figma.com/b", browser: "Chrome", agoDays: 1),
            pick("https://figma.com/c", browser: "Safari", agoDays: 1)
        ]
        let tally = ActivitySuggestions.tally(entries, now: now)
        XCTAssertEqual(tally[key("figma.com", "Chrome")]?.count, 2)
        XCTAssertEqual(tally[key("figma.com", "Safari")]?.count, 1)
    }

    func test_tally_ignoresNonPickerRoutings() {
        let entries = [
            entry("https://figma.com/a", routing: .routed(to: "Chrome", via: .rule(name: "r")), agoDays: 0),
            entry("https://figma.com/b", routing: .routed(to: "Zoom", via: .handoff(name: "Zoom")), agoDays: 0),
            entry("https://figma.com/c", routing: .failed(reason: "x"), agoDays: 0),
            entry("https://figma.com/d", routing: .unsupported, agoDays: 0)
        ]
        XCTAssertTrue(ActivitySuggestions.tally(entries, now: now).isEmpty)
    }

    func test_tally_usesRewrittenHostWhenPresent() {
        var entry = pick("https://figma.com/a?utm_source=x", browser: "Chrome", agoDays: 0)
        entry.rewritten = URL(string: "https://clean.example.com/a")!
        let tally = ActivitySuggestions.tally([entry], now: now)
        XCTAssertNil(tally[key("figma.com", "Chrome")])
        XCTAssertEqual(tally[key("clean.example.com", "Chrome")]?.count, 1)
    }

    func test_tally_carriesMostRecentTarget() {
        var older = pick("https://figma.com/a", browser: "Chrome", agoDays: 3)
        older.routedProfile = "Personal"
        older.routedBundleID = "com.google.Chrome"
        var newer = pick("https://figma.com/b", browser: "Chrome", agoDays: 1)
        newer.routedProfile = "Work"
        newer.routedBundleID = "com.google.Chrome"
        let tally = ActivitySuggestions.tally([older, newer], now: now)
        let suggestion = tally[key("figma.com", "Chrome")]
        XCTAssertEqual(suggestion?.count, 2)
        XCTAssertEqual(suggestion?.profile, "Work")
        XCTAssertEqual(suggestion?.entryID, newer.id)
    }

    // MARK: - Banner

    func test_banner_nilBelowThree() {
        let entries = [
            pick("https://figma.com/a", browser: "Chrome", agoDays: 0),
            pick("https://figma.com/b", browser: "Chrome", agoDays: 1)
        ]
        XCTAssertNil(ActivitySuggestions.banner(from: entries, dismissedHosts: [], now: now))
    }

    func test_banner_appearsAtThree() {
        let entries = (0..<3).map { pick("https://figma.com/\($0)", browser: "Chrome", agoDays: $0) }
        let banner = ActivitySuggestions.banner(from: entries, dismissedHosts: [], now: now)
        XCTAssertEqual(banner?.host, "figma.com")
        XCTAssertEqual(banner?.browser, "Chrome")
        XCTAssertEqual(banner?.count, 3)
    }

    func test_banner_suppressedWhenHostDismissed() {
        let entries = (0..<3).map { pick("https://figma.com/\($0)", browser: "Chrome", agoDays: $0) }
        XCTAssertNil(
            ActivitySuggestions.banner(from: entries, dismissedHosts: ["figma.com"], now: now)
        )
    }

    func test_banner_picksStrongest() {
        var entries = (0..<3).map { pick("https://figma.com/\($0)", browser: "Chrome", agoDays: $0) }
        entries += (0..<4).map { pick("https://notion.so/\($0)", browser: "Safari", agoDays: $0) }
        let banner = ActivitySuggestions.banner(from: entries, dismissedHosts: [], now: now)
        XCTAssertEqual(banner?.host, "notion.so")
        XCTAssertEqual(banner?.count, 4)
    }

    // MARK: - Dismissals

    func test_dismissals_activeWithinWindowThenExpires() {
        let defaults = UserDefaults(suiteName: "JunctionTests.\(UUID().uuidString)")!
        let store = SuggestionDismissals(defaults: defaults)
        store.dismiss(host: "figma.com", now: now)
        XCTAssertTrue(store.activeHosts(now: now).contains("figma.com"))
        // 6 days later: still suppressed.
        XCTAssertTrue(store.activeHosts(now: now.addingTimeInterval(6 * 86_400)).contains("figma.com"))
        // 8 days later: expired.
        XCTAssertFalse(store.activeHosts(now: now.addingTimeInterval(8 * 86_400)).contains("figma.com"))
    }

    func test_dismissals_persistAcrossInstances() {
        let suite = "JunctionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        SuggestionDismissals(defaults: defaults).dismiss(host: "figma.com", now: now)
        let reloaded = SuggestionDismissals(defaults: defaults)
        XCTAssertTrue(reloaded.activeHosts(now: now).contains("figma.com"))
    }

    // MARK: - Helpers

    private func key(_ host: String, _ browser: String) -> SuggestionKey {
        SuggestionKey(host: host, browser: browser)
    }

    private func pick(_ url: String, browser: String, agoDays: Int) -> URLLog.Entry {
        entry(url, routing: .routed(to: browser, via: .picker), agoDays: agoDays)
    }

    private func entry(
        _ url: String,
        routing: URLLog.Routing,
        agoDays: Int
    ) -> URLLog.Entry {
        URLLog.Entry(
            url: URL(string: url)!,
            source: .openURLs,
            sourceApp: nil,
            receivedAt: now.addingTimeInterval(-Double(agoDays) * 86_400),
            routing: routing
        )
    }
}
