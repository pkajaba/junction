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

    // MARK: - normalizeChip (path-preserving form)

    func test_normalizeChip_invalidInputs_returnNil() {
        XCTAssertNil(HostChipMatcher.normalizeChip(from: ""))
        XCTAssertNil(HostChipMatcher.normalizeChip(from: "   "))
        XCTAssertNil(HostChipMatcher.normalizeChip(from: "not a host"))   // space → invalid
        XCTAssertNil(HostChipMatcher.normalizeChip(from: "no-tld"))       // no dot
        XCTAssertNil(HostChipMatcher.normalizeChip(from: "https://"))     // no host part
    }

    /// Pasting a URL with a real path keeps the path in the chip so we
    /// can build a `.urlPrefix` matcher later. This was the bug behind
    /// "github.com/NBTSolutions becomes just github.com".
    func test_normalizeChip_urlWithPath_keepsPath() {
        XCTAssertEqual(
            HostChipMatcher.normalizeChip(from: "https://github.com/NBTSolutions/foo"),
            "github.com/NBTSolutions/foo"
        )
    }

    /// A trailing `/` and an empty path are both "no real path" — we
    /// strip them down to a plain host chip, matching the old behavior.
    func test_normalizeChip_urlWithRootOrEmptyPath_isHostOnly() {
        XCTAssertEqual(HostChipMatcher.normalizeChip(from: "https://github.com/"), "github.com")
        XCTAssertEqual(HostChipMatcher.normalizeChip(from: "https://github.com"), "github.com")
    }

    func test_normalizeChip_bareHost_unchanged() {
        XCTAssertEqual(HostChipMatcher.normalizeChip(from: "github.com"), "github.com")
    }

    // MARK: - matcher(from:) ⇄ chips(from:) for urlPrefix

    func test_pathChip_buildsUrlPrefixMatcher() {
        let chips = HostChipMatcher.Chips(hosts: ["github.com/NBTSolutions/"],
                                          includeSubdomains: false)
        XCTAssertEqual(
            HostChipMatcher.matcher(from: chips),
            .urlPrefix("https://github.com/NBTSolutions/")
        )
    }

    func test_urlPrefixMatcher_projectsBackToSinglePathChip() {
        let projected = HostChipMatcher.chips(from: .urlPrefix("https://github.com/NBT/"))
        XCTAssertEqual(projected,
                       HostChipMatcher.Chips(hosts: ["github.com/NBT/"],
                                             includeSubdomains: false))
    }

    /// Mixing a path chip with host chips: the path chip wins (MVP).
    func test_mixedHostAndPathChips_useUrlPrefixOfFirstPath() {
        let chips = HostChipMatcher.Chips(hosts: ["example.com", "github.com/NBT/"],
                                          includeSubdomains: true)
        XCTAssertEqual(
            HostChipMatcher.matcher(from: chips),
            .urlPrefix("https://github.com/NBT/")
        )
    }
}
