# Junction design assets

Source files for the app icon and design references. The canonical
compiled icons live in
`../Sources/Junction/Assets.xcassets/AppIcon.appiconset/`.

## Current icon — "Branch"

The shipped icon: a trunk splitting into two diverging arrows on an indigo
gradient — "routing", not "signpost".

| File | What it is |
| --- | --- |
| `icon-branch.svg` | **Source** for the current icon — hand-drawn SVG |
| `icon_master_branch.png` | 1024×1024 render of `icon-branch.svg`, the asset-catalog source |

### Regenerating the Branch icon

```bash
cd design
# SVG → 1024 master (librsvg: brew install librsvg)
rsvg-convert -w 1024 -h 1024 icon-branch.svg -o icon_master_branch.png

# Resize down to every asset-catalog slot
ICONS=../Sources/Junction/Assets.xcassets/AppIcon.appiconset
for s in 16 32 128 256 512; do
  sips -z $s $s icon_master_branch.png --out "$ICONS/icon_${s}x${s}.png"
done
sips -z 32  32  icon_master_branch.png --out "$ICONS/icon_16x16@2x.png"
sips -z 64  64  icon_master_branch.png --out "$ICONS/icon_32x32@2x.png"
sips -z 256 256 icon_master_branch.png --out "$ICONS/icon_128x128@2x.png"
sips -z 512 512 icon_master_branch.png --out "$ICONS/icon_256x256@2x.png"
cp icon_master_branch.png                "$ICONS/icon_512x512@2x.png"

cd .. && xcodegen generate
```

## Archive — earlier explorations

Kept as design history; not used by the app.

| File | What it was |
| --- | --- |
| `icon.svg` | First concept — a stylized "J" with a forked tail. Read as "T/I + mustache"; dropped. |
| `icon_master.png` | Render of the rejected signpost icon (`signpost.right.and.left` on slate) |
| `sfA.png` / `sfB.png` / `sfC.png` | Three SF-Symbol candidates evaluated before the hand-drawn Branch won: `arrow.triangle.branch`, `point.3.connected.trianglepath.dotted`, `signpost.right.and.left` |
| `render_icon.swift` | Helper that renders any SF Symbol + gradient to PNG — used during the SF-Symbol exploration |

## Other files here

| File | What it is |
| --- | --- |
| `BRIEF.md` | Design brief — paste sections into Claude/a designer when asking for design work |
| `set_default_browser.swift` | Dev helper: sets Junction (or any app) as the default browser via `NSWorkspace`, bypassing the System Settings dropdown's signing filter |
| `handoff/` | The Claude Design redesign handoff — the source of the Branch icon, v2 picker, and two-pane Rules tab |

## A note about Retina and `NSImage.lockFocus()`

`render_icon.swift` uses AppKit drawing. `NSImage.lockFocus()` on a Retina
Mac creates a 2× backing store, so a "1024×1024" image saves as 2048×2048
pixels. Normalize with `sips -z 1024 1024` before placing into the
appiconset. (The Branch icon avoids this entirely — `rsvg-convert` renders
at exact pixel sizes.)
