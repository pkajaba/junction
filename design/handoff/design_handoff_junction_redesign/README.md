# Handoff: Junction Redesign

## Overview

Junction is a macOS browser-router app — when you click a link, it picks which browser (and which browser profile) to open the link in based on user-defined rules, and prompts the user with a picker when no rule matches.

This handoff covers a redesign of three surfaces:

1. **Picker** — the panel that appears when no rule matches. Includes a learned-default "Smart suggestion" mode and a "Suggestions off" fallback.
2. **Rules + Editor** — a settings tab that combines a grouped sidebar list of rules with an inline editor in a right pane. The editor uses a visual host-chip matcher (no regex by default).
3. **App icon** — a new direction (Branch) to replace the current shipped Signpost icon.

The redesign is grounded in research of existing browser-router apps (Velja, Choosy) and follows their convention of host-list-style matching rather than regex.

## About the Design Files

The files in the `designs/` folder are **design references created as a React + HTML prototype** (rendered in-browser with Babel). They are not production code to copy directly. The React components in there use inline styles and hand-rolled "mac-ish" controls (`MacToggle`, `MacCheck`, etc.) so the prototype can render anywhere without a build step.

**The task is to recreate these designs in Junction's real codebase** — which is a native macOS Swift/SwiftUI app (the design references `render_icon.swift` in `JBRAND` comments and the app's settings shell is SwiftUI-style). Use the codebase's existing SwiftUI controls (`Toggle`, `Picker`, `Form`, `List`, etc.), `NSVisualEffectView` for the glass material on the picker, and the codebase's established type/color tokens. Do not transliterate the React/JSX — re-implement the *visual and interaction design* the prototype communicates, in SwiftUI.

If the target is a different stack (e.g. AppKit, or a cross-platform shell), pick the most appropriate native primitives there — but **preserve the visual fidelity**, especially the picker's Liquid-Glass treatment and the chip-based matcher.

## Fidelity

**High-fidelity.** The prototype represents final colors, layouts, spacing, type sizes, and key interactions. Recreate the screens pixel-close using SwiftUI's native materials and controls. Exact spacing/padding values are listed below per-screen, and the design tokens at the bottom of this doc list every color and font used.

The one place fidelity is deliberately *not* pixel-perfect is the macOS chrome itself (window traffic lights, settings sidebar). The HTML uses hand-drawn approximations — replace with real `NSWindow` / `NSToolbar` / `NSSplitView` chrome.

## Screens / Views

### 1. Picker — Smart Suggestion (default)

**Purpose:** When the user clicks a link that no rule matches, Junction shows this floating panel so they can choose where to open it. The Smart Suggestion mode learns from history — if you usually open `news.ycombinator.com` in Chrome (Work), it pre-selects that and offers a one-click "Always" button to convert the click into a saved rule.

**Layout:**

- Floating panel, **560 px wide**, centered over the user's current desktop, with a **26 px corner radius**.
- Top-to-bottom sections (no fixed height — content drives it):
  1. **URL bar** — 14 px vertical / 18 px horizontal padding. Favicon glyph (18 px) + `host` bold / `/path` muted, in monospace (12.5 px).
  2. **Suggestion section** — 16/18/14 px padding. Tiny accent-blue "Junction suggests" header with a sparkle icon (11 px, uppercase, letter-spacing 0.6), then the suggestion card (see below).
  3. **"Or open in" section** — 0/18/12 px padding. Tiny gray uppercase header, then either one wide button (1 alternate), a row of equal-flex cards (2–3 alternates), or a grid (4+).
  4. **Keyboard footer** — 8/18 px padding. Inline list of shortcuts: `1-N pick · ↑↓ move · ↩ open · ⌥↩ always · esc cancel`.

**Panel material (Liquid Glass):**

