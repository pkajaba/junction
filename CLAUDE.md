# CLAUDE.md

Junction is a native macOS browser router. URLs go through rules → a picker
when no rule matches → the chosen browser. Pre-v0.1, single developer, no
external runtime deps.

Read this whole file before doing anything substantive. It's short on
purpose; everything below is something a fresh session would otherwise have
to discover the hard way.

## Stack

- **Swift + SwiftUI + AppKit** (no Electron, no web view)
- **macOS 14+** deployment target (`.glassEffect()` Liquid Glass on macOS 26)
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
Sources/Junction/              # All app source
├── JunctionApp.swift          # @main, scenes
├── AppDelegate.swift          # URL receiving (both modern + Apple Event)
├── PickerController.swift     # Borderless picker window lifecycle
├── PickerView.swift           # Picker UI
├── RulesSettingsView.swift    # Settings → Rules tab (two-pane)
├── RuleEditorView.swift       # Inline editor in the right pane
├── HostChipMatcher.swift      # regex ↔ chip list conversion
├── Router.swift               # The dispatcher
├── RuleStore.swift            # rules.json persistence + FileWatcher
├── ...                        # everything else is named what it is
└── Assets.xcassets/           # AppIcon lives here

Tests/JunctionTests/           # XCTest suite — 34 tests, ~24ms
design/                        # Icon SVG, render scripts, design handoff
  ├── render_icon.swift        # SF Symbol → PNG renderer
  ├── set_default_browser.swift  # bypass for ad-hoc-signing's default-browser limitation
  ├── icon-branch.svg          # current icon source
  ├── BRIEF.md                 # what to paste into Claude for design work
  └── handoff/                 # design handoff zip contents
.github/workflows/             # CodeQL + tests CI
```

User runtime data:

- Rules: `~/Library/Application Support/Junction/rules.json`
- Default-browser status: `defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep junction`

## Branch conventions

- **`main`** — release branch. Linear history enforced; no force-push, no
  deletion. Direct push allowed (no PR review required since solo).
- **`polish/<topic>`** — small standalone changes (icon, polish, single
  feature). Squash-merged into main.
- **`redesign/<name>`** — branches for the Claude Design handoff redesign.
  Each phase has its own branch (`redesign/icon-branch`,
  `redesign/picker-v2`, `redesign/rules-two-pane`).
- **`redesign/all`** — the kitchen-sink combination branch for dogfooding.
  Not for PR; merge target for all three redesign branches.
- **`chore/<topic>`** — non-feature cleanup work.

PRs are open but not blocking — branch protection requires linear history
on main but not reviewers. The user merges via gh CLI when ready
(`gh pr merge N --squash --delete-branch`).

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

### macOS 26 Liquid Glass APIs

`Glass.regular`, `.glassEffect(_:in:)`, etc. exist only on macOS 26+. Guard
with `if #available(macOS 26.0, *)`. Helpers in `GlassEffect.swift` on
the polish/liquid-glass branch (open PR #7 at time of writing).

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

- **README.md** — user-facing description, install steps. Polish for
  sharing is task #29 (still pending at time of writing).
- **SPEC.md** — full technical design.
- **design/BRIEF.md** — what to paste into Claude when asking for design help.
- **GitHub Issues** — feature backlog. #10 native-app handoff, #11 default-set quirk, #13 Safari profiles.

## Commit style

Imperative subject under 70 chars. Body in detail (multiple paragraphs ok).
Always include the trailing `Co-Authored-By: Claude Opus 4.7
<noreply@anthropic.com>` line for changes made via Claude. Author identity
is `Pavel Kajaba <pavel.kajaba@icloud.com>` for this repo specifically
(local git config override; global stays as work email).
