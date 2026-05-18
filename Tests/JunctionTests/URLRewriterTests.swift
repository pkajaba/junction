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
}
