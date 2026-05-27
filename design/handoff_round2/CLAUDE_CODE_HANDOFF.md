# Junction — Settings improvements (Round 2)

Five surgical changes to the shipped Settings window. Each one is scoped to a single tab. Do them in order — they're listed by user value.

**Mockups:** `Junction Settings Improvements.html` (open in a browser; pan/zoom around the canvas to inspect each artboard).

**Existing code expectations:** SwiftUI on macOS, settings window using a top-tab `Picker(.segmented)` style chrome with a centered tab group, current tabs are `Rules / Browsers / Handoff / Advanced / Activity`. Adapt the names to your existing types — these instructions describe behavior, not file names.

---

## ① Activity → rule-builder

**File you'll touch:** Activity tab view + its row model + a new "create rule from activity" action.

### What changes

The Activity tab is currently empty-state-only. Build it into a working log where every row is a step away from becoming a rule.

**Row shape (per entry):**
- **Time** (left, 60pt wide, monospaced, secondary).
- **URL block** (flex middle):
  - Line 1: favicon-style glyph + `host` in bold + `path` in secondary color, single-line truncated.
  - Line 2 (subline, smaller, secondary):
    - `from <App>` — the source app the link came from (`AppKit NSWorkspace.shared.frontmostApplication` at the time of the open, captured into the log row).
    - `· cleaned (<param> stripped)` in green, if tracking params were removed.
    - `· N× this week → <Browser>` in amber pill, if the user has manually picked the same browser for this host 2+ times (see "Suggestion logic" below).
- **Outcome block** (right, 220pt wide, right-aligned):
  - **Matched a rule:** green ✓ + `<Browser> · <Profile>` bold, then "via <rule name>" subline.
  - **No match (picker shown):** amber dot + `<Browser> · picked manually` bold, then "no rule matched" subline.
  - **Unsupported (e.g. `mailto:`):** "Skipped" bold + "not an http(s) link" subline.

**Filter chips above the list:**
- `All` | `Matched a rule` | `No rule · picker` | `Errors`
- Each chip has a count. The "No rule · picker" chip gets a small amber dot indicator when its count > 0 (drawing attention to the rules backlog).
- Pill style, current state filled in system blue; default state is light gray.

**Header right-side actions:** `Export…` (writes JSONL), `Clear` (existing).

**Header subtitle:** "Every link Junction has handled. Hover any row to make it into a rule."

### Hover interaction

When the row is hovered AND it's a `No match` outcome, the rightmost area shows:
- A primary blue `+ Create rule…` button.
- A keycap badge `⌘R` below it (the keyboard shortcut to do the same).

Clicking the button (or pressing ⌘R while the row is selected) opens the Rules tab with a **new rule prefilled**:
- Host = `row.host`
- Include subdomains = on
- Target = the browser the user picked manually in this entry
- Profile = the profile of that browser, if any
- Rule name = `"<host> → <Browser>"` (e.g. `"figma.com → Chrome"`)
- The new rule is selected, ready for the user to tweak and save.

### Suggestion logic (the amber "N× this week → Chrome" pill)

Maintain a small rolling counter in the log model: for each `host`, count manual picks per browser over the last 7 days. When the count reaches 2 within 7 days, show the pill on that row's subline; when it reaches 3, also surface a one-time gentle banner above the list:

> _"You've picked Chrome for figma.com 3 times this week. **Make it a rule?**"_  → primary button.

Dismissed banners don't reappear for that host for 7 days.

### Empty state (kept, but updated)

When the log truly is empty (first run), show the existing empty state but replace the subtitle to: "Set Junction as your default browser, then click a link anywhere. Matching rules route silently; the rest pop up the picker — and end up here."

### Data model

A log entry needs to persist:

```swift
struct ActivityEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let url: URL
    let cleanedURL: URL?              // if rewriting changed it
    let strippedParams: [String]      // for the "cleaned (…)" subline
    let sourceApp: String?            // bundle ID or display name
    let outcome: Outcome              // see below
}

enum Outcome: Codable {
    case matched(ruleID: UUID, ruleName: String, browser: String, profile: String?)
    case pickerManual(browser: String, profile: String?)
    case unsupported(reason: String)  // "mailto", "javascript:", etc.
}
```

Persist to `~/Library/Application Support/Junction/activity.jsonl` (append-only, one JSON per line). Cap at the most recent 1000 entries — trim on launch.

---

