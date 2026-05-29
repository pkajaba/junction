import XCTest
@testable import Junction

/// Covers Activity-log URL redaction: secret-bearing query values are
/// scrubbed (key preserved), everything else — host, path, ordinary params
/// — is left intact.
final class SensitiveURLRedactorTests: XCTestCase {

    private func redacted(_ string: String) -> String {
        SensitiveURLRedactor.redact(URL(string: string)!).absoluteString
    }

    func test_redactsKnownSensitiveValue() {
        let out = redacted("https://zoom.us/j/123?pwd=SECRET123")
        XCTAssertTrue(out.contains("pwd=REDACTED"))
        XCTAssertFalse(out.contains("SECRET123"))
    }

    func test_preservesHostPathAndOrdinaryParams() {
        let out = redacted("https://example.com/a/b?utm_source=news&token=abc&page=2")
        XCTAssertTrue(out.contains("example.com/a/b"))
        XCTAssertTrue(out.contains("utm_source=news"))
        XCTAssertTrue(out.contains("page=2"))
        XCTAssertTrue(out.contains("token=REDACTED"))
        XCTAssertFalse(out.contains("token=abc"))
    }

    func test_keyMatchIsCaseInsensitive() {
        let out = redacted("https://example.com/?Access_Token=xyz")
        XCTAssertTrue(out.contains("Access_Token=REDACTED"))
        XCTAssertFalse(out.contains("xyz"))
    }

    func test_urlWithNoQueryIsUnchanged() {
        let url = URL(string: "https://example.com/path")!
        XCTAssertEqual(SensitiveURLRedactor.redact(url), url)
    }

    func test_urlWithNoSensitiveParamsIsUnchanged() {
        let url = URL(string: "https://example.com/?a=1&b=2")!
        XCTAssertEqual(SensitiveURLRedactor.redact(url), url)
    }

    func test_valuelessSensitiveKeyIsLeftAlone() {
        // `?token` with no value carries nothing to leak — don't fabricate one.
        let out = redacted("https://example.com/?token")
        XCTAssertFalse(out.contains("REDACTED"))
    }

    func test_multipleSensitiveParamsAllRedacted() {
        let out = redacted("https://example.com/?code=A&state=B&id=keep")
        XCTAssertTrue(out.contains("code=REDACTED"))
        XCTAssertTrue(out.contains("state=REDACTED"))
        XCTAssertTrue(out.contains("id=keep"))
    }

    // MARK: - Fragment (OAuth implicit flow)

    func test_redactsTokensInFragment() {
        let out = redacted(
            "https://app.example.com/cb#access_token=ABC123&token_type=bearer&expires_in=3600"
        )
        XCTAssertTrue(out.contains("access_token=REDACTED"))
        XCTAssertFalse(out.contains("ABC123"))
        XCTAssertTrue(out.contains("token_type=bearer"))
        XCTAssertTrue(out.contains("expires_in=3600"))
    }

    func test_nonKeyValueFragmentIsUnchanged() {
        let url = URL(string: "https://example.com/docs#section-2")!
        XCTAssertEqual(SensitiveURLRedactor.redact(url), url)
    }

    // MARK: - Embedded credentials & signed-URL params

    func test_redactsEmbeddedPassword() {
        let out = redacted("https://alice:hunter2@example.com/inbox")
        XCTAssertFalse(out.contains("hunter2"))
        XCTAssertTrue(out.contains("alice"))            // username kept
        XCTAssertTrue(out.contains("example.com/inbox"))
    }

    func test_redactsSignedURLSignature() {
        let out = redacted("https://s3.example.com/o?X-Amz-Signature=deadbeef&X-Amz-Expires=60")
        XCTAssertTrue(out.contains("X-Amz-Signature=REDACTED"))
        XCTAssertFalse(out.contains("deadbeef"))
        XCTAssertTrue(out.contains("X-Amz-Expires=60"))
    }
}
