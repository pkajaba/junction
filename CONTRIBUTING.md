# Contributing to Junction

Junction is **feature-complete and in dogfooding** (pre-v0.1 — the only
remaining milestone is signing/notarization + a Homebrew cask). The code is
small, native (Swift/SwiftUI/AppKit), and has no external runtime
dependencies. Contributions are welcome.

## Where to help right now

1. **Browser quirks.** If you use a browser not in the detected list, open
   an issue with its bundle ID and where it stores profiles. Profile
   detection lives in `ProfileDetector.swift`; the launch-arg quirks are in
   `Router.swift`.
2. **macOS edge cases.** Multi-display, Spaces, Stage Manager, Focus modes
   — anything that might break the borderless picker window.
3. **Native-app handoff targets.** New apps to hand URLs off to (à la Zoom)
   go in `AppHandoff.swift` with a URL transform + a test in
   `AppHandoffTests.swift`.
4. **Push back on the design.** Open an issue tagged `design` if an
   architectural choice seems wrong. [SPEC.md](./SPEC.md) is the original
   design doc; [CLAUDE.md](./CLAUDE.md) describes the codebase as it
   actually is today.

## Development setup

```bash
git clone https://github.com/pkajaba/junction.git
cd junction
brew install xcodegen swiftlint   # build tooling
xcodegen generate                 # writes Junction.xcodeproj from project.yml
open Junction.xcodeproj           # ⌘R to run, ⌘U to test
```

`Junction.xcodeproj` is generated and **not** committed — re-run `xcodegen
generate` after editing `project.yml` (e.g. adding a file or build
setting). [CLAUDE.md](./CLAUDE.md) is the fastest orientation to the
codebase layout and the macOS gotchas (ad-hoc signing, Launch Services
duplicates, etc.).

## Making a change

1. Fork, branch from `main` (`feat/<topic>` or `fix/<topic>`), PR back.
2. **One logical change per PR.** Refactors and feature changes go
   separately.
3. **Match the existing style.** `swiftlint --strict` runs as a build-time
   script and in CI — config in [`.swiftlint.yml`](./.swiftlint.yml). A PR
   that fails lint won't go green. (We use SwiftLint, not swift-format.)
4. **Tests** use XCTest in the `JunctionTests` target (111 and counting).
   Run them with `⌘U` in Xcode or:
   ```bash
   xcodebuild -project Junction.xcodeproj -scheme Junction \
     -destination 'platform=macOS' \
     CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
     test
   ```
   Aim for unit coverage on the rule engine, URL rewriter, matchers, and
   handoff transforms (they're pure functions and easy to test). UI tests
   are best-effort.
5. **Commit messages**: imperative subject ("Add Firefox profile
   detection"), under ~70 chars, details in the body. No Conventional
   Commits requirement.

CI (GitHub Actions) runs the test suite, SwiftLint, and CodeQL on every PR.

## Code of Conduct

Be decent. Don't be a jerk. If something feels off, email the maintainer
(see `git log`) — we'll figure it out in private before any public action.
See [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

## Releases

Releases will be signed `.dmg` files attached to GitHub Releases, plus a
Homebrew cask. Maintainer-only, and gated on an Apple Developer ID (the
final pre-v0.1 milestone). The release process will be documented in
`RELEASING.md` when it's set up.

## Licensing

By submitting a PR you agree your contributions are MIT-licensed (same as
the project). No CLA required.