## ② Rules tab — sidebar header restructure

**File you'll touch:** the left sidebar of the Rules split view.

### What changes

**Header zone (top of sidebar, replaces today's empty corner):**

Layout, top to bottom:

1. Title row: `Rules` (22pt, semibold, leading-aligned) on the left, two icon buttons on the right:
   - `−` (remove rule) — circular, hairline border, white background. Disabled if no rule selected.
   - `+` (new rule) — circular, **filled system blue**, white plus glyph. Primary action.
2. Meta row (12pt, secondary): `26 rules · grouped by [destination ▾]`.
   - The `[destination ▾]` segment is a clickable pill that opens a popover menu with four options:
     - **Destination** (current) — by target browser.
     - **Source app** — by the app the link came from (`Slack`, `Mail`, etc.).
     - **Match type** — `host` / `regex` / `contains` / etc.
     - **Nothing** — flat list, no group headers.
   - The current selection gets a leading checkmark in the popover.
3. Filter input (existing) with a `⌘F` keycap on the right, hairline border, light gray background.

**Bottom toolbar (where `+ −  rules.json` used to live):**
- **Remove** the `+` and `−` from the bottom — they're now in the header.
- Keep `rules.json` (or move it to the title bar of the right pane as a "..." menu item; either works, just don't leave a half-empty toolbar).

### Grouping behavior

When grouping is `Destination`, render group headers as today (browser icon + name + count). For `Source app`, group by `entry.sourceApp`; for `Match type`, group by `rule.match.kind`. For `Nothing`, render flat (no headers).

The grouping choice is per-window state, persisted to `UserDefaults` (key: `JunctionRulesGrouping`).

### Visual spec for the +/− buttons

```
+ button: 22×22, corner radius 11, fill = system blue,
          plus glyph: 12pt SF Symbols "plus", weight semibold, white.
          Hover: slightly darker blue.
- button: 22×22, corner radius 11, fill = white,
          stroke = 0.5pt rgba(black, 0.15),
          minus glyph: 12pt SF Symbols "minus", weight regular, gray.
          Disabled (no selection): 40% opacity, no hover.
```

---

## ③ Handoff — proper disabled states

**File you'll touch:** Handoff tab list view + the `HandoffApp` model.

### What changes

**For each app row, branch the render by `app.isInstalled`:**

| State | Icon | Toggle area | Row opacity |
|---|---|---|---|
| Installed | Real app icon (28×28, rounded, drop shadow) | Working `MacToggle` | 100% |
| Not installed | Dashed-outline 28×28 placeholder, no glyph | Pill button "Not installed ↗" | 55% |

The "Not installed ↗" button:
- Background `rgba(black, 0.04)`, hairline border, `rgba(black, 0.12)`.
- Text "Not installed", 11.5pt semibold, color `rgba(black, 0.65)`.
- Trailing icon: `arrow.up.forward` (SF Symbol).
- Click action: opens the vendor download URL in the system default browser. Hard-code a small `[appBundleID: downloadURL]` map for the seven supported apps:
  - `us.zoom.xos` → `https://zoom.us/download`
  - `com.microsoft.teams2` → `https://www.microsoft.com/microsoft-teams/download-app`
  - `com.tinyspeck.slackmacgap` → `https://slack.com/downloads/mac`
  - `notion.id` → `https://www.notion.so/desktop`
  - `com.linear` → `https://linear.app/download`
  - `com.spotify.client` → `https://www.spotify.com/download`
  - `com.hnc.Discord` → `https://discord.com/download`

**Section header:** "Hand off to native apps" on the left, "<N> installed · <M> available" counter on the right.

**Remove** the bottom footnote "Toggles are disabled when the corresponding app isn't installed." — the UI now self-explains.

### Layout

Wrap the whole list in a rounded container (`background: rgba(0,0,0,.025)`, `border: 0.5pt rgba(0,0,0,.06)`, `cornerRadius: 12`) with hairline dividers between rows. Section header sits outside that container, above it.

---

## ④ Browsers — empty state

**File you'll touch:** Browsers tab list view.

### What changes

After the real detected browsers, **remove the six gray skeleton rows**. Replace them with a single empty-state card:

- Dashed border, `rgba(0,0,0,.18)`, `cornerRadius: 12`.
- Inner padding ~20pt.
- Left: 36×36 icon tile (light gray background, `folder.badge` SF Symbol).
- Middle:
  - Title (13pt semibold): "That's everything Junction found."
  - Subtitle (12pt, secondary, two lines): "Junction scans `/Applications` and `~/Applications`. Install another browser, then click Refresh — or add one by bundle ID."
- Right: secondary button `+ Add manually`. Clicking opens a small sheet that takes:
  - **Bundle ID** (e.g. `com.brave.Browser`)
  - **Display name** (e.g. `Brave`)
  - **Icon** (optional file picker; falls back to a generic glyph).

Persisted manually-added browsers go into `UserDefaults` under `JunctionManualBrowsers` as an array of `{bundleID, name, iconPath?}`.

Also add a `Refresh` button in the page header (top-right) that re-runs the `/Applications` scan and re-renders. Currently this only exists in the empty state's body — promote it.

### Header polish

Add a `System default` pill next to Safari (or whichever browser is the macOS default) — 10pt uppercase, system-blue text on a 10% tinted background. Helps users grok which browser is being routed to when no rule matches.

---

## ⑤ Advanced — hierarchy + add-param input

**File you'll touch:** Advanced tab body.

### What changes

Restructure the body so the **toggle is the section header**, not a peer of the param list.

**Order, top to bottom:**

1. **Appearance** card (compact, one row):
   - Label "Theme" on the left, segmented `System / Light / Dark` on the right.
   - Hint subtitle under the label: "'System' follows macOS. Light and Dark override it for Junction only."
2. **Tracking section** (the meat):
   - **Row-level header** (NOT a card — this sits in the page chrome):
     - Title "Strip tracking parameters" (14pt semibold).
     - Subtitle (12pt secondary): "Removes `utm_*`, `fbclid`, `gclid`, and other tracking-only params before the URL hits a rule."
     - Trailing: full-size `MacToggle`.
   - **Indented card below** (`rgba(0,0,0,.025)` background, `cornerRadius: 12`):
     - Mini-header inside: "Parameters to strip" uppercase + "N params · matched against query string" on the right.
     - **List of params** in a nested white card. Each row: param name (monospaced) + `−` circular button (20×20) on the right.
     - **Last row of the list** is an add-input on a tinted blue background:
       - Leading: blue `+` glyph.
       - Input: placeholder "Add a parameter… (e.g. ref, source_id, *_token)", monospaced, 12.5pt.
       - Trailing: `⏎` keycap.
       - Pressing return adds the param, clears the input.

### Disabled state

When "Strip tracking parameters" is **off**, dim the entire indented card to 50% opacity and disable interaction. The toggle and its label remain at full opacity.

### Glob support

Params support `*` as a wildcard (e.g. `utm_*` matches `utm_source`, `utm_medium`, etc.). Implement with `NSRegularExpression` by converting glob → regex: escape the param, replace `\*` with `.*`, anchor with `^$`. Match against query string keys, case-insensitive.

---

## General notes

- **Don't change the top-tab chrome** — it works. All five edits live inside their existing tab containers.
- **Spacing scale:** 4 / 8 / 12 / 16 / 20 / 22 / 24 pt. Don't invent new values.
- **Colors used:**
  - Primary blue: `#1e6dff` (existing macOS-system-blue).
  - Success green: `#34a853`, success bg `rgba(52,168,83,.12)`.
  - Warning amber: `#f5a623`, amber bg `rgba(245,166,35,.14)`.
  - Hairline: `rgba(0,0,0,0.08)`.
  - Surface tint: `rgba(0,0,0,0.025)`.
- **Animations:** any toggle, chip, or hover state animates at `0.15s ease-out`. Card mounts/unmounts use a 0.2s fade only — no slide.
- **A11y:** every interactive control needs a `.accessibilityLabel`. Hover-revealed controls must also be reachable via keyboard (Tab focus shows them).
- **Keyboard shortcuts to wire:** `⌘F` (focus filter input in Rules), `⌘N` (new rule, scoped to Rules tab), `⌘R` (create-rule-from-activity, scoped to Activity tab when a no-match row is selected).

### Order of attack

1. ① Activity (biggest unlock, touches the most product surface — start here).
2. ② Rules header (small, low-risk, immediate visual upgrade).
3. ④ Browsers empty state (tiny, very high "looks broken → looks intentional" delta).
4. ③ Handoff disabled states.
5. ⑤ Advanced restructure.

Test each on macOS 14 and 15. The window has min/max sizes — make sure the new Activity row truncates URLs cleanly down to ~700pt window width.
