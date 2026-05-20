import Foundation
import AppKit

/// Rewrites a web URL to the native-app URL scheme of the app that owns
/// that host, so we can open the link directly in the native app instead
/// of bouncing through the browser.
///
/// Motivating example: clicking a Zoom meeting link in Slack normally
/// opens the browser, which then shows a "Launch Meeting" page that
/// hands off to Zoom.app. With `AppHandoff.zoom` enabled, Junction
/// transforms the URL to `zoommtg://...` and opens it directly.
///
/// Each case is opt-in via `AppHandoffSettings`. If the user hasn't
/// enabled a handoff, or the native app isn't installed, the URL falls
/// through to the normal rule/picker flow.
enum AppHandoff: String, CaseIterable, Codable, Identifiable {
    case zoom
    case teams
    case slack
    case notion
    case linear
    case spotify
    case discord

    var id: String { rawValue }

    /// Human-readable name shown in Settings and the debug log.
    var displayName: String {
        switch self {
        case .zoom:    return "Zoom"
        case .teams:   return "Microsoft Teams"
        case .slack:   return "Slack"
        case .notion:  return "Notion"
        case .linear:  return "Linear"
        case .spotify: return "Spotify"
        case .discord: return "Discord"
        }
    }

    /// Bundle ID of the native macOS app. Used for installation detection
    /// and for the eventual "show the app icon next to the toggle" UI.
    /// Apps sometimes ship multiple bundle IDs (Teams classic vs Teams 2,
    /// for instance) — we keep a primary here and check alternates inline.
    var bundleID: String {
        switch self {
        case .zoom:    return "us.zoom.xos"
        case .teams:   return "com.microsoft.teams2"     // alternate: com.microsoft.teams
        case .slack:   return "com.tinyspeck.slackmacgap"
        case .notion:  return "notion.id"
        case .linear:  return "com.linear"               // alternate: com.linear.Linear
        case .spotify: return "com.spotify.client"
        case .discord: return "com.hnc.Discord"
        }
    }

    /// Alternate bundle IDs to also check during installation detection.
    /// Empty for apps with a stable single bundle ID.
    var alternateBundleIDs: [String] {
        switch self {
        case .teams:  return ["com.microsoft.teams"]
        case .linear: return ["com.linear.Linear"]
        default:      return []
        }
    }

    // MARK: - Transform

    /// Returns the native-scheme URL if `url` matches this handoff's
    /// host/path pattern, otherwise nil.
    ///
    /// Pure function — no I/O, no side effects.
    func transform(_ url: URL) -> URL? {
        guard let host = url.host?.lowercased() else { return nil }
        switch self {
        case .zoom:    return transformZoom(url, host: host)
        case .teams:   return transformTeams(url, host: host)
        case .slack:   return transformSlack(url, host: host)
        case .notion:  return transformNotion(url, host: host)
        case .linear:  return transformLinear(url, host: host)
        case .spotify: return transformSpotify(url, host: host)
        case .discord: return transformDiscord(url, host: host)
        }
    }

    // MARK: - Per-app transforms

