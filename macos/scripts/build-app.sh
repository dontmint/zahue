#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PKG="$ROOT/macos/ZaHue"
DIST="$ROOT/dist"
APP="$DIST/ZaHue.app"

echo "==> Building Swift release binary"
cd "$PKG"
/usr/bin/swift build -c release

BIN=$(/usr/bin/swift build -c release --show-bin-path)/ZaHue
if [[ ! -x "$BIN" ]]; then
  echo "Binary not found: $BIN" >&2
  exit 1
fi

echo "==> Assembling app bundle at $APP"
rm -rf "$APP"
# Clean old branding bundle if present
rm -rf "$DIST/ZaloThemeSwitcher.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/themes"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>ZaHue</string>
  <key>CFBundleIdentifier</key>
  <string>com.zahue.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>ZaHue</string>
  <key>CFBundleDisplayName</key>
  <string>ZaHue</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.1.0</string>
  <key>CFBundleVersion</key>
  <string>2</string>
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

cp "$BIN" "$APP/Contents/MacOS/ZaHue"
chmod +x "$APP/Contents/MacOS/ZaHue"

echo "==> Bundling app icon + theme catalog"
cp "$ROOT/macos/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/macos/assets/AppLogo.png" "$APP/Contents/Resources/AppLogo.png"
cp "$ROOT/themes/terminalcolors.json" "$APP/Contents/Resources/themes/"

# ad-hoc sign
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" || true
fi

echo ""
echo "Done: $APP"
echo "Open with: open \"$APP\""
echo "Fully native Swift installer — no Node.js runtime bundled."
echo "If write permission fails, grant App Management to ZaHue."
