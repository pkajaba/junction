import XCTest
@testable import Junction

/// Verifies the JSON shape of rules.json is stable. Users edit this file
/// by hand and via Junction's settings UI; both paths must agree, and
/// historical files must keep loading after schema changes.
final class RuleCodableTests: XCTestCase {

    // MARK: - Full Rule round-trip

    func test_rule_hostMatcher_roundTrip() throws {
        let original = Rule(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "GitHub → Chrome",
            enabled: true,
            match: .host("github.com"),
            target: Target(
                browserBundleID: "com.google.Chrome",
                profile: "Default",
                extraArgs: [],
                openInNewWindow: false
            )
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Rule.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_rule_hostRegexMatcher_roundTrip() throws {
        let original = Rule(
            id: UUID(),
            name: "Workspace",
            match: .hostRegex("^(mail|calendar)\\.google\\.com$"),
            target: Target(browserBundleID: "com.google.Chrome")
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Rule.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_rule_urlContainsMatcher_roundTrip() throws {
        let original = Rule(
            id: UUID(),
            name: "HN → Safari",
            match: .urlContains("news.ycombinator.com"),
            target: Target(browserBundleID: "com.apple.Safari")
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Rule.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Matcher discriminator shape

    /// The JSON must use a clear, human-readable shape — users edit this
    /// file by hand. Lock in the discriminator format.
    func test_matcher_host_jsonShape() throws {
        let data = try JSONEncoder().encode(Matcher.host("github.com"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["type"], "host")
        XCTAssertEqual(json?["value"], "github.com")
    }

    func test_matcher_hostRegex_jsonShape() throws {
        let data = try JSONEncoder().encode(Matcher.hostRegex("^x$"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["type"], "hostRegex")
        XCTAssertEqual(json?["value"], "^x$")
    }

    func test_matcher_urlContains_jsonShape() throws {
        let data = try JSONEncoder().encode(Matcher.urlContains("/issues/"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["type"], "urlContains")
        XCTAssertEqual(json?["value"], "/issues/")
    }

    /// Unknown matcher type should error cleanly rather than crash. Users
    /// editing rules.json by hand will mistype things; failure mode
    /// matters.
    func test_matcher_unknownType_throwsDecodingError() {
        let json = "{\"type\": \"magic\", \"value\": \"abc\"}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Matcher.self, from: json))
    }

    // MARK: - File envelope (schema version, rules array)

    func test_fileEnvelope_emptyRules_roundTrip() throws {
        let original = RuleStore.File(rules: [], schemaVersion: 1)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RuleStore.File.self, from: data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertTrue(decoded.rules.isEmpty)
    }

    func test_fileEnvelope_withRules_roundTrip() throws {
        let rules = [
            Rule(name: "a", match: .host("a.com"), target: Target(browserBundleID: "com.x")),
            Rule(name: "b", match: .urlContains("foo"), target: Target(browserBundleID: "com.y")),
        ]
        let original = RuleStore.File(rules: rules, schemaVersion: 1)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RuleStore.File.self, from: data)
        XCTAssertEqual(decoded.rules.count, 2)
        XCTAssertEqual(decoded.rules.first?.name, "a")
    }
}
