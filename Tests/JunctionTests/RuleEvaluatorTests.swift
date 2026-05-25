import XCTest
@testable import Junction

final class RuleEvaluatorTests: XCTestCase {

    // MARK: - Host matcher: exact + parent-domain semantics

    func test_host_exactMatch() {
        let url = URL(string: "https://github.com")!
        XCTAssertTrue(RuleEvaluator.matches(url, .host("github.com")))
    }

    func test_host_subdomainMatch() {
        let url = URL(string: "https://api.github.com/users")!
        XCTAssertTrue(RuleEvaluator.matches(url, .host("github.com")))
    }

    func test_host_deepSubdomainMatch() {
        let url = URL(string: "https://docs.api.github.com/foo")!
        XCTAssertTrue(RuleEvaluator.matches(url, .host("github.com")))
    }

    /// Prefix-style impostors must NOT match. This is the key safety
    /// property — "notgithub.com" should never route as "github.com".
    func test_host_prefixDoesNotMatch() {
        let url = URL(string: "https://notgithub.com")!
        XCTAssertFalse(RuleEvaluator.matches(url, .host("github.com")))
    }

    /// Pattern-as-prefix-of-host should also not match.
    func test_host_patternAsPrefixDoesNotMatch() {
        let url = URL(string: "https://github.com.evil.example")!
        XCTAssertFalse(RuleEvaluator.matches(url, .host("github.com")))
    }

    func test_host_caseInsensitive() {
        let url = URL(string: "https://GitHub.COM")!
        XCTAssertTrue(RuleEvaluator.matches(url, .host("GITHUB.com")))
    }

    func test_host_emptyHostDoesNotMatch() {
        let url = URL(string: "file:///tmp/foo")!
        XCTAssertFalse(RuleEvaluator.matches(url, .host("anything")))
    }

    // MARK: - Host regex

    func test_hostRegex_matches() {
        let url = URL(string: "https://mail.google.com")!
        XCTAssertTrue(RuleEvaluator.matches(url, .hostRegex("^(mail|calendar)\\.google\\.com$")))
    }

    func test_hostRegex_doesNotMatch() {
        let url = URL(string: "https://drive.google.com")!
        XCTAssertFalse(RuleEvaluator.matches(url, .hostRegex("^(mail|calendar)\\.google\\.com$")))
    }

    /// Invalid regex should return false rather than crash.
    func test_hostRegex_invalidRegexReturnsFalse() {
        let url = URL(string: "https://example.com")!
        XCTAssertFalse(RuleEvaluator.matches(url, .hostRegex("[unclosed")))
    }

    func test_hostRegex_caseInsensitive() {
        let url = URL(string: "https://MAIL.google.com")!
        XCTAssertTrue(RuleEvaluator.matches(url, .hostRegex("^mail\\.google\\.com$")))
    }

    // MARK: - URL contains

    func test_urlContains_matchesInQuery() {
        let url = URL(string: "https://docs.google.com/d?authuser=user@vetrofibermap.com")!
        XCTAssertTrue(RuleEvaluator.matches(url, .urlContains("vetrofibermap")))
    }

    func test_urlContains_caseInsensitive() {
        let url = URL(string: "https://example.com/Path")!
        XCTAssertTrue(RuleEvaluator.matches(url, .urlContains("path")))
    }

    func test_urlContains_doesNotMatch() {
        let url = URL(string: "https://example.com")!
        XCTAssertFalse(RuleEvaluator.matches(url, .urlContains("notpresent")))
    }

    // MARK: - Evaluator ordering

    func test_evaluate_firstMatchWins() {
        let rule1 = Rule(name: "first", match: .host("example.com"), target: Target(browserBundleID: "first"))
        let rule2 = Rule(name: "second", match: .host("example.com"), target: Target(browserBundleID: "second"))
        let url = URL(string: "https://example.com")!
        let matched = RuleEvaluator.evaluate(url, against: [rule1, rule2])
        XCTAssertEqual(matched?.target.browserBundleID, "first")
        XCTAssertEqual(matched?.name, "first")
    }

    func test_evaluate_disabledRulesSkipped() {
        let disabled = Rule(name: "disabled", enabled: false, match: .host("example.com"),
                            target: Target(browserBundleID: "first"))
        let enabled = Rule(name: "enabled", match: .host("example.com"),
                           target: Target(browserBundleID: "second"))
        let url = URL(string: "https://example.com")!
        let matched = RuleEvaluator.evaluate(url, against: [disabled, enabled])
        XCTAssertEqual(matched?.target.browserBundleID, "second")
    }

