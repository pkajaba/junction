# AGENTS.md

Guidance for AI coding agents working in this repo. The detailed,
canonical guide is **[CLAUDE.md](./CLAUDE.md)** — read it before doing
anything substantive. This file is the quick card; it intentionally stays
in sync with CLAUDE.md, which wins on any conflict.

## What this is

Junction — a native macOS browser router (Swift + SwiftUI + AppKit, no
Electron, no web view, no external runtime dependencies). Click a link
anywhere → Junction routes it to the right browser/profile via rules, or
shows a keyboard-driven picker when no rule matches. Feature-complete and
in dogfooding (pre-v0.1).

## Build · test · lint

```bash
brew install xcodegen swiftlint     # one-time tooling
xcodegen generate                   # regenerate Junction.xcodeproj (it is NOT committed)
swiftlint --strict                  # must be clean — CI fails on any violation

# Run the test suite (111 XCTest cases):
xcodebuild -project Junction.xcodeproj -scheme Junction \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  test
```

Always run `xcodegen generate` after editing `project.yml` or adding/removing
a source file, then `swiftlint --strict` and the tests, before committing.

## Hard constraints — do not violate

- **No network calls, no telemetry, no analytics.** Junction is fully
  offline by design; the README and SPEC promise this. URL transforms
  (`URLRewriter`, `AppHandoff`) are pure, local, synchronous functions.
- **No new runtime dependencies.** Apple frameworks only — no SPM packages.
- **Keep `swiftlint --strict` green.** Notable budgets: `file_length` 600
  (warn), `type_body_length` 350, and `large_tuple` warns at 3+ member
  tuples — prefer a small struct once you'd reach for a 3-tuple.
- **Don't commit `Junction.xcodeproj`** (generated) or build artifacts.
- **Security posture:** never shell out / use `Process`, `system`,
  `NSAppleScript`, or `eval` to launch browsers — use `NSWorkspace.open`
  with `configuration.arguments` (array args, never a shell string). The
  scheme guard in `Router.swift` rejects non-`http(s)` URLs before routing;
  keep it.

## Architecture in one line

`AppDelegate` (receive URL) → `URLLog` (record) → `Router` (scheme guard →
`URLRewriter` → `AppHandoff` → `RuleEvaluator` → picker) → `NSWorkspace`
(open). Everything is `@MainActor`; the matchers/transforms/evaluator are
pure and unit-tested. See CLAUDE.md for the full file map.

## Commits

Imperative subject under ~70 chars; details in the body. Include the
trailer `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` for
agent-made changes. Branches: `feat/<topic>`, `fix/<topic>`,
`docs/<topic>`. One logical change per PR.
