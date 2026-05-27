import XCTest
@testable import Junction

final class URLRewriterTests: XCTestCase {

    // MARK: - Tracking-param stripping

    func test_stripQueryParams_removesUTM() {
        let url = URL(string: "https://example.com/?utm_source=newsletter&id=42")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_source"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?id=42")
    }

    func test_stripQueryParams_caseInsensitive() {
        let url = URL(string: "https://example.com/?UTM_Source=x&keep=y")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_source"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?keep=y")
    }

    /// URLs with no query string should be returned unchanged (identity).
    func test_stripQueryParams_noParams_returnsIdentity() {
        let url = URL(string: "https://example.com/path")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_source"])
        XCTAssertEqual(result, url)
    }

    /// When the rewriter has nothing to strip, return the original URL
    /// unchanged (preserves formatting nuances).
    func test_stripQueryParams_noMatchingParams_returnsOriginal() {
        let url = URL(string: "https://example.com/?keep=this")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_source"])
        XCTAssertEqual(result, url)
    }

    /// If every query param gets stripped, the `?` should go away too.
    func test_stripQueryParams_allParamsStripped_dropsQueryString() {
        let url = URL(string: "https://example.com/?utm_source=x&utm_medium=y")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_source", "utm_medium"])
        XCTAssertEqual(result.absoluteString, "https://example.com/")
    }

    func test_stripQueryParams_preservesOrder() {
        let url = URL(string: "https://example.com/?a=1&b=2&c=3")!
        let result = URLRewriter.stripQueryParams(url, params: ["b"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?a=1&c=3")
    }

    func test_stripQueryParams_realWorldMixedTracking() {
        // Typical newsletter link with utms + a real content param.
        let url = URL(string: "https://blog.example.com/article?utm_source=newsletter&utm_medium=email&fbclid=abc&id=42")!
        let result = URLRewriter.stripQueryParams(
            url, params: ["utm_source", "utm_medium", "fbclid"]
        )
        XCTAssertEqual(result.absoluteString, "https://blog.example.com/article?id=42")
    }

    // MARK: - Glob support

    /// `utm_*` should sweep up all the `utm_*` family with one entry.
    /// Saves users the toil of listing each variant individually.
    func test_stripQueryParams_glob_matchesPrefix() {
        let url = URL(string: "https://example.com/?utm_source=a&utm_medium=b&utm_campaign=c&keep=d")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_*"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?keep=d")
    }

    /// Globs are anchored — `utm_*` doesn't accidentally match
    /// `some_utm_thing`. (Important: an underscore in the user-visible
    /// pattern is a regex literal, so this isn't a false positive.)
    func test_stripQueryParams_glob_anchored() {
        let url = URL(string: "https://example.com/?ref=keep&some_utm_thing=keepme")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_*"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?ref=keep&some_utm_thing=keepme")
    }

    func test_stripQueryParams_glob_caseInsensitive() {
        let url = URL(string: "https://example.com/?UTM_Source=x&Utm_Medium=y&keep=z")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_*"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?keep=z")
    }

    /// Mixing globs and exact strings in the same set works.
    func test_stripQueryParams_glob_mixedWithExact() {
        let url = URL(string: "https://example.com/?utm_source=a&fbclid=b&id=c")!
        let result = URLRewriter.stripQueryParams(url, params: ["utm_*", "fbclid"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?id=c")
    }

    /// Suffix globs: `*_token` matches `auth_token`, `access_token`, etc.
    func test_stripQueryParams_glob_suffix() {
        let url = URL(string: "https://example.com/?auth_token=a&access_token=b&id=c")!
        let result = URLRewriter.stripQueryParams(url, params: ["*_token"])
        XCTAssertEqual(result.absoluteString, "https://example.com/?id=c")
    }

    // MARK: - TrackingParamPattern direct tests

    func test_pattern_exact_matchesCaseInsensitive() {
        XCTAssertTrue(TrackingParamPattern("fbclid").matches("fbclid"))
        XCTAssertTrue(TrackingParamPattern("fbclid").matches("FBclid"))
        XCTAssertFalse(TrackingParamPattern("fbclid").matches("fbclids"))
        XCTAssertFalse(TrackingParamPattern("fbclid").matches("notfbclid"))
    }

    func test_pattern_glob_matchesAnchored() {
        let p = TrackingParamPattern("utm_*")
        XCTAssertTrue(p.matches("utm_source"))
        XCTAssertTrue(p.matches("utm_"))                  // empty tail OK
        XCTAssertFalse(p.matches("some_utm_thing"))       // must start with "utm_"
    }
}
