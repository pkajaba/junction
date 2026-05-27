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

    func test_rule_withMultipleSourceApps_roundTrip() throws {
        let original = Rule(
            id: UUID(),
            name: "Chat apps → Chrome",
            match: .any,
            target: Target(browserBundleID: "com.google.Chrome"),
            sourceApps: ["com.tinyspeck.slackmacgap", "com.microsoft.teams2"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Rule.self, from: data)
        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.sourceApps,
                       ["com.tinyspeck.slackmacgap", "com.microsoft.teams2"])
        XCTAssertEqual(decoded.match, .any)
    }

    /// Rules written before any source-app key existed (the original
    /// rules.json schema) must still load — absent key decodes as an
    /// empty `sourceApps` array.
    func test_rule_legacyJSON_withoutSourceApp_decodesAsEmptyArray() throws {
        let json = Data("""
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "name": "Legacy",
          "enabled": true,
          "match": { "type": "host", "value": "github.com" },
          "target": {
            "browserBundleID": "com.apple.Safari",
            "extraArgs": [],
            "openInNewWindow": false
          }
        }
        """.utf8)
        let decoded = try JSONDecoder().decode(Rule.self, from: json)
        XCTAssertEqual(decoded.sourceApps, [])
        XCTAssertEqual(decoded.name, "Legacy")
        XCTAssertEqual(decoded.match, .host("github.com"))
    }

    /// Rules written by the first cut of source-app rules used a singular
    /// `sourceApp` key. The decoder lifts that into a one-element
    /// `sourceApps` array so nobody loses a saved rule.
    func test_rule_legacyJSON_withSingularSourceApp_liftsToArray() throws {
        let json = Data("""
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "name": "Old-shape Slack rule",
          "enabled": true,
          "match": { "type": "any" },
          "target": {
            "browserBundleID": "com.google.Chrome",
            "extraArgs": [],
            "openInNewWindow": false
          },
          "sourceApp": "com.tinyspeck.slackmacgap"
        }
        """.utf8)
        let decoded = try JSONDecoder().decode(Rule.self, from: json)
        XCTAssertEqual(decoded.sourceApps, ["com.tinyspeck.slackmacgap"])
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
        let json = Data("{\"type\": \"magic\", \"value\": \"abc\"}".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Matcher.self, from: json))
    }

    /// The `any` matcher carries no value — its JSON is just the type
    /// discriminator. Lock that shape in.
    func test_matcher_any_jsonShape() throws {
        let data = try JSONEncoder().encode(Matcher.any)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["type"], "any")
        XCTAssertNil(json?["value"])
    }

    func test_matcher_any_roundTrip() throws {
        let data = try JSONEncoder().encode(Matcher.any)
        let decoded = try JSONDecoder().decode(Matcher.self, from: data)
        XCTAssertEqual(decoded, .any)
    }

    /// Decoding `any` must not require a `value` key.
    func test_matcher_any_decodesWithoutValue() throws {
        let json = Data("{\"type\": \"any\"}".utf8)
        let decoded = try JSONDecoder().decode(Matcher.self, from: json)
        XCTAssertEqual(decoded, .any)
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