- Background: `linear-gradient(180deg, rgba(255,255,255,.38) 0%, rgba(255,255,255,.18) 60%, rgba(255,255,255,.22) 100%)` — a top-to-bottom translucency curve that gives a subtle sheen at the top edge.
- `backdrop-filter: blur(60px) saturate(200%) brightness(108%)` — strong enough that the desktop wallpaper visibly refracts.
- Border: `0.5px solid rgba(255,255,255,.55)` — a thin highlight edge.
- Shadow: drop shadow `0 40px 80px rgba(20,40,30,.38)` + inset top `0 2px 0 rgba(255,255,255,.22)` + inset bottom `0 -1px 0 rgba(0,0,0,.04)` + hairline `0 0 0 0.5px rgba(0,0,0,.04)`.
- In SwiftUI, this is `NSVisualEffectView` with `.material = .hudWindow` (or `.popover`) plus an overlay gradient for the sheen.

**Suggestion card (the inner blue-tinted card):**

- 14 px padding, 16 px corner radius, 14 px gap between icon and text.
- Background: `linear-gradient(180deg, rgba(255,255,255,.55), rgba(255,255,255,.25))`, its own `backdrop-filter: blur(20px) saturate(160%)`.
- 0.5 px white border (`rgba(255,255,255,.5)`), inner shadow `inset 0 1px 0 rgba(255,255,255,.6)`, outer drop shadow `0 4px 14px rgba(30,109,255,.12)`.
- Browser icon: **56 px** square.
- Title: "Chrome · Work" — `15 px / 600` weight, " · Work" rendered as a muted middle dot followed by 70%-opacity dark text. The browser name and profile name are split conceptually but render as one line.
- Subtitle: "You opened **news.ycombinator.com** here 7 of the last 9 times" — 11.5 px, `rgba(0,0,0,.65)`, 2 px margin-top.
- **Two buttons on the right**, 6 px gap:
  - **Primary "Open"** — `1e6dff` background, white text, 8 px radius, 7/12 padding, 12.5 px / 600. Includes a `↩` keycap inset on the right with `rgba(255,255,255,.22)` background. Shadow: `0 2px 8px rgba(30,109,255,.35), inset 0 1px 0 rgba(255,255,255,.25)`.
  - **Secondary "Always"** — `rgba(255,255,255,.55)` glass background with its own `blur(20px)`, 0.5 px white border (`rgba(255,255,255,.6)`), 12.5 px / 600 black text. A 11 px `pin` SF Symbol on the left. This is the **most important UX choice in the redesign** — make sure it is visually equal-weighted to "Open" so users immediately discover that they can promote the suggestion to a saved rule with one click.

**"Or open in" — single-alternate card** (the layout that appears when the user has only 2 browsers installed):

- Full-width button, 10/14 px padding, 14 px corner radius.
- Glass: `rgba(255,255,255,.4)` background, `blur(20px) saturate(150%)`, 0.5 px white border, inset top highlight.
- Browser icon 36 px, name 13.5 px / 600, a single `2` keycap on the right.

**"Or open in" — 2-3 alternates:** flex-row of equally-flexed cards, same glass treatment, 9/12 padding, 12 px radius, 28 px browser icon, name 12.5 px / 600, keycap `2`, `3`, …

**"Or pick another" — 4+ alternates:** grid of icon tiles (no card chrome), number in the top-left corner (9.5 px / 600 muted), 32 px icon, name below (10 px / 600 muted, ellipsis-truncated at 56 px).

**Footer keyboard shortcut row:**

- `rgba(255,255,255,.18)` background bar, 8/18 padding, 0.5 px top divider, 11 px text in `rgba(0,0,0,.6)`.
- Each hint is `<keycap> label` — keycaps are 11px / 600 in a 0.5px border 6px radius pill (3px horizontal padding, white background, 90% opacity).
- Shortcuts (in order): `1-N` pick · `↑↓` move · `↩` open · `⌥↩` always · spacer · `esc` cancel.

**Behavior:**

- `1`–`N` digit keys: open in that numbered browser immediately.
- `↑`/`↓`: cycle selection (the highlighted row in the alternates).
- `↩`: open in the currently-highlighted browser (which is the suggested one initially).
- `⌥↩`: open AND promote to a saved rule (same as clicking "Always").
- `⌘.`: turn off smart suggestions for this session (toast or quiet inline confirmation).
- `esc`: dismiss without opening anything.

