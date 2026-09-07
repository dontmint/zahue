# Zalo Theme Switcher (macOS)

Native **SwiftUI** app that switches Zalo PC themes:

- Rosé Pine Dawn (light)
- Rosé Pine Moon (soft dark)
- Rosé Pine (dark)
- Restore Original Zalo

The UI is native SwiftUI. Patching still uses the proven Node ASAR helper bundled inside the app (`Contents/Resources/helper`).

## Requirements

- macOS 14+
- Apple Swift toolchain (Command Line Tools is enough)
- Node.js 18+ (`brew install node`)
- App Management permission for the app (same as Terminal needed before)

## Build

```bash
cd ~/Projects/zalo-theme-maple-dawn
./macos/scripts/build-app.sh
open dist/ZaloThemeSwitcher.app
```

## Dev run (without app bundle)

```bash
cd macos/ZaloThemeSwitcher
ZALO_THEME_HELPER=~/Projects/zalo-theme-maple-dawn swift run
```

## CLI (same helper the app uses)

```bash
node install.js list
node install.js status
node install.js install rose-pine-dawn
node install.js install rose-pine-moon
node install.js install rose-pine
node install.js uninstall
```

## Notes

- First apply extracts `app.asar` and creates `app.asar.bak`
- Later theme switches reuse the unpacked folder (fast)
- Re-apply after Zalo updates
- Install Maple Mono for the intended font
