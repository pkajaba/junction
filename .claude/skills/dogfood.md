---
name: dogfood
description: Rebuild Junction.app from the current branch and replace /Applications/Junction.app with it. Handles all the lsregister/Spotlight cleanup. Use whenever the user says "dogfood Junction", "deploy", "rebuild and copy", or after any change you want the user to test in their real Dock.
---

# Dogfood Junction

End-to-end "make the latest code be the running app." Automates the
sequence we kept redoing by hand.

## What it does

1. Quits any running Junction (graceful, then force-kill if needed)
2. Regenerates the Xcode project from `project.yml`
3. Builds Debug, ad-hoc-signed, to `build/derived/`
4. Unregisters all known stale Junction.app copies from Launch Services
5. Replaces `/Applications/Junction.app` with the fresh build
6. Re-registers the `/Applications/` copy
7. Deletes the dev-path copy so Spotlight stays clean
8. Verifies: only one Junction in LaunchServices, Junction is still default browser, app launches
9. Reports the result

## When NOT to use this

- The user is in the middle of an editing flow and just wants to verify
  a build compiles — use `xcodebuild build` alone. Don't redeploy.
- The user is on a feature branch they explicitly don't want to dogfood.
  Confirm before deploying off an unexpected branch.

## The procedure

```bash
set -e
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
SRC_APP=build/derived/Build/Products/Debug/Junction.app
DEST_APP=/Applications/Junction.app

cd ~/Projects/junction

# 1. Quit any running Junction
osascript -e 'tell application id "com.pkajaba.junction" to quit' 2>/dev/null
sleep 1
pkill -9 -f "/Applications/Junction.app" 2>/dev/null || true

# 2. Regenerate project (idempotent)
xcodegen generate 2>&1 | tail -3

# 3. Build
xcodebuild \
  -project Junction.xcodeproj \
  -scheme Junction \
  -configuration Debug \
  -derivedDataPath build/derived \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E '(error:|warning:|^\*\* )' | head -5

# 4. Unregister stale copies
"$LSREG" -u "$DEST_APP" 2>&1 | tail -1 || true
"$LSREG" -u "$SRC_APP" 2>&1 | tail -1 || true
DD_APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Junction-*/Build/Products/Debug/Junction.app 2>/dev/null | head -1)
[ -n "$DD_APP" ] && "$LSREG" -u "$DD_APP" 2>&1 | tail -1 || true

# 5. Replace /Applications copy
rm -rf "$DEST_APP"
cp -R "$SRC_APP" "$DEST_APP"

# 6. Register the /Applications copy
"$LSREG" -f -R -trusted "$DEST_APP"

# 7. Delete dev copy so Spotlight stays clean
rm -rf "$SRC_APP"

# 8. Verify
echo
echo "=== LaunchServices http handlers (should show /Applications/Junction.app only for Junction) ==="
"$LSREG" -dump 2>/dev/null \
  | awk '
    /^path:/ { path = $0; sub(/^path:[[:space:]]+/, "", path) }
    /bindings:.*http:/ {
      if (path != "" && path !~ /\/System\//) print path
    }
  ' | grep -i junction

echo
echo "=== Junction is default for http/https? ==="
defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null \
  | awk '/LSHandlerURLScheme = (http|https);/{print prev " | " $0} {prev=$0}' \
  | grep junction || echo "  NOTE: Junction is not the default browser. Run design/set_default_browser.swift if you want to set it."

# 9. Launch
open "$DEST_APP"
sleep 2
pgrep -lf "/Applications/Junction.app" >/dev/null && echo "  ✓ Junction running"
```

## Notes on edge cases

- **First-time setup**: if `/Applications/Junction.app` doesn't exist yet,
  the unregister-and-rm steps are harmless no-ops. The skill handles this.
- **Build fails**: the procedure runs `xcodebuild` with `set -e`, so a
  failed build halts before the destructive steps. Junction.app is not
  replaced if the new binary doesn't exist.
- **Junction isn't currently default**: the verification reports this but
  doesn't fail. To set as default: `swift design/set_default_browser.swift
  /Applications/Junction.app`.
- **macOS first-run dialog**: ad-hoc-signed apps trigger Gatekeeper on
  first launch from /Applications/. Tell the user to right-click → Open
  if they see "Junction can't be opened because Apple cannot check it for
  malicious software." This only happens once per copy.

## Verification you ran the skill correctly

After the skill finishes you should be able to:

1. `open https://example.com/picker-test` — picker should pop up (assuming
   no rule matches example.com) with the latest UI
2. ⌘, → see the latest Settings UI
3. `ls -la /Applications/Junction.app/Contents/MacOS/Junction` — mtime
   should be within the last minute

If any of those don't behave as expected, something went wrong.