**Interactions:**

- The "Always" button, when clicked, generates a rule `host = <host of clicked URL>` → `<suggested browser> (<profile if set>)`, persists it, and the next time a link from this host is clicked the picker never appears.
- The Smart-Suggestion logic itself is out of scope for the design — but the data model is "track the last N picks per host, suggest the mode if >50% confident."

### 2. Picker — Suggestions Off (fallback)

**Purpose:** What the user sees if they turn off smart suggestions in Settings → General. Functionally identical to the original shipped picker, but with the redesigned glass chrome and keyboard footer.

**Layout:**

- Same outer panel (560 px / 26 px radius / Liquid Glass material / keyboard footer).
- URL bar gets an additional "no rule match" badge on the right — 10.5 px / 500 muted text, 2/7 padding, 4 px radius, `rgba(255,255,255,.4)` glass background.
- Body is a vertical list, not a grid. 10/10/14 padding.
- Each row: 10/12 padding, 12 px corner radius, 12 px gap.
  - 36 px browser icon
  - Name (14 px / 600) + optional ` · Work` profile suffix (500 weight, 60% opacity black)
  - "DEFAULT" eyebrow tag below the name on the first item (10.5 px / 600, uppercase, letter-spacing 0.4)
  - Keycap on the right (1, 2, 3…)
- **Selected row** uses a saturated blue gradient: `linear-gradient(180deg, rgba(30,109,255,.85), rgba(30,109,255,.95))` with a glow shadow `0 2px 10px rgba(30,109,255,.3), inset 0 1px 0 rgba(255,255,255,.25)`. The default row is selected by default.

### 3. Rules + Editor — Grouped Two-Pane with Visual Matcher

**Purpose:** This is the Settings → Rules tab. The user lands here to add, edit, reorder, enable/disable rules. The old design opened a modal sheet when editing a rule; the new design uses a two-pane split so the editor is always visible, with a live URL tester.

**Window:**

- Standard `NSWindow` Settings shell with traffic-light close/min/max + centered "Junction · Settings" title.
- Left rail is the existing Settings sidebar (General / **Rules** / Browsers / Advanced / About) — 200 px wide, system-styled.
- Main content area: a split view with **300 px sidebar** + flexible-width right pane.

**Left pane — grouped rule list:**

- Header (14/14/8 padding):
  - Title "Rules" (16 px / 600), subtitle "`<n>` rules · grouped by destination" (11 px muted, 2 px margin-top).
  - Search field — 5/8 padding, 6 px radius, `rgba(0,0,0,.05)` background, 11 px search icon (45% black), 12 px placeholder "Filter all rules".
- Scroll area: groups, each consisting of:
  - **Group header** — 6/12/6/10 padding, no background. 9 px chevron + 14 px browser icon + group name (12.5 px / 600) + flex-spacer + small rule count (10.5 px / 600 / 40% black, tabular-nums).
  - **Rule rows** — 7/10/7/22 padding (left padding pushes them past the group header indent), 6 px corner radius, 1 px bottom margin.
    - 6 px circle dot at absolute left 10/center — green `#34a853` when enabled, 25% black when disabled.
    - Name 12.5 px / 500, ellipsis-truncated.
    - Below name: matcher pattern in monospace 10.5 px (50% black), ellipsis-truncated.
    - If the rule has a profile and isn't the only Chrome rule in the group: a small profile chip on the right (9.5 px / 600, 1/5 padding, 3 px radius, `rgba(0,0,0,.05)` background, 55% black text — e.g. "Work").
  - **Selected row** uses solid `#1e6dff` background with white text. The status dot becomes white, the matcher pattern goes to 70% white, the profile chip goes to `rgba(255,255,255,.18)` background / 85% white.
- Disabled rules render at **0.55 opacity** so the whole row reads as dimmed.
- Bottom toolbar of the left pane: 8 px padding, 4 px gap. `+` and `−` icon buttons (26×22, 5 px radius, transparent), spacer, then a "📄 rules.json" button (default style) that opens the JSON file in Finder.

**Right pane — inline editor:**

