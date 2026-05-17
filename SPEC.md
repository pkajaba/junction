# Junction — Technical Spec

This document describes Junction's architecture and design decisions. It's deliberately written before any Swift code so we have something to push against, not just react to. It will evolve.

## Goals

1. **Route URLs to the right browser**, with rules and a fallback picker.
2. **Native macOS** — Swift, system frameworks, no Electron, no web view chrome.
3. **Small, fast, accessible.** The picker should appear in under 100ms after a link click.
4. **Open and forkable.** MIT, plain-text config, no telemetry, no account.

## Non-goals

- Cross-platform (macOS only — no Linux/Windows)
- Per-tab routing (we route opens, not navigation inside a browser)
- Mobile (no iOS)
- Replacing browsers themselves (we route, not render)
- Mac App Store distribution (sandboxing would block default-browser registration; we ship via signed `.dmg` / Homebrew cask)

## User flows

### 1. Click a link in any app
1. App calls `LSOpenURL` (or equivalent) with the link.
2. macOS dispatches a GetURL Apple Event to the registered default browser → **Junction**.
3. Junction matches the URL against the user's rule list.
4. **Match → silent route.** `open -na "<browser>" --args --profile-directory=<X> <url>` (or equivalent per browser).
5. **No match → picker.**

### 2. Picker
- Borderless window centered on the active display, dismissable with `Esc`.
- Grid of installed browser icons (auto-detected, filtered through the user's hide-list).
- Keyboard:
  - `Enter` → default browser (top-left, configurable)
  - `1`–`9` / type-to-filter → pick a browser
  - `↑/↓/←/→` → navigate
  - Hold `⌥` (Option) when picking → "Always for this domain" (saves a rule)
  - `Esc` → cancel (URL is dropped)
- Title bar shows the URL (truncated, full on hover).

### 3. Settings
- Standard SwiftUI Settings scene (`⌘,`).
- **Rules tab**: list of rules, drag to reorder, inline edit, +/- buttons, "Test URL" field.
- **Browsers tab**: detected browsers, checkbox to hide from picker, per-browser profile detection.
- **Advanced tab**: URL shortener list, tracking-param strip list, log level, "reveal rules.json".

## Data model

### Rule (Swift sketch)

```swift
struct Rule: Codable, Identifiable {
    let id: UUID
    var name: String                   // human-readable, optional
    var enabled: Bool = true
    var match: Matcher                 // see below
    var target: Target                 // browser + profile + args
}

enum Matcher: Codable {
    case host(String)                  // "github.com" matches host or *.host
    case hostRegex(String)             // arbitrary regex on host
    case urlContains(String)           // substring on full URL
    case predicate(String)             // future: structured predicate language
}

struct Target: Codable {
    var browserBundleID: String        // e.g. "com.google.Chrome"
    var profile: String?               // e.g. "Default" for Chrome, "personal" for Firefox
    var extraArgs: [String] = []
    var openInNewWindow: Bool = false
}
```

### Persistence

- **Path:** `~/Library/Application Support/Junction/rules.json`
- **Format:** pretty-printed JSON, stable key ordering
- **Atomic writes:** write to `rules.json.tmp`, fsync, rename
- **Live reload:** `FSEventStream` on the file — external edits (`vim`, `finicky-learn`-style scripts) update the running app
- **Schema version:** top-level `"schemaVersion": 1` for future migrations

## URL receiving

Junction registers as a default browser via:

- `Info.plist`:
  - `CFBundleURLTypes` with `CFBundleURLSchemes`: `["http", "https"]`
  - `LSHandlerRank`: `Default`
- App delegate implements `application(_:open:options:)` for `[URL]`
- Also implement `NSApplicationDelegate.application(_:willPresentError:)` for diagnostic UX

## Browser detection

- Query Launch Services via `LSCopyApplicationURLsForURL(_, .all)` for `http://example.com`
- Filter results:
  - Exclude `Junction.app` itself (avoid loops)
  - Exclude non-browser apps that opportunistically claim `http` (e.g. Discord, Slack) — heuristic: check for known browser bundle IDs first, then offer "Add more apps" in settings
  - Honor user's "hide" list

Known browser bundle IDs to special-case (icons, profile detection):

| Bundle ID | Browser |
| --- | --- |
| `com.apple.Safari` | Safari |
| `com.google.Chrome` | Chrome |
| `com.google.Chrome.canary` | Chrome Canary |
| `com.brave.Browser` | Brave |
| `org.mozilla.firefox` | Firefox |
| `company.thebrowser.Browser` | Arc |
| `com.microsoft.edgemac` | Edge |
| `com.operasoftware.Opera` | Opera |
| `com.vivaldi.Vivaldi` | Vivaldi |
| `org.mozilla.LibreWolf` | LibreWolf |

## Profile detection per browser

| Browser | Profile source | Command-line flag |
| --- | --- | --- |
| Chrome / Brave / Edge / Vivaldi (Chromium) | `~/Library/Application Support/<Browser>/Local State` (`profile.info_cache`) | `--profile-directory=<dir>` |
| Firefox | `~/Library/Application Support/Firefox/profiles.ini` | `-P <profileName>` (or `--profile <path>`) |
| Safari | N/A (single profile in older versions; Safari 17+ supports profiles via `safari://` URL syntax — research needed) | TBD |
| Arc | Spaces, not profiles — TBD | TBD |

Profile detection runs once at app launch and on settings open; cached otherwise.

## URL rewriting

Optional pre-routing transforms, applied in order:

1. **Shortener expansion** — `t.co`, `bit.ly`, etc.: `HEAD` request, follow `Location` header (max 5 hops, 2s timeout). Off by default; opt-in per shortener.
2. **Tracking param strip** — remove `utm_*`, `fbclid`, `gclid`, etc. (configurable allowlist of *what to strip*).
3. **Custom rewrites** — user-defined regex find/replace.

All transforms are pure functions; the resulting URL is what gets matched against rules and opened.

## Picker window

- `NSWindow` with `.borderless` style, `.floating` level, ignores activation
- Click outside or `Esc` dismisses
- Layout: SwiftUI grid, 80×80pt browser tiles, label below each
- Hover: subtle background; focus ring on keyboard selection
- "Always" affordance:
  - Tile shows pin icon when `⌥` is held (live)
  - Status bar text: "⌥ to always open <domain> here"

## Signing & distribution

- Apple Developer ID Application certificate
- Hardened runtime + notarization
- Sparkle 2.x for auto-update (EdDSA signed appcasts)
- Homebrew cask in `homebrew-cask` (after a few minor releases) — until then, in a tap: `pkajaba/tap`
- Direct `.dmg` download from GitHub Releases

## Accessibility

- VoiceOver labels on every picker tile (browser name + "press to open once, hold Option for always")
- Full keyboard navigation, no required mouse interaction
- Respect Reduce Motion (no spring animations on picker show)
- Honor Increase Contrast (stronger borders, higher-contrast focus rings)
- Dynamic Type for settings labels (best-effort)

## Telemetry

**None.** No analytics, no crash reporting (until proven needed; if needed, Sentry-self-hosted only, opt-in).

## Future / out of v0.1

- Per-display picker positioning preferences
- Picker themes / custom CSS
- iCloud sync for rules
- CLI companion (`junction route <url>` for scripting)
- Workspace-aware routing (different rules per macOS Space / Focus mode)
- Tab grouping (open multiple links in one window/tabs)
