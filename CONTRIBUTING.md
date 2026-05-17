# Contributing to Junction

Junction is in **pre-v0.1**: design decisions are being made every day and the codebase doesn't really exist yet. That means contribution shape is unusual for now.

## Where to help right now

1. **Read [SPEC.md](./SPEC.md) and push back on it.** Open an issue tagged `design` if you disagree with an architectural choice or see a gap. The cheapest fix is *before* code exists.
2. **Browser quirks.** If you use a browser not listed in the bundle-ID table, open an issue with the bundle ID and profile-storage location.
3. **macOS edge cases.** Multi-display, Spaces, Stage Manager, focus modes — if you have a setup that might break a picker window, mention it.

## When code exists (M1+)

1. Fork, branch from `main`, PR back.
2. Match the existing code style — we'll add `swift-format` config when there's enough code to format.
3. One logical change per PR. Refactors and feature changes go separately.
4. Tests: SwiftPM `XCTest`. Aim for unit tests on the rule engine and URL rewriter; UI tests are best-effort.
5. Commit messages: imperative ("Add Firefox profile detection"), no Conventional Commits requirement.

## Code of Conduct

Be decent. Don't be a jerk. If something feels off, email the maintainer (see `git log`) — we'll figure it out in private before any public action.

## Releases

Releases are signed `.dmg` files attached to GitHub Releases, plus a Homebrew cask. Maintainer-only for now. The release process will be documented in `RELEASING.md` when we're ready.

## Licensing

By submitting a PR you agree your contributions are MIT-licensed (same as the project). No CLA required.
