# Zalo Theme Switcher (macOS)

Native **SwiftUI** app that switches Zalo PC themes (80+ palettes) and any installed system font.

The installer is **fully native Swift** (ASAR extract + HTML/CSS inject). No Node.js runtime is required for end users or the app itself.

## Requirements

### End users
- macOS 14+
- App Management permission for Zalo Theme Switcher
- Keep Zalo’s built-in appearance on **Light** for correct colors

### Developers (building the .app)
- Apple Swift toolchain (Command Line Tools is enough)

## Build

```bash
cd ~/Projects/zalo-theme-maple-dawn
./macos/scripts/build-app.sh
open dist/ZaloThemeSwitcher.app
```

## Behavior

- Default chrome follows **System Default** (macOS Light/Dark)
- Selecting a catalog theme live-previews that palette in the switcher UI
- Apply writes the theme into Zalo via the native installer
- Optional developer CLI remains in repo root `install.js` (Node) but is not used by the app

## Notes

- First apply extracts `app.asar` and creates `app.asar.bak`
- Later theme switches reuse the unpacked folder (fast)
- Re-apply after Zalo updates
