# Junction design assets

Files in this folder are **source** for the icon — the canonical compiled
icons live in `../Sources/Junction/Assets.xcassets/AppIcon.appiconset/`.

| File | What it is |
| --- | --- |
| `render_icon.swift` | One-shot Swift script: SF Symbol + gradient → PNG. Used to produce the current icon. |
| `icon_master.png` | The 1024×1024 PNG used as the asset-catalog source. Re-runnable via `render_icon.swift`. |
| `icon.svg` | The original hand-drawn "J with junction kicker" concept — kept for history; not currently used. |
| `sfA.png` / `sfB.png` / `sfC.png` | Three SF-Symbol icon candidates we evaluated. We shipped C (signpost on slate); A and B are kept as design archaeology. |

## Regenerating the icon

```bash
cd design

# Render the signpost variant at 1024×1024
swift render_icon.swift \
  "signpost.right.and.left" \
  "475569" \
  "1E293B" \
  "semibold" \
  icon_master.png

# Resize down to all the asset-catalog sizes via sips
ICONS=../Sources/Junction/Assets.xcassets/AppIcon.appiconset
sips -z 16   16   icon_master.png --out "$ICONS/icon_16x16.png"
sips -z 32   32   icon_master.png --out "$ICONS/icon_16x16@2x.png"
sips -z 32   32   icon_master.png --out "$ICONS/icon_32x32.png"
sips -z 64   64   icon_master.png --out "$ICONS/icon_32x32@2x.png"
sips -z 128  128  icon_master.png --out "$ICONS/icon_128x128.png"
sips -z 256  256  icon_master.png --out "$ICONS/icon_128x128@2x.png"
sips -z 256  256  icon_master.png --out "$ICONS/icon_256x256.png"
sips -z 512  512  icon_master.png --out "$ICONS/icon_256x256@2x.png"
sips -z 512  512  icon_master.png --out "$ICONS/icon_512x512.png"
cp icon_master.png "$ICONS/icon_512x512@2x.png"

# Rebuild
cd ..
xcodegen generate
xcodebuild -project Junction.xcodeproj -scheme Junction build
```

## Trying a different SF Symbol

`render_icon.swift` accepts any SF Symbol name. Open SF Symbols.app
(`open -a "SF Symbols"`), pick a glyph, copy its name, then:

```bash
swift render_icon.swift "<symbol-name>" "<hex-top>" "<hex-bottom>" semibold preview.png
open preview.png
```

The original three candidates were:

- `arrow.triangle.branch` — most directly "routes a URL"
- `point.3.connected.trianglepath.dotted` — network-y abstraction
- `signpost.right.and.left` — literal junction sign (shipped)

## A note about the script and Retina

`NSImage.lockFocus()` on a Retina Mac creates a 2× backing store by default,
so a "1024×1024" image is actually saved as 2048×2048 pixels. The asset
catalog expects exact pixel sizes, so we always `sips -z 1024 1024` after
rendering to normalize before placing into the appiconset.
