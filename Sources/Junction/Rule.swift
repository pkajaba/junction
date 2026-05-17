import Foundation

/// A user-defined routing rule: "if a URL looks like THIS, send it THERE".
struct Rule: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var enabled: Bool
    var match: Matcher
    var target: Target

    init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool = true,
        match: Matcher,
        target: Target
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.match = match
        self.target = target
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
enum Matcher: Equatable {
    case host(String)
    case hostRegex(String)
    case urlContains(String)
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        switch kind {
        case .host:        self = .host(value)
        case .hostRegex:   self = .hostRegex(value)
        case .urlContains: self = .urlContains(value)
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
        }
    }
}
