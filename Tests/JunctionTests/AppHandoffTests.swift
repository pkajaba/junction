import XCTest
@testable import Junction

/// Tests for the native-app handoff URL transforms. These are pure
/// functions — given a web URL, produce the native-scheme URL (or nil).
///
/// NOTE: this file needs the `JunctionTests` target, which is added by
/// the baseline-quality work. Until that target exists in `project.yml`,
/// these tests live here but don't run.
final class AppHandoffTests: XCTestCase {

    // MARK: - Zoom

    func test_zoom_basicMeeting() {
        let web = URL(string: "https://us02web.zoom.us/j/123456789")!
        let native = AppHandoff.zoom.transform(web)
        XCTAssertEqual(native?.scheme, "zoommtg")
        XCTAssertEqual(native?.host, "us02web.zoom.us")
        XCTAssertTrue(native?.absoluteString.contains("confno=123456789") ?? false)
        XCTAssertTrue(native?.absoluteString.contains("action=join") ?? false)
    }

    func test_zoom_meetingWithPassword() {
        let web = URL(string: "https://company.zoom.us/j/987654321?pwd=abc123")!
        let native = AppHandoff.zoom.transform(web)
        XCTAssertEqual(native?.scheme, "zoommtg")
        XCTAssertTrue(native?.absoluteString.contains("confno=987654321") ?? false)
        XCTAssertTrue(native?.absoluteString.contains("pwd=abc123") ?? false)
    }

    func test_zoom_personalRoomNotTransformed() {
        // /my/<link> is not a /j/ meeting URL — should fall through.
        let web = URL(string: "https://company.zoom.us/my/personal.link")!
        XCTAssertNil(AppHandoff.zoom.transform(web))
    }

    func test_zoom_nonZoomURLNotTransformed() {
        let web = URL(string: "https://example.com/j/123")!
        XCTAssertNil(AppHandoff.zoom.transform(web))
    }

    // MARK: - Teams

    func test_teams_meetupJoin() {
        let web = URL(string: "https://teams.microsoft.com/l/meetup-join/19%3ameeting_abc")!
        let native = AppHandoff.teams.transform(web)
        XCTAssertEqual(native?.scheme, "msteams")
        XCTAssertTrue(native?.absoluteString.contains("/l/meetup-join/") ?? false)
    }

    func test_teams_nonDeeplinkNotTransformed() {
        // The teams.microsoft.com homepage is not an /l/ deep link.
        let web = URL(string: "https://teams.microsoft.com/")!
        XCTAssertNil(AppHandoff.teams.transform(web))
    }

    // MARK: - Slack

    func test_slack_clientChannel() {
        let web = URL(string: "https://app.slack.com/client/T01ABC/C02XYZ")!
        let native = AppHandoff.slack.transform(web)
        XCTAssertEqual(native?.scheme, "slack")
        XCTAssertTrue(native?.absoluteString.contains("team=T01ABC") ?? false)
        XCTAssertTrue(native?.absoluteString.contains("id=C02XYZ") ?? false)
    }

    func test_slack_workspaceArchiveNotTransformed() {
        // workspace.slack.com/archives form is not handled in v1.
        let web = URL(string: "https://myteam.slack.com/archives/C02XYZ")!
        XCTAssertNil(AppHandoff.slack.transform(web))
    }

    // MARK: - Notion

    func test_notion_pageURL() {
        let web = URL(string: "https://www.notion.so/workspace/My-Page-abc123")!
        let native = AppHandoff.notion.transform(web)
        XCTAssertEqual(native?.scheme, "notion")
        XCTAssertEqual(native?.host, "www.notion.so")
        XCTAssertEqual(native?.path, "/workspace/My-Page-abc123")
    }

    func test_notion_bareHost() {
        let web = URL(string: "https://notion.so/abc123")!
        XCTAssertEqual(AppHandoff.notion.transform(web)?.scheme, "notion")
    }

    // MARK: - Linear

    func test_linear_issue() {
        let web = URL(string: "https://linear.app/acme/issue/ACM-42")!
        let native = AppHandoff.linear.transform(web)
        XCTAssertEqual(native?.scheme, "linear")
        XCTAssertEqual(native?.path, "/acme/issue/ACM-42")
    }

    // MARK: - Spotify

    func test_spotify_track() {
        let web = URL(string: "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT")!
        let native = AppHandoff.spotify.transform(web)
        XCTAssertEqual(native?.absoluteString, "spotify:track:4cOdK2wGLETKBW3PvgPWqT")
    }

    func test_spotify_playlistDropsShareToken() {
        // ?si=<token> share param must not survive into the native URI.
        let web = URL(string: "https://open.spotify.com/playlist/37i9dQ?si=xyz")!
        let native = AppHandoff.spotify.transform(web)
        XCTAssertEqual(native?.absoluteString, "spotify:playlist:37i9dQ")
    }

    func test_spotify_unknownTypeNotTransformed() {
        let web = URL(string: "https://open.spotify.com/gibberish/123")!
        XCTAssertNil(AppHandoff.spotify.transform(web))
    }

    // MARK: - Discord

    func test_discord_channel() {
        let web = URL(string: "https://discord.com/channels/111/222")!
        let native = AppHandoff.discord.transform(web)
        XCTAssertEqual(native?.scheme, "discord")
        XCTAssertEqual(native?.path, "/channels/111/222")
    }

    func test_discord_nonChannelNotTransformed() {
        let web = URL(string: "https://discord.com/download")!
        XCTAssertNil(AppHandoff.discord.transform(web))
    }

    // MARK: - Cross-cutting

    func test_eachHandoff_ignoresUnrelatedURL() {
        let unrelated = URL(string: "https://example.com/some/page")!
        for handoff in AppHandoff.allCases {
            XCTAssertNil(handoff.transform(unrelated),
                         "\(handoff.displayName) should not transform an unrelated URL")
        }
    }

    @MainActor
    func test_settings_handoffForURL_findsEnabledMatch() {
        let settings = AppHandoffSettings.shared
        let snapshot = settings.enabled        // restore after the test
        defer { settings.enabled = snapshot }

        settings.enabled = [.zoom]
        let zoomURL = URL(string: "https://us02web.zoom.us/j/555")!
        let match = settings.handoff(for: zoomURL)
        XCTAssertEqual(match?.0, .zoom)
        XCTAssertEqual(match?.1.scheme, "zoommtg")

        // A URL no enabled handoff claims → nil.
        XCTAssertNil(settings.handoff(for: URL(string: "https://example.com")!))
    }
}
