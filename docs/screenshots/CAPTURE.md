# Screenshots — capture guide

The README references images in this folder. Capture them, drop the PNGs
here with the exact filenames below, then uncomment the matching
`![...]` lines in `README.md`.

## How to capture a window cleanly

For **Settings** (and any normal window): `⌘⇧4`, then press **Space** — the
cursor becomes a camera. Click the window. macOS saves a PNG (with the drop
shadow) to your Desktop. Move it here and rename.

### Capturing the picker (special case)

The interactive `⌘⇧4`/`⌘⇧5` tools **won't work on the picker**: it's a
floating panel that dismisses itself the instant it loses key focus (that's
how "click anywhere else to cancel" works), and the screenshot overlay
takes focus — so the picker vanishes before you can click it.

Use a **timed** capture instead, and let the picker open *during* the
countdown so nothing steals its focus:

```bash
# Arms a 7s timer, opens the picker after 3s, captures the full screen.
( sleep 3 && open "https://example.com/screenshot-demo" ) & \
  screencapture -T 7 ~/Desktop/picker.png
```

Then crop to the panel (Preview → ⌘K). Don't touch the keyboard or mouse
during the countdown. For the ⌥-held "always" variant, hold Option as the
timer fires.

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
