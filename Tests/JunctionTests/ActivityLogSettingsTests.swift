import XCTest
@testable import Junction

/// Covers the Activity-log retention window's duration mapping — the value
/// `URLLog` feeds into `retained(...)`. (Persistence uses the same
/// UserDefaults pattern as the other settings types and isn't re-tested
/// here to avoid mutating the shared singleton / standard defaults.)
@MainActor
final class ActivityLogSettingsTests: XCTestCase {

    func test_maxAgeMatchesLabelledWindow() {
        let day: TimeInterval = 24 * 60 * 60
        XCTAssertEqual(ActivityLogSettings.Retention.days7.maxAge, 7 * day)
        XCTAssertEqual(ActivityLogSettings.Retention.days30.maxAge, 30 * day)
        XCTAssertEqual(ActivityLogSettings.Retention.days90.maxAge, 90 * day)
    }

    func test_windowsAreOrderedAndForeverIsLargest() {
        let cases = ActivityLogSettings.Retention.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertLessThan(ActivityLogSettings.Retention.days7.maxAge,
                          ActivityLogSettings.Retention.days30.maxAge)
        XCTAssertLessThan(ActivityLogSettings.Retention.days30.maxAge,
                          ActivityLogSettings.Retention.days90.maxAge)
        XCTAssertLessThan(ActivityLogSettings.Retention.days90.maxAge,
                          ActivityLogSettings.Retention.forever.maxAge)
    }

    func test_foreverIsEffectivelyUnbounded() {
        // ≥ 50 years — long enough that no real Activity log ages out, but
        // finite so date arithmetic in URLLog.retained can't overflow.
        XCTAssertGreaterThan(
            ActivityLogSettings.Retention.forever.maxAge,
            50 * 365 * 24 * 60 * 60
        )
    }
}
