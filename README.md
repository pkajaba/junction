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

Two ways to manage rules:

1. **Settings UI** (`⌘,` or **Junction → Settings…**). The **Rules** tab has add / edit / delete, drag-to-reorder, a built-in "Test URL" field, and a per-rule enable toggle. The **Browsers** tab lets you hide unwanted browsers from the picker.
2. **Edit `~/Library/Application Support/Junction/rules.json`** directly. Junction watches the file and reloads automatically when you save (via FSEventStream). The **Reload Rules** menu item (`⌥⌘R`) is also available if you want to force a refresh.

You can also create a rule on-the-fly from the picker: when an unmatched URL pops the picker, hold **⌥ (Option)** while clicking a browser (or pressing a digit / Return). Junction saves a rule for that domain → that browser, so the next URL on the same domain skips the picker.

## URL rewriting

Junction strips common tracking parameters (`utm_*`, `fbclid`, `gclid`, `msclkid`, and friends) from every URL **before** rule matching. The browser receives the clean URL — no more "look at all this UTM cruft in my address bar". The full list lives in **Settings → Advanced**, where you can add domain-specific tracking params or disable the feature.

The rewrite is a pure value transform: no network requests, no logging, no analytics. Shortener expansion (following `t.co` / `bit.ly` redirects) is a planned post-v0.1 feature.

## Profile support

Per-browser profile launching is honored for:

| Browser family | How |
|---|---|
| **Chromium** (Chrome, Brave, Edge, Vivaldi, Opera, plus channels) | `--profile-directory=<dir>`. Profiles are detected by reading the browser's `Local State` JSON, so the rule editor shows real names like "Personal" or "vetrofibermap.com" instead of asking you to remember `Default` vs `Profile 1`. |
| **Firefox** (incl. Developer Edition, Nightly) | `-P <name>`. Profiles are read from `profiles.ini`. Note: the flag is most effective on cold launch — if Firefox is already running with a different profile, the OS may route the URL to that running instance instead. Pair with "Open in new window" if it matters. |
| **Safari / Arc** | Not yet — Safari 17+ profiles and Arc Spaces use different models; planned for after v0.1. |

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

Currently at M6 (URL rewriting + multi-browser profile support).

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