    func test_evaluate_noMatchReturnsNil() {
        let rule = Rule(name: "r", match: .host("example.com"),
                        target: Target(browserBundleID: "x"))
        let url = URL(string: "https://other.com")!
        XCTAssertNil(RuleEvaluator.evaluate(url, against: [rule]))
    }

    func test_evaluate_emptyRulesReturnsNil() {
        let url = URL(string: "https://example.com")!
        XCTAssertNil(RuleEvaluator.evaluate(url, against: []))
    }

    // MARK: - Any matcher

    func test_any_matchesEverything() {
        XCTAssertTrue(RuleEvaluator.matches(URL(string: "https://anything.example/x")!, .any))
        XCTAssertTrue(RuleEvaluator.matches(URL(string: "https://github.com")!, .any))
        XCTAssertTrue(RuleEvaluator.matches(URL(string: "http://localhost:3000")!, .any))
    }

    // MARK: - Source-app matching

    private let slack = "com.tinyspeck.slackmacgap"
    private let mail = "com.apple.mail"

    func test_sourceMatches_nilRuleAcceptsAnySource() {
        XCTAssertTrue(RuleEvaluator.sourceMatches(nil, slack))
        XCTAssertTrue(RuleEvaluator.sourceMatches(nil, nil))
    }

    func test_sourceMatches_specificRuleRequiresEqualSource() {
        XCTAssertTrue(RuleEvaluator.sourceMatches(slack, slack))
        XCTAssertFalse(RuleEvaluator.sourceMatches(slack, mail))
        XCTAssertFalse(RuleEvaluator.sourceMatches(slack, nil))
    }

    func test_evaluate_sourceAppRuleMatchesWhenSourceEquals() {
        let rule = Rule(name: "from Slack", match: .any,
                        target: Target(browserBundleID: "com.google.Chrome"),
                        sourceApp: slack)
        let url = URL(string: "https://example.com")!
        XCTAssertEqual(
            RuleEvaluator.evaluate(url, sourceApp: slack, against: [rule])?.name,
            "from Slack"
        )
    }

    func test_evaluate_sourceAppRuleSkippedWhenSourceDiffersOrUnknown() {
        let rule = Rule(name: "from Slack", match: .any,
                        target: Target(browserBundleID: "com.google.Chrome"),
                        sourceApp: slack)
        let url = URL(string: "https://example.com")!
        XCTAssertNil(RuleEvaluator.evaluate(url, sourceApp: mail, against: [rule]))
        XCTAssertNil(RuleEvaluator.evaluate(url, sourceApp: nil, against: [rule]))
    }

    /// A rule with both a host matcher and a source app requires *both*.
    func test_evaluate_sourceAndHostBothRequired() {
        let rule = Rule(name: "github from Slack", match: .host("github.com"),
                        target: Target(browserBundleID: "com.google.Chrome"),
                        sourceApp: slack)
        let github = URL(string: "https://github.com")!
        let other = URL(string: "https://example.com")!
        XCTAssertNotNil(RuleEvaluator.evaluate(github, sourceApp: slack, against: [rule]))
        XCTAssertNil(RuleEvaluator.evaluate(github, sourceApp: mail, against: [rule]))
        XCTAssertNil(RuleEvaluator.evaluate(other, sourceApp: slack, against: [rule]))
    }

    /// A sourceless rule keeps its old behavior — it matches no matter
    /// which app the link came from. Backward-compatibility guard.
    func test_evaluate_sourcelessRuleMatchesRegardlessOfSource() {
        let rule = Rule(name: "plain", match: .host("example.com"),
                        target: Target(browserBundleID: "x"))
        let url = URL(string: "https://example.com")!
        XCTAssertNotNil(RuleEvaluator.evaluate(url, sourceApp: "com.anything", against: [rule]))
        XCTAssertNotNil(RuleEvaluator.evaluate(url, sourceApp: nil, against: [rule]))
    }

    /// An earlier, more specific source-app rule takes precedence over a
    /// later general one — and is correctly skipped for other sources.
    func test_evaluate_specificSourceRulePrecedesGeneralRule() {
        let slackRule = Rule(name: "slack", match: .host("github.com"),
                             target: Target(browserBundleID: "work"),
                             sourceApp: slack)
        let generalRule = Rule(name: "general", match: .host("github.com"),
                               target: Target(browserBundleID: "personal"))
        let url = URL(string: "https://github.com")!
        XCTAssertEqual(
            RuleEvaluator.evaluate(url, sourceApp: slack, against: [slackRule, generalRule])?
                .target.browserBundleID,
            "work"
        )
        XCTAssertEqual(
            RuleEvaluator.evaluate(url, sourceApp: mail, against: [slackRule, generalRule])?
                .target.browserBundleID,
            "personal"
        )
    }
}
