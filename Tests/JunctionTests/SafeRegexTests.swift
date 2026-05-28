import XCTest
@testable import Junction

/// Covers the ReDoS guards on user-authored regex: correctness for normal
/// patterns, the pattern/input length caps, the compile cache, and — most
/// importantly — that a catastrophically-backtracking pattern bails at the
/// budget instead of hanging routing.
final class SafeRegexTests: XCTestCase {

    func test_matches_normalPatterns() {
        XCTAssertTrue(SafeRegex.matches(pattern: "github", input: "api.github.com"))
        XCTAssertTrue(SafeRegex.matches(pattern: "(^|\\.)github\\.com$", input: "api.github.com"))
        XCTAssertFalse(SafeRegex.matches(pattern: "^github\\.com$", input: "api.github.com"))
    }

    func test_matches_isCaseInsensitive() {
        XCTAssertTrue(SafeRegex.matches(pattern: "GITHUB", input: "github.com"))
    }

    func test_matches_emptyInputIsFalse() {
        XCTAssertFalse(SafeRegex.matches(pattern: ".*", input: ""))
    }

    func test_compile_rejectsOverLongPattern() {
        let long = String(repeating: "a", count: SafeRegex.maxPatternLength + 1)
        XCTAssertNil(SafeRegex.compile(long))
        XCTAssertFalse(SafeRegex.matches(pattern: long, input: "aaa"))
    }

    func test_compile_acceptsPatternAtCap() {
        let atCap = String(repeating: "a", count: SafeRegex.maxPatternLength)
        XCTAssertNotNil(SafeRegex.compile(atCap))
    }

    func test_compile_returnsNilForInvalidPattern() {
        XCTAssertNil(SafeRegex.compile("(unclosed"))
        XCTAssertFalse(SafeRegex.matches(pattern: "(unclosed", input: "anything"))
    }

    func test_compile_cachesTheSameInstance() {
        let first = SafeRegex.compile("cached\\.example\\.com")
        let second = SafeRegex.compile("cached\\.example\\.com")
        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
    }

    func test_matches_overLongInputIsFalse() {
        let bigInput = String(repeating: "a", count: SafeRegex.maxInputLength + 1)
        XCTAssertFalse(SafeRegex.matches(pattern: "a", input: bigInput))
    }

    /// `(a+)+$` over a long run of `a` ending in `b` is the textbook
    /// exponential-backtracking case. Without the budget this would take
    /// many seconds; with it, the call must return `false` promptly. We
    /// assert a generous ceiling (CI is noisy) — the point is "doesn't
    /// hang", not exact timing.
    func test_matches_catastrophicPattern_bailsAtBudget() {
        let evil = "^(a+)+$"
        let input = String(repeating: "a", count: 30) + "b"
        let start = Date()
        let result = SafeRegex.matches(pattern: evil, input: input)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertFalse(result)
        XCTAssertLessThan(elapsed, 2.0, "catastrophic match should bail at the budget, not hang")
    }
}
