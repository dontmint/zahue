# Zalo Theme Switcher (macOS)

Native **SwiftUI** app that switches Zalo PC themes (80+ palettes from terminalcolors.com) and any installed system font.

The UI is native SwiftUI. Patching still uses the Node ASAR helper, but a **portable Node runtime is bundled inside the app**, so end users do **not** need Node.js / Homebrew.

Bundled layout:

```
ZaloThemeSwitcher.app/Contents/Resources/helper/
  install.js
  runtime/bin/node   ← portable Node (no system install needed)
  node_modules/
  themes/terminalcolors.json
```

## Requirements

### End users
- macOS 14+
- App Management permission for Zalo Theme Switcher (System Settings → Privacy & Security)
- Keep Zalo’s built-in appearance on **Light** for correct colors

### Developers (building the .app)
- Apple Swift toolchain (Command Line Tools is enough)
- Network access once (build downloads portable Node into `macos/runtime/`, gitignored)
- `npm` on the build machine to vendor helper dependencies

## Build

```bash
cd ~/Projects/zalo-theme-maple-dawn
./macos/scripts/build-app.sh
open dist/ZaloThemeSwitcher.app
```

The build script:
1. Compiles the SwiftUI app
2. Downloads/caches portable Node (`macos/scripts/ensure-node-runtime.sh`)
3. Embeds `helper/runtime/bin/node`
4. Smoke-tests `install.js` using **only** the bundled runtime

## Dev run (without app bundle)

```bash
cd macos/ZaloThemeSwitcher
ZALO_THEME_HELPER=~/Projects/zalo-theme-maple-dawn swift run
```

Dev mode can fall back to a system Node if the bundled runtime is not present.

## CLI (developers)

```bash
node install.js list --mode dark
node install.js status
node install.js install everforest-light --font "SF Pro Text" --weight 500
node install.js uninstall
```

## Notes

- First apply extracts `app.asar` and creates `app.asar.bak`
- Later theme switches reuse the unpacked folder (fast)
- Re-apply after Zalo updates
- Build for the Mac architecture you distribute (`arm64` or `x64`); the embedded Node matches the build host
