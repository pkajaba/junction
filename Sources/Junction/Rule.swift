import Foundation

/// A user-defined routing rule: "if a URL looks like THIS, send it THERE".
struct Rule: Identifiable, Equatable {
    let id: UUID
    var name: String
    var enabled: Bool
    var match: Matcher
    var target: Target

    /// Bundle IDs of apps the link must come *from* for this rule to apply
    /// (e.g. `["com.tinyspeck.slackmacgap", "com.microsoft.teams2"]` →
    /// "links from Slack or Teams"). An **empty array** means the rule
    /// fires regardless of the opener app — that's the default.
    ///
    /// Backward-compatible with the singular `sourceApp` key used by the
    /// first cut of this feature: see `Rule`'s custom `Codable` for the
    /// decode-side lift.
    var sourceApps: [String]

    init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool = true,
        match: Matcher,
        target: Target,
        sourceApps: [String] = []
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.match = match
        self.target = target
        self.sourceApps = sourceApps
    }
}

// MARK: - Rule Codable (with sourceApp → sourceApps migration)

extension Rule: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, enabled, match, target
        case sourceApps
        case sourceApp   // legacy singular key — read-only, migrated on decode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.match = try container.decode(Matcher.self, forKey: .match)
        self.target = try container.decode(Target.self, forKey: .target)

        // Prefer the new key. Fall back to the legacy singular `sourceApp`
        // so rules.json files written by the first cut of source-app rules
        // keep loading. Either key absent = "any source", empty array.
        if let plural = try container.decodeIfPresent([String].self, forKey: .sourceApps) {
            self.sourceApps = plural
        } else if let legacy = try container.decodeIfPresent(String.self, forKey: .sourceApp) {
            self.sourceApps = [legacy]
        } else {
            self.sourceApps = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(match, forKey: .match)
        try container.encode(target, forKey: .target)
        // Only write the plural — emitting `sourceApp: null` would create
        // confusing duplication in hand-edited rules.json files.
        try container.encode(sourceApps, forKey: .sourceApps)
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