    /// Zoom: https://<subdomain>.zoom.us/j/<meeting-id>?pwd=<pwd>
    ///   → zoommtg://<subdomain>.zoom.us/join?action=join&confno=<id>&pwd=<pwd>
    /// Only `/j/<id>` meeting URLs are transformed; `/my/<personal-link>`
    /// and `/s/<scheduled-id>` fall through (the web flow is fine for
    /// those, and the native scheme has quirks for them).
    private func transformZoom(_ url: URL, host: String) -> URL? {
        guard host == "zoom.us" || host.hasSuffix(".zoom.us") else { return nil }
        let parts = url.pathComponents       // ["/", "j", "<id>"]
        guard parts.count >= 3, parts[1] == "j" else { return nil }
        let meetingID = parts[2]
        guard !meetingID.isEmpty else { return nil }

        let pwd = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "pwd" })?.value

        var components = URLComponents()
        components.scheme = "zoommtg"
        components.host = host
        components.path = "/join"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "action", value: "join"),
            URLQueryItem(name: "confno", value: meetingID),
        ]
        if let pwd { items.append(URLQueryItem(name: "pwd", value: pwd)) }
        components.queryItems = items
        return components.url
    }

    /// Teams: https://teams.microsoft.com/l/meetup-join/<encoded>?<params>
    ///   → msteams:/l/meetup-join/<encoded>?<params>
    /// Just a scheme + host swap; the path and query are preserved.
    private func transformTeams(_ url: URL, host: String) -> URL? {
        guard host == "teams.microsoft.com" else { return nil }
        // Match meeting and deep-link URLs that start with /l/...
        guard url.path.hasPrefix("/l/") else { return nil }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "msteams"
        components?.host = nil          // msteams:/l/... has no host
        return components?.url
    }

    /// Slack: https://app.slack.com/client/<TEAM>/<CHANNEL>
    ///   → slack://channel?team=<TEAM>&id=<CHANNEL>
    /// Workspace-hostname URLs (https://<ws>.slack.com/archives/<C>) are
    /// not handled in v1; they require resolving <ws> to a team ID.
    private func transformSlack(_ url: URL, host: String) -> URL? {
        guard host == "app.slack.com" else { return nil }
        let parts = url.pathComponents      // ["/", "client", "<TEAM>", "<CHANNEL>"]
        guard parts.count >= 4, parts[1] == "client" else { return nil }
        let team = parts[2], channel = parts[3]
        guard !team.isEmpty, !channel.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "slack"
        components.host = "channel"     // slack://channel?team=…&id=…
        components.queryItems = [
            URLQueryItem(name: "team", value: team),
            URLQueryItem(name: "id", value: channel),
        ]
        return components.url
    }

    /// Notion: https://www.notion.so/<path>  → notion://www.notion.so/<path>
    /// Also handles bare notion.so (no www).
    private func transformNotion(_ url: URL, host: String) -> URL? {
        guard host == "www.notion.so" || host == "notion.so" else { return nil }
        return urlByReplacingScheme(url, with: "notion")
    }

    /// Linear: https://linear.app/<rest>  → linear://linear.app/<rest>
    private func transformLinear(_ url: URL, host: String) -> URL? {
        guard host == "linear.app" else { return nil }
        return urlByReplacingScheme(url, with: "linear")
    }

    /// Spotify: https://open.spotify.com/<type>/<id>(?si=…)
    ///   → spotify:<type>:<id>
    /// Note the **colons** (not ://) — Spotify's URI grammar is its own.
    /// The query string (`?si=…` share token) is dropped because the
    /// native scheme doesn't use it.
    private func transformSpotify(_ url: URL, host: String) -> URL? {
        guard host == "open.spotify.com" else { return nil }
        let parts = url.pathComponents      // ["/", "<type>", "<id>"]
        guard parts.count >= 3 else { return nil }
        let type = parts[1], id = parts[2]
        let validTypes: Set<String> = ["track", "album", "playlist", "artist", "show", "episode"]
        guard validTypes.contains(type), !id.isEmpty else { return nil }
        return URL(string: "spotify:\(type):\(id)")
    }

    /// Discord: https://discord.com/channels/<guild-or-@me>/<channel>
    ///   → discord://discord.com/channels/<guild>/<channel>
    /// Also handles discordapp.com (the older domain still in some
    /// shared URLs).
    private func transformDiscord(_ url: URL, host: String) -> URL? {
        guard host == "discord.com" || host == "discordapp.com" else { return nil }
        guard url.path.hasPrefix("/channels/") else { return nil }
        return urlByReplacingScheme(url, with: "discord")
    }

    // MARK: - Helper

    /// Returns `url` with its scheme replaced. Path, query, fragment, and
    /// host all carry through unchanged. Used by handoffs whose native
    /// scheme uses the same path/host shape as the web URL.
    private func urlByReplacingScheme(_ url: URL, with newScheme: String) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = newScheme
        return components?.url
    }

    // MARK: - Installation detection

    /// True if the native app for this handoff is installed on this Mac.
    /// Checks the primary bundle ID and any known alternates.
    var isInstalled: Bool {
        let workspace = NSWorkspace.shared
        if workspace.urlForApplication(withBundleIdentifier: bundleID) != nil { return true }
        for alt in alternateBundleIDs
        where workspace.urlForApplication(withBundleIdentifier: alt) != nil {
            return true
        }
        return false
    }
}
