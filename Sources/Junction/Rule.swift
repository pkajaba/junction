import Foundation

/// A user-defined routing rule: "if a URL looks like THIS, send it THERE".
struct Rule: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var enabled: Bool
    var match: Matcher
    var target: Target

    /// Optional bundle ID of the app the link must come *from* for this
    /// rule to apply (e.g. `"com.tinyspeck.slackmacgap"` → "links from
    /// Slack"). `nil` means the rule fires regardless of the opener app.
    ///
    /// Backward-compatible: the key is decoded with `decodeIfPresent`, so
    /// rules saved before this field existed load fine as `nil`.
    var sourceApp: String?

    init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool = true,
        match: Matcher,
        target: Target,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.match = match
        self.target = target
        self.sourceApp = sourceApp
    }
}

/// How a rule decides whether a URL matches.
///
/// Three matchers cover the common cases without leaking regex syntax into
/// the JSON for users who just want "github.com → Chrome":
///
/// - `.host("github.com")` matches `github.com` exactly **and** any subdomain
///   (`api.github.com`, `gist.github.com`, ...).
/// - `.hostRegex("...")` runs an arbitrary case-insensitive regex against the
///   URL's host. Power tool — use when `.host` isn't expressive enough.
/// - `.urlContains("/issues/")` matches if the substring appears anywhere in
///   the full URL string. Useful for path-based rules.
/// - `.any` matches every URL. Used by source-app-only rules ("everything
///   from Slack → Chrome") where the URL pattern is irrelevant.
enum Matcher: Equatable {
    case host(String)
    case hostRegex(String)
    case urlContains(String)
    case any
}

/// Where a matched URL should be opened.
struct Target: Codable, Equatable {
    var browserBundleID: String
    var profile: String?
    var extraArgs: [String]
    var openInNewWindow: Bool

    init(
        browserBundleID: String,
        profile: String? = nil,
        extraArgs: [String] = [],
        openInNewWindow: Bool = false
    ) {
        self.browserBundleID = browserBundleID
        self.profile = profile
        self.extraArgs = extraArgs
        self.openInNewWindow = openInNewWindow
    }
}

// MARK: - Matcher Codable

extension Matcher: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum Kind: String, Codable {
        case host
        case hostRegex
        case urlContains
        case any
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)
        if kind == .any {
            self = .any
            return
        }
        let value = try container.decode(String.self, forKey: .value)
        switch kind {
        case .host:        self = .host(value)
        case .hostRegex:   self = .hostRegex(value)
        case .urlContains: self = .urlContains(value)
        case .any:         self = .any   // unreachable; handled above
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .host(let value):
            try container.encode(Kind.host, forKey: .type)
            try container.encode(value, forKey: .value)
        case .hostRegex(let value):
            try container.encode(Kind.hostRegex, forKey: .type)
            try container.encode(value, forKey: .value)
        case .urlContains(let value):
            try container.encode(Kind.urlContains, forKey: .type)
            try container.encode(value, forKey: .value)
        case .any:
            try container.encode(Kind.any, forKey: .type)
        }
    }
}
