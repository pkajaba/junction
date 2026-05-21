# Screenshots — capture guide

The README references images in this folder. Capture them, drop the PNGs
here with the exact filenames below, then uncomment the matching
`![...]` lines in `README.md`.

## How to capture a window cleanly

`⌘⇧4`, then press **Space** — the cursor becomes a camera. Click the
window. macOS saves a PNG (with the drop shadow) to your Desktop. Move it
here and rename.

For the picker (a borderless floating panel) the Space-then-click trick
still works — click anywhere on the panel.

## Shot list

| Filename | What | How to get the app into that state |
| --- | --- | --- |
| `picker.png` | The picker panel | `open "https://example.com/demo"` in Terminal — no rule matches `example.com`, so the picker appears. Capture it before dismissing. |
| `rules.png` | Settings → Rules, a rule selected | `⌘,` → Rules tab → click any rule so the inline editor shows. |
| `handoff.png` | Settings → Advanced, handoff toggles | `⌘,` → Advanced tab → scroll to "Hand off to native apps". |

Optional extras if you want them in the README later: `browsers.png`
(Settings → Browsers), `debug-log.png` (the main window with a few routed
URLs).

## Keep them clean

- Use a neutral desktop wallpaper — the picker is translucent, so whatever
  is behind it shows through.
- Avoid capturing windows with private URLs / real work links in them.
  `example.com` and the like are good stand-ins.
- 2× (Retina) PNGs are fine; GitHub scales them down.
