# Junction

A native, open-source browser router for macOS — pick the right browser for every link.

> **Status: pre-v0.1.** No usable binary yet. Currently in design and scaffolding phase. Watch the repo if you want to be notified when it's usable.

---

## Why does this exist?

macOS has a long history of "browser chooser" apps that intercept link clicks and route them to the right browser. The two best-known options have problems in 2026:

| App | Status |
| --- | --- |
| **[Browserosaurus](https://github.com/will-stone/browserosaurus)** | Discontinued. Cask deprecated, will be disabled 2026-08-30. |
| **[Velja](https://sindresorhus.com/velja)** | Actively maintained, but closed-source and rule features may sit behind a paywall. |
| **[Finicky](https://github.com/johnste/finicky)** | Open-source rule router (JS config), but no GUI picker for ambiguous URLs. |
| **[Choosy](https://www.choosyosx.com/)** | Closed-source, paid. |

**Junction** aims to be:

- Open source (MIT)
- Native macOS (Swift + SwiftUI / AppKit — no Electron)
- Both a **rule router** (Finicky-style) and a **picker** (Browserosaurus-style) in one app
- Distributed via signed/notarized Homebrew cask, no Mac App Store paywall
- Small (~10 MB binary, not 100+ MB)

## Planned features

- [ ] Register as default browser, receive `http://` / `https://` URL events
- [ ] Rule engine: domain / regex / URL-component patterns → browser + profile + args
- [ ] Picker window: grid of installed browser icons, keyboard-driven
- [ ] "Open once" vs "Always for this domain" — first-class affordance in the picker
- [ ] Chrome / Brave / Edge / Firefox profile selection
- [ ] URL rewriting (strip tracking params, unfurl shorteners)
- [ ] Settings UI: drag-to-reorder rules, hide unwanted browsers from picker
- [ ] Rules persisted in `~/Library/Application Support/Junction/rules.json` (text, git-friendly)
- [ ] Universal binary (Apple Silicon + Intel)
- [ ] Sparkle auto-updates
- [ ] Accessibility (VoiceOver, keyboard navigation, Dynamic Type where possible)

See [SPEC.md](./SPEC.md) for the architectural design.

## Roadmap

| Milestone | Description |
| --- | --- |
| **M0** | Repo + design docs (you are here) |
| **M1** | SwiftUI scaffold; app launches, registers as URL handler, logs received URLs |
| **M2** | Hardcoded routing — opens received URL in Safari |
| **M3** | Picker window — keyboard-navigable, opens chosen browser |
| **M4** | Rule engine with `rules.json` |
| **M5** | Settings UI |
| **M6** | URL rewriting, profile selection, edge cases |
| **M7** | Signing + notarization + Homebrew cask → v0.1 |

## Configuring rules

Junction reads rules from `~/Library/Application Support/Junction/rules.json`. On first launch it bootstraps an empty file there. A settings UI lands in **M5**; until then, edit the JSON directly and pick **Reload Rules** (`⌥⌘R`) from the menu to apply changes without restarting.

Example:

```json
{
  "schemaVersion": 1,
  "rules": [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "name": "GitHub → work Chrome",
      "enabled": true,
      "match": { "type": "host", "value": "github.com" },
      "target": {
        "browserBundleID": "com.google.Chrome",
        "profile": "Default",
        "extraArgs": [],
        "openInNewWindow": false
      }
    },
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "name": "Google Workspace",
      "enabled": true,
      "match": {
        "type": "hostRegex",
        "value": "^(mail|calendar|docs|drive|meet)\\.google\\.com$"
      },
      "target": {
        "browserBundleID": "com.google.Chrome",
        "profile": "Default",
        "extraArgs": [],
        "openInNewWindow": false
      }
    },
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "name": "Hacker News → Safari",
      "enabled": true,
      "match": { "type": "urlContains", "value": "news.ycombinator.com" },
      "target": {
        "browserBundleID": "com.apple.Safari",
        "extraArgs": [],
        "openInNewWindow": false
      }
    }
  ]
}
```

**Matchers:**

| Type | Behavior |
|---|---|
| `host` | Matches `value` exactly, **or** any subdomain of it. `"github.com"` matches `github.com`, `api.github.com`, etc. — but not `notgithub.com`. |
| `hostRegex` | Case-insensitive regex against the URL's host. Power tool. |
| `urlContains` | Case-insensitive substring against the full URL string. Use for path-based rules. |

**Targets:**

`browserBundleID` is required. `profile` is honored for Chromium browsers today (passed as `--profile-directory=<value>`); Firefox / Arc profile support arrives in **M6**. `extraArgs` are appended to the launch command. `openInNewWindow` requests a fresh app instance (useful for multi-window workflows).

Rules are evaluated **in order**. The first enabled match wins. If no rule matches, Junction shows the picker.

## Building from source

Currently at M4 (rule engine with picker fallback).

**Requirements:**

- macOS 13 Ventura or newer (deployment target; Junction itself develops on macOS 26)
- Xcode 15 or newer
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

**Build & run:**

```bash
git clone https://github.com/pkajaba/junction.git
cd junction
xcodegen generate          # writes Junction.xcodeproj from project.yml
open Junction.xcodeproj
# then ⌘R in Xcode
```

`Junction.xcodeproj` is generated from `project.yml` and **not** committed — that avoids the merge-conflict pain that plagues most Xcode projects. Run `xcodegen generate` whenever `project.yml` or the source tree changes.

## Contributing

Pre-v0.1, the codebase moves fast and breakage is constant. If you want to help shape the design, comment on issues tagged `design` or open one. Code contributions are welcome once M1 lands. See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

[MIT](./LICENSE) — same as Browserosaurus and Finicky. Fork freely, ship commercially, no obligations beyond keeping the copyright notice.

## Acknowledgements

Junction stands on the shoulders of [Browserosaurus](https://github.com/will-stone/browserosaurus) (Will Stone) and [Finicky](https://github.com/johnste/finicky) (Johannes Stenmark) — both of which proved this kind of tool can be loved. Junction's goal is to keep that experience alive natively and openly.
