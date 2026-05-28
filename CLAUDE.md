# CLAUDE.md

Junction is a native macOS browser router. URLs go through rules → a picker
when no rule matches → the chosen browser. Feature-complete and in
dogfooding (pre-v0.1 — only signing/notarization + a Homebrew cask remain).
Single developer, no external runtime deps.

Read this whole file before doing anything substantive. It's short on
purpose; everything below is something a fresh session would otherwise have
to discover the hard way.

## Stack

- **Swift + SwiftUI + AppKit** (no Electron, no web view)
- **macOS 14+** deployment target. Picker chrome is an `NSVisualEffectView`
  blur (`.hudWindow`), which the system renders with Liquid Glass on macOS
  26 automatically — there is **no** `.glassEffect()` call or version-gated
  code path.
- **Menu-bar agent** — `LSUIElement` (no Dock icon); activation policy
  flips to `.regular` only while Settings is open. There is no SwiftUI
  `Settings {}` scene (it won't open for an `LSUIElement` app) — Settings
  is a hand-built `NSWindow` + `NSToolbar`, see `SettingsWindowController.swift`.
- **XcodeGen** generates `Junction.xcodeproj` from `project.yml` — the .xcodeproj is **not** committed
- **No SPM / no external runtime dependencies** — only Apple frameworks
- **SwiftLint** runs as a build-time preBuildScript; config in `.swiftlint.yml`
- **XCTest** for unit tests, target `JunctionTests`

## Building & dogfooding

The full rebuild-and-deploy-to-/Applications sequence is automated — call
the `dogfood` skill. Manual recipe in `.claude/skills/dogfood.md` if you
need to run it by hand.

Bare minimum to build for inspection (not deploy):

```bash
xcodegen generate
xcodebuild -project Junction.xcodeproj -scheme Junction -configuration Debug \
  -derivedDataPath build/derived \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

The signing flags are necessary because Junction is ad-hoc-signed for
local dev. A proper Developer ID is the M7 milestone (open).

## Repo layout

```
Sources/Junction/              # All app source (~7k LOC, 38 files)
│  # ── Lifecycle / URL intake ────────────────────────────────
├── JunctionApp.swift          # @main
├── AppDelegate.swift          # URL receiving (modern open + kAEGetURL Apple Event)
├── MenuBarController.swift    # NSStatusItem menu; activation-policy flips
├── LoginItemSettings.swift    # launch-at-login via SMAppService
│  # ── The routing pipeline (pure where possible) ────────────
├── Router.swift               # The dispatcher: scheme guard → rewrite → handoff → rules → picker
├── URLRewriter.swift          # Tracking-param strip (glob → regex). Pure.
├── AppHandoff.swift           # Native-app handoff URL transforms (Zoom, …). Pure.
├── RuleEvaluator.swift        # Matches a URL (+ source app) against rules. Pure.
├── Rule.swift                 # Rule / Matcher / Target models + Codable (+ legacy migration)
├── HostChipMatcher.swift      # Matcher ↔ host-chip list conversion (for the editor)
├── RuleStore.swift            # rules.json persistence + live reload via FileWatcher
├── FileWatcher.swift          # DispatchSource watch on the *parent dir* (survives atomic rename)
│  # ── Browser / profile / source-app detection ──────────────
├── BrowserDetector.swift      # Launch Services query + manual/extra/hide lists
├── ProfileDetector.swift      # Chromium Local State + Firefox profiles.ini parsing
├── ManualBrowserList.swift    # user-added browsers (UserDefaults)
├── BrowserHideList / BrowserExtraList / SourceAppList.swift
│  # ── Picker ─────────────────────────────────────────────────
├── PickerController.swift     # Borderless panel lifecycle
├── PickerView.swift           # Picker UI + NSVisualEffectView bridge
│  # ── Settings (NSWindow + NSToolbar, one view per tab) ──────
├── SettingsWindowController.swift  # window/toolbar + SettingsCoordinator (cross-tab)
├── RulesSettingsView.swift / RuleEditorView*.swift / RulesSidebarRows.swift / RulesGrouping.swift
├── BrowsersSettingsView.swift / HandoffSettingsView.swift / AdvancedSettingsView.swift
├── *Settings.swift            # Appearance / Rewriter / AppHandoff / LoginItem prefs (UserDefaults)
│  # ── Activity log ───────────────────────────────────────────
├── URLLog.swift               # Observable log, JSONL persistence (Application Support)
├── DebugLogView.swift / ActivityRow.swift   # Activity tab UI
├── ActivitySuggestions.swift  # "N× this week → Browser" pill + "Make it a rule?" banner. Pure + dismissal store.
└── Assets.xcassets/           # AppIcon lives here

Tests/JunctionTests/           # XCTest suite — 111 tests across 7 files:
  # RuleEvaluator 32 · AppHandoff 18 · RuleCodable 17 · URLRewriter 14 ·
  # HostChipMatcher 13 · ActivitySuggestions 12 · URLLogCodable 5
design/                        # Icon SVG, render scripts, design handoffs
  ├── render_icon.swift        # SF Symbol → PNG renderer
  ├── set_default_browser.swift  # bypass for ad-hoc-signing's default-browser limitation
  ├── icon-branch.svg          # current icon source
  ├── BRIEF.md                 # what to paste into Claude for design work
  ├── handoff/                 # first design handoff
  └── handoff_round2/          # Round 2 handoff (Activity, sidebar, Handoff, Browsers, Advanced)
.github/workflows/             # CodeQL + Test (xcodebuild) CI
```

User runtime data:

- Rules: `~/Library/Application Support/Junction/rules.json`
- Default-browser status: `defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep junction`

## Branch conventions

- **`main`** — release branch. Linear history enforced; no force-push, no
  deletion. Direct push allowed (no PR review required since solo).
- **`feat/<topic>`** — new features (`feat/launch-at-login`,
  `feat/activity-suggestion-counter`, …). One logical change per branch.
- **`fix/<topic>`** — bug fixes.
- **`docs/<topic>`, `chore/<topic>`** — docs and non-feature cleanup.

PRs are open but not blocking — branch protection requires linear history
on main but not reviewers. The user merges via gh CLI when CI is green
(`gh pr merge N --rebase --delete-branch`; `--squash` also works since both
keep history linear).

**Stacked PRs:** when a branch is based on another open branch, retarget
the downstream PR's base to `main` *before* merging the upstream one —
otherwise GitHub auto-closes it. Then rebase + `--force-with-lease`.

## Common gotchas (in order of how much time they've cost)

### Ad-hoc signing blocks the System Settings dropdown

macOS Sonoma+ filters the "Default web browser" dropdown to apps with a
proper Developer ID. Ad-hoc-signed dev builds (i.e., what we make) won't
appear — even though they're properly registered as URL handlers.

Workaround: `swift design/set_default_browser.swift /Applications/Junction.app`.
That calls `NSWorkspace.setDefaultApplication` directly, which bypasses the
UI filter. Same script can flip back to other browsers by bundle ID.

### Multiple Junction.app copies confuse Launch Services

Every `xcodebuild build` writes a fresh `.app` to `build/derived/...`,
and Xcode IDE builds write one to `~/Library/Developer/Xcode/DerivedData/`.
Each one registers itself as an HTTP handler on first run. macOS gets
confused when there are duplicate bundle IDs in LaunchServices.

Mitigations already in place:
- `~/Projects/junction/build/.metadata_never_index` — Spotlight skips this dir
- `~/Library/Developer/Xcode/DerivedData/.metadata_never_index` — same for DerivedData
- The dogfood skill deletes the dev copy after copying to /Applications.

If duplicates show up anyway: use `lsregister -u <path>` to unregister, then
delete the file.

### Picker blur is NSVisualEffectView, not `.glassEffect()`

The picker chrome is an `NSVisualEffectView` with the `.hudWindow` material
(`VisualEffectBackground` in `PickerView.swift`). On macOS 26 the system
composites that material with Liquid Glass for free — so we get the look
without calling the macOS 26-only `.glassEffect(_:in:)` API or branching on
`#available(macOS 26.0, *)`. If you ever do reach for those APIs, guard
them; right now the codebase calls **no** macOS 26-only API.

### XcodeGen requires regeneration after project.yml changes

Adding a target, a build setting, or a resource path means running
`xcodegen generate` before `xcodebuild`. Forgetting causes confusing
"resource not found" / "target missing" errors.

### Swift 6 strict concurrency on `ImageRenderer`

`ImageRenderer.nsImage` is `@MainActor`-isolated. CLI scripts can't reach it
from top-level code without `MainActor.assumeIsolated`. We worked around
this in `design/render_icon.swift` by using AppKit `NSImage.lockFocus`
directly instead of SwiftUI's `ImageRenderer`. Lesson: AppKit drawing is
the right tool for one-shot scripts.

### Retina backing on `NSImage.lockFocus`

A "1024×1024" `NSImage` saves as **2048×2048 pixels** on Retina Macs
because of the default 2× backing scale. Always `sips -z 1024 1024` after
rendering to normalize before placing into the AppIcon appiconset.

## Toolchain in use

- Xcode 26.5 (macOS 26 SDK)
- xcodegen via Homebrew
- swiftlint via Homebrew
- librsvg via Homebrew (for SVG → PNG in icon pipeline)
- gh CLI authed as @pkajaba

## What's a "milestone"?

M1–M6 are merged. M7 (sign + notarize + ship via Homebrew cask) is open
and blocked on the user getting an Apple Developer ID. The redesign work
isn't numbered — it's the Claude Design handoff retrofit. See
`design/handoff/` for the brief.

## What's tracked elsewhere

- **README.md** — user-facing description, install steps, feature list.
- **SPEC.md** — the *original* pre-code design doc. Useful for intent, but
  some of it is aspirational (shortener expansion, Sparkle auto-update,
  CLI) and never shipped — trust this file + the code for current state.
- **design/BRIEF.md** — what to paste into Claude when asking for design help.
- **GitHub Issues** — remaining backlog: #11 (https-only default-set
  quirk), #13 (Safari profiles, blocked on Apple API). Native-app handoff
  (#10) shipped but the issue is kept open as the tracking umbrella.

## Commit style

Imperative subject under 70 chars. Body in detail (multiple paragraphs ok).
Always include the trailing `Co-Authored-By: Claude Opus 4.7
<noreply@anthropic.com>` line for changes made via Claude. Author identity
is `Pavel Kajaba <pavel.kajaba@icloud.com>` for this repo specifically
(local git config override; global stays as work email).
