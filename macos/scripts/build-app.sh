#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PKG="$ROOT/macos/ZaloThemeSwitcher"
DIST="$ROOT/dist"
APP="$DIST/ZaloThemeSwitcher.app"
HELPER="$APP/Contents/Resources/helper"
ENSURE_NODE="$ROOT/macos/scripts/ensure-node-runtime.sh"

echo "==> Building Swift release binary"
cd "$PKG"
/usr/bin/swift build -c release

BIN=$(/usr/bin/swift build -c release --show-bin-path)/ZaloThemeSwitcher
if [[ ! -x "$BIN" ]]; then
  echo "Binary not found: $BIN" >&2
  exit 1
fi

echo "==> Assembling app bundle at $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$HELPER"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>ZaloThemeSwitcher</string>
  <key>CFBundleIdentifier</key>
  <string>com.local.ZaloThemeSwitcher</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Zalo Theme Switcher</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
</dict>
</plist>
PLIST

cp "$BIN" "$APP/Contents/MacOS/ZaloThemeSwitcher"
chmod +x "$APP/Contents/MacOS/ZaloThemeSwitcher"

echo "==> Bundling app icon"
cp "$ROOT/macos/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/macos/assets/AppLogo.png" "$APP/Contents/Resources/AppLogo.png"

echo "==> Bundling portable Node runtime (users do not need Node installed)"
chmod +x "$ENSURE_NODE"
NODE_BIN="$("$ENSURE_NODE")"
mkdir -p "$HELPER/runtime/bin"
cp "$NODE_BIN" "$HELPER/runtime/bin/node"
chmod +x "$HELPER/runtime/bin/node"
# Keep a stable relative marker for debugging
"$HELPER/runtime/bin/node" -v > "$HELPER/runtime/VERSION.txt"
echo "Bundled $($HELPER/runtime/bin/node -v) ($(uname -m))"

echo "==> Bundling Node helper scripts"
cp "$ROOT/install.js" "$HELPER/"
cp "$ROOT/package.json" "$HELPER/"
cp "$ROOT/package-lock.json" "$HELPER/"
mkdir -p "$HELPER/assets" "$HELPER/themes"
cp "$ROOT/assets/theme.css" "$HELPER/assets/"
cp "$ROOT/assets/theme.js" "$HELPER/assets/"
cp "$ROOT/themes/terminalcolors.json" "$HELPER/themes/"

(
  cd "$HELPER"
  # Install deps using the system npm if available; modules are plain JS.
  if command -v npm >/dev/null 2>&1; then
    npm ci --omit=dev
  else
    echo "npm not found; copy node_modules from repo" >&2
    cp -R "$ROOT/node_modules" "$HELPER/"
  fi
)

# Smoke-check: helper must run with ONLY the bundled runtime on PATH
echo "==> Verifying bundled runtime can execute install.js"
env -i PATH="/usr/bin:/bin" HOME="$HOME" \
  "$HELPER/runtime/bin/node" "$HELPER/install.js" list --mode light >/dev/null

# ad-hoc sign so Gatekeeper is a bit happier for local use
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" || true
fi

echo ""
echo "Done: $APP"
echo "Open with: open \"$APP\""
echo "No system Node.js install is required for end users."
echo "If write permission fails, grant App Management to Zalo Theme Switcher."
