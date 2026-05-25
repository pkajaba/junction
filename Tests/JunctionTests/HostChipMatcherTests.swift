import XCTest
@testable import Junction

/// Covers the `Matcher` ⇄ host-chip projection, with focus on the
/// empty-chip-list ⇄ `.any` mapping that source-app rules rely on.
final class HostChipMatcherTests: XCTestCase {

    // MARK: - any ⇄ empty chips

    func test_anyMatcher_projectsToEmptyChipList() {
        let chips = HostChipMatcher.chips(from: .any)
        XCTAssertEqual(chips?.hosts, [])
    }

    func test_emptyChipList_buildsAnyMatcher() {
        let chips = HostChipMatcher.Chips(hosts: [], includeSubdomains: true)
        XCTAssertEqual(HostChipMatcher.matcher(from: chips), .any)
    }

    /// Whitespace-only entries are not real hosts — they collapse to
    /// `.any` just like a truly empty list.
    func test_whitespaceOnlyChips_buildAnyMatcher() {
        let chips = HostChipMatcher.Chips(hosts: ["   ", ""], includeSubdomains: false)
        XCTAssertEqual(HostChipMatcher.matcher(from: chips), .any)
    }

    // MARK: - Ordinary host chips still round-trip

    func test_singleHost_buildsHostMatcher() {
        let chips = HostChipMatcher.Chips(hosts: ["github.com"], includeSubdomains: true)
        XCTAssertEqual(HostChipMatcher.matcher(from: chips), .host("github.com"))
    }

    func test_hostMatcher_projectsBackToSingleChip() {
        let chips = HostChipMatcher.chips(from: .host("github.com"))
        XCTAssertEqual(chips, HostChipMatcher.Chips(hosts: ["github.com"], includeSubdomains: true))
    }

    func test_multipleHosts_buildHostRegexAndRoundTrip() {
        let chips = HostChipMatcher.Chips(hosts: ["mail.google.com", "calendar.google.com"],
                                          includeSubdomains: false)
        let matcher = HostChipMatcher.matcher(from: chips)
        XCTAssertEqual(HostChipMatcher.chips(from: matcher), chips)
    }
}