- 22 px padding. Vertical scroll if content exceeds the height.
- **Header row** (mb 18):
  - Inline-editable rule name (19 px / 600, transparent background, no border) — clicking puts it into edit mode.
  - Right-aligned: "Enabled" label (11 px / 55% black) + `MacToggle` (size 0.85).
- **Three sections**, each with:
  - Uppercase header (11 px / 700, 55% black, letter-spacing 0.6, mb 8).
  - Card body: 12/14 padding, 10 px radius, `rgba(0,0,0,.025)` background, 0.5 px border `rgba(0,0,0,.06)`, 18 px bottom margin.

#### Section A — "When a link goes to"

The visual matcher. Top half: a flexible wrap of host chips + an "Add host" dashed-border placeholder button.

**Host chip:** `inline-flex`, 6 px gap, 4/6/4/8 padding (more left padding for the leading favicon), 7 px corner radius. White background, 0.5 px border `rgba(0,0,0,.18)`, subtle shadow `0 1px 2px rgba(0,0,0,.04)`. Body: 12 px favicon (`HostGlyph` — a colored circle with the host's first letter), then the host text in **monospace** 12 px / 500, then a 14×14 px `×` button (9 px X icon, 50% black, 7 px radius hover state).

**Add-host button:** 4/9 padding, 7 px radius, `rgba(0,0,0,.03)` background, 0.5 px **dashed** border `rgba(0,0,0,.22)`, plain font 12 px / 500 / 65% black, with a 10 px `+` icon on the left.

Bottom half (below a 0.5 px divider, 10 px gap above):

- **Checkbox "Include subdomains"** — 7 px gap, 12.5 px label. Label format: **"Include subdomains"** (500 weight) followed by " — so `m.mail.google.com` matches too" (regular weight, 45% black, the code span in monospace 11 px). Checked by default.
- **Checkbox "Only if the URL contains [path input]"** — 7 px gap. The path input is a 140 px-wide inline `<input>` with monospace placeholder `e.g. /mail/u/0`, 2/8 padding, 5 px radius, 0.5 px border, white background.
- **Disclosure "Edit as regex (advanced)"** — collapsed by default. Summary is a 11.5 px / 55% black inline-flex with a 9 px chevron. When expanded (14 px left indent), shows a `CodeInput` (white box, 0.5 px border, monospace 12.5 px, `overflow-wrap: anywhere`, `word-break: break-all` so long regex wraps) containing the compiled regex (e.g. `^(mail|calendar|docs|drive|meet)\.google\.com$`), followed by a hint that switching to raw mode disables the chips.

**Behavior:**

- Typing a host into "Add host" and pressing `↩` or `,` or `space` commits the chip.
- "Include subdomains" controls whether the compiled regex becomes `^(...)$` (off) or `(^|\.)(...)$ ` (on).
- The chip list and the regex are **two views of the same data**. Editing the regex disables the chips and shows the raw mode. If the regex is later determined to be a simple list of hosts (matches the pattern `^(host1|host2|...)$`), offer a button to convert back.

#### Section B — "Open it in"

A small two-row form + a checkbox:

- Row 1: "Browser" label (12 px / 60% black, fixed 64 px width) + a `BrowserPickerInline` dropdown (4/8/4/6 padding, 6 px radius, white, 0.5 px border, 13 px / 500 text, 18 px browser icon, chevron-down on the right).
- Row 2: "Profile" label + a `ProfileDropdown` (same chrome, with an 8 px colored circle indicating the profile color — green for Work, etc.).
- Bottom checkbox: "Open in a new window" (off by default).

#### Section C — "Test a URL"

- Full-width `CodeInput` with `https://mail.google.com/mail/u/0/` as placeholder.
- Below: a live result chip — `inline-flex`, 5/9 padding, 6 px radius, **green when matching** (`rgba(52,168,83,.12)` bg, `#1f7a4a` text, 11 px check icon, 12 px / 600 text, format "Matches `<host>` — routes to `<browser>` (`<profile>`)").
- If the URL does *not* match the rule: switch to gray (`rgba(0,0,0,.04)` bg, 55% black) with format "Falls through".

### 4. App Icon — Branch

**Purpose:** Replace the current literal "Signpost" icon with a metaphor closer to what the app actually does: one URL splitting into two destinations.

**Concept:** A trunk that splits into two diverging arrows on a slate-gradient rounded-square dock tile (macOS 26 / Sequoia–style icon proportions). Implementation lives in `lib/extras.jsx` as `IconBranch`.

**Variants explored** (in `Junction Redesign.html` → "App icon · alternates"):

- **I1 Signpost** (current shipped) — keep as runner-up if brand recognition matters more.
- **I2 Branch (picked)** — described above.
- **I3 Node** — graph junction; reads as tech-y but loses the routing verb.
- **I4 Wordmark J** — the letter J with the dot rebuilt as a small fork.

Recreate I2 at every required Sonoma icon size (16, 32, 64, 128, 256, 512, 1024 @1x and @2x). Use the same slate gradient `linear-gradient(155deg, #475569, #1e293b)` as the existing icon (pulled from `render_icon.swift`) so the brand color continues to read.

## Interactions & Behavior

### Picker

- Open behavior: Triggered when the user clicks a link AND no rule matches AND `Junction` is set as the default browser. Animates in with a quick scale-up + fade (suggested: 160 ms ease-out, scale from 0.96 → 1.0, opacity 0 → 1).
- Auto-dismiss: clicking anywhere outside the panel dismisses it (no link opens).
- Selection state: arrow keys cycle through `[suggested, ...others]` in the Smart mode, or `[1, 2, …]` in the Fallback mode.
- "Always" click: opens the link AND adds a new rule with `kind=host`, `value=<clicked host>`, `target=<suggested browser/profile>`. The rule should be added to the **end of the list** (lowest priority) so existing rules still win.
- "⌥↩" is equivalent to "Always" — open AND promote.

### Rules + Editor

- Picking a rule in the left pane swaps the right pane to its editor immediately (no transition needed; if added, ≤120 ms crossfade).
- Drag-reorder rules within and across groups. Moving a rule to a different group's section changes its target browser inline (with a confirm prompt the first time).
- The "Test a URL" field re-evaluates on every keystroke (debounce ≤100 ms).
- Adding a host chip: the chip appears immediately; the underlying regex updates; the test URL re-evaluates.
- Editing the rule name commits on blur or `↩`.

## State Management

The data model is the existing `rules.json` on disk, stored at `~/Library/Application Support/Junction/rules.json`. No schema change required for the redesign.

The visual matcher introduces **no new persistent state** — the chip list is a UI projection of the existing regex string (or `host` value). Conversion functions needed in app code:

- `chipsToRegex(hosts: [String], includeSubdomains: Bool) -> String`
  - Returns `^(host1|host2|...)$` if `includeSubdomains=false`, or `(^|\.)(host1|host2|...)$` if `true`.
- `regexToChips(regex: String) -> (hosts: [String], includeSubdomains: Bool)?`
  - Returns nil if the regex is not a simple host-list pattern (which forces the editor into raw mode).

The Smart Suggestion system needs a new per-host history table:

```swift
struct HostHistory {
  let host: String
  var picks: [PickEvent] // ring buffer of last ~20
}
struct PickEvent {
  let timestamp: Date
  let target: RuleTarget // browser + profile
}
```

The suggestion is the most-frequent `target` in the last N picks for that host, shown only if confidence ≥50% over a minimum sample size (e.g. ≥3 picks).

## Design Tokens

### Colors

- **Accent (system blue):** `#1e6dff` — used for selected list rows, primary buttons, the smart-suggestion accent, the JunctionMark
- **Accent soft:** `rgba(30,109,255,0.12)` — hover/selected backgrounds
- **Slate palette** (used in app icon + brand surfaces, pulled from `render_icon.swift`):
  - `slate100: #f1f5f9`
  - `slate200: #e2e8f0`
  - `slate300: #cbd5e1`
  - `slate400: #94a3b8`
  - `slate500: #64748b`
  - `slate600: #475569`
  - `slate700: #334155`
  - `slate800: #1e293b`
  - `slate900: #0f172a`
- **Status:**
  - Success / enabled: `#34a853` (the green status dot) and `#1f7a4a` (success-chip text)
  - Destructive: `#d23a2c`
- **Text on light:**
  - Primary: `#1a1a1a`
  - Secondary: `rgba(0,0,0,.7)` to `rgba(0,0,0,.55)`
  - Tertiary: `rgba(0,0,0,.45)` to `rgba(0,0,0,.4)`
- **Background fills** (used heavily for cards / form sections):
  - `rgba(0,0,0,.025)` — section card bg
  - `rgba(0,0,0,.04)` to `.05` — search/filter input bg
  - `rgba(0,0,0,.06)` to `.08` — hairlines, dividers
- **Glass-mode tints** (picker panel):
  - Top: `rgba(255,255,255,.38)`
  - Middle: `rgba(255,255,255,.18)`
  - Bottom: `rgba(255,255,255,.22)`
  - Border: `rgba(255,255,255,.55)`
  - Inset top sheen: `rgba(255,255,255,.22)`

### Typography

- **System font:** `-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro", "Helvetica Neue", sans-serif`
- **Monospace:** `ui-monospace, "SF Mono", Menlo, Consolas, monospace`
- **Sizes / weights used:**
  - 22 px / 600 — page titles ("Rules")
  - 19 px / 600 — editor rule name
  - 16 px / 600 — pane headers
  - 14 px / 600 — list rule names, fallback picker rows
  - 13.5 px / 600 — picker alternate cards
  - 13 / 12.5 px / 500–600 — body, segmented controls, dropdowns
  - 12 / 11.5 px / 500 — secondary labels, hints, code chips
  - 11 px / 700 uppercase / letter-spacing 0.6 — section headers
  - 10.5 px / 600 uppercase / letter-spacing 0.4 — DEFAULT / status eyebrows
  - 10–9.5 px / 600 — number badges, profile tags

### Spacing & Radius

- **Spacing scale used:** 2, 4, 6, 8, 10, 12, 14, 16, 18, 22, 26 px. No formal scale — match what the prototype shows.
- **Corner radii:**
  - 4–5 px — small chips, keycaps
  - 6 px — search inputs, dropdowns, CodeInput
  - 7 px — chips, button frames, mini-buttons
  - 8 px — primary buttons, list rows
  - 10 px — form section cards
  - 12 px — settings sidebar rows, picker alternate cards
  - 14 px — picker single-alternate, glass cards
  - 16 px — picker suggestion card
  - 18 px — older picker panels (not picked variant)
  - 22 px — Hero variant panel
  - **26 px — picked picker panel (Liquid Glass)**

### Shadows

- **Glass panel:** `0 40px 80px rgba(20,40,30,.38), 0 2px 0 rgba(255,255,255,.22) inset, 0 -1px 0 rgba(0,0,0,.04) inset, 0 0 0 0.5px rgba(0,0,0,.04)`
- **Inner glass card:** `0 4px 14px rgba(30,109,255,.12), inset 0 1px 0 rgba(255,255,255,.6)`
- **Primary button:** `0 2px 8px rgba(30,109,255,.35), inset 0 1px 0 rgba(255,255,255,.25)`
- **Settings window:** `0 30px 70px rgba(0,0,0,.18), 0 0 0 0.5px rgba(0,0,0,.12)`
- **List row card:** `0 1px 2px rgba(0,0,0,.04)`
- **Selected fallback row:** `0 2px 10px rgba(30,109,255,.3), inset 0 1px 0 rgba(255,255,255,.25)`

## Assets

- **Browser icons** — the prototype uses hand-drawn SVG approximations of Safari, Chrome, Firefox, Arc, Brave, Edge logos. In the real app, prefer extracting each browser's bundled `.icns` from `/Applications/<Browser>.app/Contents/Resources/AppIcon.icns` (or wherever it lives) and rendering at the requested size. The mapping from bundle ID to file is in `lib/junction-shared.jsx` under `MOCK_BROWSERS`.
- **SF Symbols** — the prototype hand-draws several (`star.fill`, `pin`, `pin.fill`, `sparkle`, `chevronDown`, `arrowRight`, `plus`, `minus`, `search`, `bolt`, `gear`, `signpost`, `handDraggable`, `folderBadge`, `info`, `sliders`, `wand`, `x`, `check`, `listBullet`, `doc.text`, `pencil`). In a real macOS app, use the actual `SF Symbols 5` glyphs at matching sizes.
- **Junction app icon** — currently `signpost.right.and.left` on a slate gradient (see `JunctionMark` in `lib/junction-shared.jsx`). The picked redesign (I2 Branch) is in `lib/extras.jsx` as `IconBranch`.
- **Favicons (`HostGlyph`)** — placeholder colored circles. Replace with actual favicons fetched via `https://www.google.com/s2/favicons?domain=<host>&sz=64` or the browser's own favicon cache.

## Screenshots

Rendered images of the picked variants are in `screenshots/`:

- `01-picker-smart.png` — Picker · Smart suggestion (default state). Shows the Liquid-Glass panel over a photographic backdrop so the refraction is visible. Demonstrates the suggestion card with Open / Always buttons and the single-alternate "Or open in" card layout (when the user has only 2 browsers).
- `02-picker-fallback.png` — Picker · Suggestions off. Same panel chrome and keyboard footer, but the body is a numbered list with the default browser highlighted in the saturated-blue selected state.
- `03-rules-editor.png` — Rules + Editor · Grouped two-pane. Shows: macOS settings sidebar, grouped rule list with profile chips and the selected-row treatment, and the right pane with the visual host-chip matcher, "Include subdomains" toggle, and the collapsed "Edit as regex (advanced)" disclosure.
- `04-icon-branch.png` — App Icon · Branch. Shows the picked icon at full size with a dock-strip preview alongside neighboring browser icons for context.

## Files

All design references are under `designs/`:

- `Junction Redesign.html` — root prototype, opens the full design canvas with every variant visible.
- `app.jsx` — the canvas composition. Reads as a table of contents: which artboards exist, what each shows, and which variant is picked (✓-tagged). **Start here** to orient yourself.
- `lib/junction-shared.jsx` — shared tokens (`JBRAND`, `JFONT`, `JMONO`), shared components (`BrowserIcon`, `HostGlyph`, `KeyCap`, `SFIcon`, `MacToggle`, `MacCheck`), and mock data (`MOCK_BROWSERS`, `MOCK_RULES`).
- `lib/picker-variants.jsx` — `PickerSmart` (the picked variant) plus the rejected `PickerNative`, `PickerHero`, `PickerCommand`, `PickerRadial`, `PickerProfile`. The glass treatment lives at the top of `PickerSmart` and in `DesktopBackdrop`.
- `lib/rules-variants.jsx` — `RulesHybrid` (the picked variant, "R5") plus `RulesNative`, `RulesGrouped`, `RulesTwoPane`, `RulesFlow`. The visual matcher with host chips lives inside `RulesHybrid`'s right pane.
- `lib/editor-variants.jsx` — `EditorSheet`, `EditorSentence`. **Superseded** — the editor is now part of `RulesHybrid`'s right pane. Kept for historical context only; do not re-implement these as separate sheets.
- `lib/extras.jsx` — onboarding, debug log, and the four app icon variants (`IconSignpost`, `IconBranch` (picked), `IconNode`, `IconTypo`).
- `design-canvas.jsx` — pan/zoom canvas runtime. Not part of Junction; you can ignore this entirely.

### How to read a variant

Each variant component is a pure render of one screen state. There's no app-level routing or state — interactions are sketched, not wired. Read each one as a static spec; the React/JSX is a convenience for the prototype, not a target.

### Out of scope for this handoff

- Onboarding flow (the `OnboardingHero` artboard) — concept only; not picked.
- Debug log refresh (`DebugLog` artboard) — concept only; not picked.
- The five rejected picker variants (P1, P2, P3, P4, P6).
- The three rejected icon directions (I1 Signpost, I3 Node, I4 Wordmark J).
- The two superseded editor sheets (E1, E2).
