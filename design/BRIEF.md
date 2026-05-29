# Junction — Design Brief

Reference document for getting good design feedback from Claude, designers, or
any other source. Paste relevant sections (the overview, then 1–2 surface
sections, then a screenshot) instead of dumping the whole file.

---

## TL;DR (paste this first)

**Junction** is an open-source macOS browser router. When you click a link
anywhere on macOS, Junction decides which browser opens it — silently if a
rule matches (e.g. `*.zoom.us → Chrome work profile`), or by popping a
keyboard-driven picker if not. Pre-v0.1, single developer, native Swift +
SwiftUI + AppKit, targeting macOS 14+ with full Liquid Glass on macOS 26.

It's the spiritual successor to two dead-or-paywalled tools:
[Browserosaurus](https://github.com/will-stone/browserosaurus) (discontinued)
and [Velja](https://sindresorhus.com/velja) (closed-source, paid). Sibling
in spirit to [Finicky](https://github.com/johnste/finicky) (rules-only, no
GUI).

Repo: https://github.com/pkajaba/junction

---

## Audience

Mac developers, designers, and knowledge workers who:

- Use **multiple browsers or browser profiles** (work Chrome, personal
  Safari, Firefox for testing, etc.)
- Want **link clicks routed correctly** without manually dragging URLs
  between browsers
- Care about keeping **work and personal browsing separate** without
  ceremony

Power-user-leaning, but everything should be discoverable without docs.

---

## Brand attributes

| Is | Isn't |
| --- | --- |
| Calm, professional, native | Loud, branded, web-app-styled |
| Trustworthy plumbing | Hero app you stare at all day |
| macOS-idiomatic | Cross-platform-compatible compromise |
| Open and inspectable (plain JSON config) | Black-box magic |

Visual aesthetic should feel like a 2026 Apple utility — alongside
Reminders, Shortcuts, Migration Assistant — not like an Electron SaaS
admin panel.

---

## Tech / platform constraints

- **Swift + SwiftUI + AppKit** (no Electron, no web views)
- **macOS 14+** deployment target; Liquid Glass via `.glassEffect()` on
  macOS 26+
- **SF Symbols** for all iconography (no custom icons inside the app)
- **System fonts only** (SF Pro Display / Text)
- **No external dependencies** today; Sparkle for auto-update later
- **Standard macOS Settings scene** (`⌘,`) — not a custom config window
- **Single binary**, ~10 MB
- Distributed via Homebrew cask (no Mac App Store)

---

## Surfaces (the screens that exist)

### 1. Picker window

The most-visible surface. Pops up when an unmatched URL arrives.

- Borderless `NSWindow`, floating level, centered on the active display
- Material: Liquid Glass on macOS 26, `regularMaterial` on 14/15
- Top: URL bar (monospaced, truncates middle)
- Middle: 4-column grid of browser tiles, each with icon + name + number
  badge (1–9) + pin button (top-right)
- Bottom: keyboard-hint footer (`1–N pick   ←→ move   ↩ open once   📌 always   esc cancel`)
- Selected tile: tinted accent border + filled background
- Hold ⌥: glow accent on outer border, "always for &lt;host&gt;" pill in URL bar

**Goals to improve:** visual hierarchy (default tile vs others), the URL
bar feels like an afterthought, pin button discoverability vs noise
balance.

### 2. Debug log window

Main app window. Shows every URL received and how it was routed.

- Standard `WindowGroup`, resizable
- Top header: rule count, entry count, Clear button
- List of entries: URL (mono, selectable), source (`openURL` / `AppleEvent`),
  timestamp, routing badge (`→ Chrome (rule: GitHub → work)`)
- Empty state: large `link.circle` SF Symbol + "Set Junction as your
  default browser" copy

**Goals to improve:** feels text-heavy, no grouping; this window may be
hidden by default in v1.0 and shown only on-demand.

### 3. Settings window

Standard macOS Settings (`⌘,`), three tabs:

- **Rules**: list of rules with status dot, name, matcher summary →
  target. Drag-to-reorder. Footer toolbar with `+ - ✎` and "Reveal
  rules.json". Double-click row or click pencil to edit (opens sheet).
- **Browsers**: detected browsers with icon, name, bundle ID, and a
  "Visible in picker" toggle each.
- **Advanced**: URL rewriter toggle ("Strip tracking parameters") and an
  editable list of parameters to strip (with add field + restore-defaults).

**Goals to improve:** the Rules list is flat; could group by target
browser (with disclosure). Empty states could be more inviting.

### 4. Rule editor sheet

Modal sheet for adding or editing a single rule. Form sections:

- **Identity**: name (text field), enabled (toggle)
- **Match**: type (picker: host / hostRegex / urlContains), value (mono
  text field). Invalid regex shows a live orange warning.
- **Target**: browser (picker of detected browsers), profile (text field
  or picker if Chromium/Firefox with detected profiles), "Open in new
  window" toggle.
- **Test**: paste a URL → live "Match" / "Does not match" indicator

Action bar: Cancel / Add-or-Save.

**Goals to improve:** form is dense; could break into a wizard or rely on
progressive disclosure. The "Test" section is brilliant but visually
underwhelming.

### 5. App icon

Slate gray vertical gradient + white `signpost.right.and.left` SF Symbol.
Functional placeholder; not a hero brand mark. Could be evolved.

---

## Existing visual references

| File | What |
| --- | --- |
| `design/icon-branch.svg` | **Source** for the shipped "Branch" icon — hand-drawn SVG |
| `design/icon_master_branch.png` | 1024×1024 render of the Branch icon (the asset-catalog source) |

(Earlier rejected explorations — a "J with junction kicker" SVG, a signpost
render, and three SF-Symbol candidates — were pruned from the repo but
remain in git history.)

Screenshots of the live UI live in `design/screenshots/` (you'll create
these as needed — see "Producing screenshots" below).

---

## Design goals (vague-to-specific)

In order of likely impact:

1. **Picker first-impression** — this is the only UI most users see
   regularly. Tile design and selection state could be more delightful.
2. **Settings → Rules** — flat list grows ugly fast at 20+ rules.
3. **Empty states** — Junction has good copy but stark visuals.
4. **Onboarding** — there is none. First-launch could explain "set
   Junction as your default browser" without nagging.
5. **App icon** — placeholder-quality; eventually wants a real brand mark.

## Non-goals

- **Custom typography** — system fonts only, always.
- **Animations beyond Apple's defaults** — respect Reduce Motion.
- **Themes / color customization** — light/dark from the system, that's it.
- **Branded launch screen** — Junction launches into the debug window or
  hides; there's no splash.
- **Marketing-style hero illustrations** — this is a utility, not a
  landing page.

---

## Producing screenshots (for design conversations)

The single most useful thing you can do when asking for design feedback is
**paste a screenshot of the current state alongside the brief section**.

Quickest path:

```bash
# Launch Junction (if not running already)
open /Applications/Junction.app

# To screenshot a single window (better than full screen):
#   1. Press ⌘⇧4
#   2. Press SPACE (cursor turns into a camera)
#   3. Click the window you want
#   4. PNG lands on Desktop

# Trigger the picker for screenshotting:
open "https://example.com/screenshot-the-picker"
# (this fires a URL with no rule match → picker appears → screenshot it)
```

Recommended set to keep in `design/screenshots/`:

- `picker.png` — picker with a few browsers
- `picker-option-held.png` — picker with ⌥ held (accent glow)
- `debug-log.png` — main window with a few entries
- `settings-rules.png` — Settings → Rules tab
- `settings-browsers.png` — Settings → Browsers tab
- `settings-advanced.png` — Settings → Advanced tab
- `rule-editor.png` — rule editor sheet

Keep them gitignored if they show personal URLs; or scrub them first.

---

## How to ask Claude (or any AI) for design help

A prompt that works:

```
I'm designing a [SURFACE] for a native macOS utility called Junction.
[paste TL;DR + relevant surface section from BRIEF.md]
[attach screenshot of current state]
Show me 3 distinct redesign directions. Constraints:
- Stay native macOS (SF Symbols, system fonts, standard materials)
- Aim for the visual tone of Linear, Raycast, or Apple's Reminders
- No web-app aesthetics, no Electron flat-design
- Keep keyboard-driven behavior intact
- Output: ASCII layout sketch first, then short paragraph per direction
```

Things that **don't** work:
- "Make it look better" (too vague)
- "Make it modern" (modern is everywhere; specify *which* modern)
- "Add some colors" (the brand is restrained)
- Asking for visual mocks without first nailing layout in text

For multiple iterations: in each round, paste the chosen direction back
in and ask for variations of *that* direction only. Cuts churn.

---

## A note on what's pre-v0.1

Junction is not shipped, not signed, not in Homebrew yet (waiting on M7 —
Apple Developer ID). This means:

- Polish is welcome but not blocking
- Anything controversial is reversible
- The brand can still shift; the only constraint is "feels native macOS"

This is the **best** window for design pushback because nothing is set in
stone. Use it.
