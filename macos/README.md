# ZaHue (macOS)

Native **SwiftUI** app that themes Zalo PC (80+ palettes) and any installed system font.

The installer is **fully native Swift** (ASAR extract + HTML/CSS inject). No Node.js runtime is required for end users or the app itself.

## Requirements

### End users
- macOS 14+
- App Management permission for **ZaHue**
- Keep Zalo’s built-in appearance on **Light** for correct colors

### Developers (building the .app)
- Apple Swift toolchain (Command Line Tools is enough)

## Build

```bash
cd ~/Projects/zalo-theme-maple-dawn
./macos/scripts/build-app.sh
open dist/ZaHue.app
```

## Behavior

- Default chrome follows **System Default** (macOS Light/Dark)
- Selecting a catalog theme live-previews that palette in the switcher UI
- Apply writes the theme into Zalo via the native installer
- Restore puts back `app.asar` from `app.asar.bak`
- Vietnamese UI by default, with 🇻🇳 / 🇺🇸 language flags

## Notes

- Re-apply after Zalo updates (updates can replace `app.asar`)
- Grant **App Management** if Apply fails to write under `/Applications/Zalo.app`
