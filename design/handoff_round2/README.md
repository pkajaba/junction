# Junction · Settings improvements — Round 2 handoff

## What's in here

- **`CLAUDE_CODE_HANDOFF.md`** — the spec. Open this first. Five surgical changes to the shipped Settings window, in priority order, with all the implementation detail (data models, color tokens, button dimensions, bundle-ID maps, keyboard shortcuts).
- **`Junction Settings Improvements.html`** — interactive design canvas. Open in any browser (no server needed). Pan with two-finger drag, zoom with pinch/scroll, or click any artboard to focus it fullscreen. This is the source of truth for layout, colors, spacing.
- **`mocks-stacked.html`** — same 5 mocks rendered top-to-bottom (no canvas, no pan/zoom). Useful for screenshotting or scrolling through quickly.

## The 5 changes (TL;DR)

| # | Tab      | Change                                                                              |
|---|----------|-------------------------------------------------------------------------------------|
| ① | Activity | Make the log a rule-builder. Every "no rule" row → hover → `+ Create rule…` button. |
| ② | Rules    | Move `+`/`−` from the bottom toolbar into the sidebar title row. "Grouped by …" becomes a real popover with 4 options. |
| ③ | Handoff  | Not-installed rows: 55% opacity + "Not installed ↗" pill linking to vendor download. Footer note removed. |
| ④ | Browsers | Replace the gray skeleton rows with a real "that's everything Junction found" empty-state card. Add a manual-add path. |
| ⑤ | Advanced | Promote "Strip tracking parameters" to a section header with toggle inline. Nest the param list under it. Add a missing "Add param" input. |

## Order of attack

1. **① Activity** — biggest user value unlock, touches the most product surface.
2. **② Rules header** — small, low-risk, immediate visual upgrade.
3. **④ Browsers empty state** — tiny, very high "looks broken → looks intentional" delta.
4. **③ Handoff** disabled states.
5. **⑤ Advanced** restructure.

## Open question for the team

Where should `rules.json` (the "show on disk" button currently in the Rules-tab bottom toolbar) live after the bottom toolbar empties out? Either keep a slim toolbar or move it into a `⋯` menu on the right pane. Pick before kicking off ②.
