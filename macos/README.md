# ZaHue (macOS)

Native **SwiftUI** app that themes Zalo PC (80 palettes) and any installed system font.

The installer is **fully native Swift** (ASAR extract + HTML/CSS inject). No Node.js runtime is required for end users or the app itself.

## Requirements

### End users
- macOS 14+
- App Management permission for **ZaHue**
- Keep Zalo’s built-in appearance on **Light** for light themes

### Developers (building the .app)
- Apple Swift toolchain (Command Line Tools is enough)

## Build

### Option A — GitHub Actions (recommended)

You do **not** need your own Mac for packaging — GitHub’s `macos-latest` runner builds it:

1. Open https://github.com/dontmint/zahue/actions
2. Choose **macOS build** → **Run workflow**
3. Download the **zahue-macos** artifact (`ZaHue.dmg` + zip fallback)

Workflow: `.github/workflows/macos-build.yml`

> Native Swift still requires a **Mac machine** to compile. GitHub provides that Mac in CI. You cannot build the `.app` on Linux/Windows.

### Option B — Build locally

```bash
./macos/scripts/build-app.sh
open dist/ZaHue.app
```

## Behavior

- Default chrome follows **System Default** (macOS Light/Dark)
- Selecting a catalog theme live-previews that palette in the switcher UI
- Apply writes the theme into Zalo via the native installer
- Restore puts back `app.asar` from `app.asar.bak`
- Vietnamese UI by default, with 🇻🇳 / 🇺🇸 language flags
- **Permission status:** Status row shows green **Permission OK** or red **Permission denied**
- If App Management is missing, a red banner appears with **Open Settings** (deep-link) + **Recheck**

## Notes

- Re-apply after Zalo updates (updates can replace `app.asar`)
- Grant **App Management** if Apply fails to write under `/Applications/Zalo.app`
- Use the in-app **Open Settings** button, or: System Settings → Privacy & Security → App Management → enable **ZaHue**
