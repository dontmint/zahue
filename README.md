<p align="center">
  <img src="docs/assets/zahue-logo-256.png" alt="ZaHue" width="160" />
</p>

<h1 align="center">ZaHue</h1>

<p align="center">
  <strong>Theme switcher for Zalo PC</strong> — 80 palettes, custom fonts, native installers.
</p>

<p align="center">
  <a href="https://github.com/dontmint/zahue/actions/workflows/macos-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/macos-build.yml?branch=main&style=for-the-badge&logo=apple&logoColor=white&label=macOS" alt="macOS build" /></a>
  <a href="https://github.com/dontmint/zahue/actions/workflows/windows-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/windows-build.yml?branch=main&style=for-the-badge&logo=windows&logoColor=white&label=Windows" alt="Windows build" /></a>
  <a href="https://github.com/dontmint/zahue/actions/workflows/linux-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/linux-build.yml?branch=main&style=for-the-badge&logo=linux&logoColor=white&label=Linux" alt="Linux build" /></a>
  <img src="https://img.shields.io/badge/themes-80-7c3aed?style=for-the-badge&logo=palette&logoColor=white" alt="80 themes" />
  <img src="https://img.shields.io/badge/license-MPL--2.0-blue?style=for-the-badge" alt="MPL-2.0" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-native-F05138?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Tauri-Windows%20%2F%20Linux-FFC131?style=flat-square&logo=tauri&logoColor=black" alt="Tauri Windows/Linux" />
  <img src="https://img.shields.io/badge/VI%20%2F%20EN-localized-00A86B?style=flat-square" alt="Localized" />
  <img src="https://img.shields.io/badge/Electron-ASAR%20patch-47848F?style=flat-square&logo=electron&logoColor=white" alt="Electron ASAR" />
  <a href="https://github.com/dontmint/zahue/stargazers"><img src="https://img.shields.io/github/stars/dontmint/zahue?style=flat-square" alt="Stars" /></a>
</p>

**ZaHue** applies catalog themes to **Zalo PC** on macOS, Windows, and Linux (unofficial ports):

1. Unpack Zalo `app.asar`
2. Inject CSS token overrides + optional UI font / size
3. Keep an `app.asar.bak` for clean Restore
4. Switch themes without reinstalling Zalo

Inspired by [ZaDark](https://github.com/ncdai/zadark) (MPL-2.0) Electron ASAR patching. Theme palettes are sourced from [terminalcolors.com](https://terminalcolors.com) Alacritty catalogs.

There is **no official Zalo Linux client** — ZaHue supports unofficial AppImage / `.deb` ports when pointed at a writable install.

## Download

| Platform | Artifact | How |
|----------|----------|-----|
| **macOS** | `ZaHue.dmg` | [Releases](https://github.com/dontmint/zahue/releases) or Actions → **macOS build** |
| **Windows** | NSIS `.exe` / `.msi` | [Releases](https://github.com/dontmint/zahue/releases) or Actions → **Windows build** |
| **Linux** | `.AppImage` / `.deb` | [Releases](https://github.com/dontmint/zahue/releases) or Actions → **Linux build** |

First launch on macOS (ad-hoc signed): **Right-click → Open** if Gatekeeper warns.

## Features

- **80 themes** (18 light / 62 dark) from `themes/terminalcolors.json`
- Live palette preview in the switcher UI
- Any installed system font (Maple Mono preferred if present; not required)
- Font weight + UI size (rem scale)
- Vietnamese default UI + English toggle
- Apply / Restore with installer log
- Native apps — no Node.js runtime for end users

## ZaHue for macOS (SwiftUI)

Fully **native Swift** installer (~1.6MB app bundle):

```bash
./macos/scripts/build-app.sh
open dist/ZaHue.app
```

Or download the DMG from CI / Releases (no local Xcode needed).

- Default chrome follows **System Default** (macOS Light/Dark)
- Selecting a catalog theme live-previews that palette
- Apply/Restore uses Swift ASAR extract + HTML/CSS injection
- Needs **App Management** permission to write under `/Applications/Zalo.app`

See [macos/README.md](./macos/README.md).

## ZaHue Desktop (Windows + Linux)

Cross-platform GUI (React + Rust installer) in `desktop/`:

```bash
cd desktop
npm install
npm run tauri:dev      # develop (UI on any OS; Apply needs a local Zalo install)
npm run tauri:build    # produce platform installers on the matching OS
```

- **Windows** default path: `%LOCALAPPDATA%\Programs\Zalo`
- **Linux:** unofficial AppImage/deb ports — writable extract required. Auto-detect tries `/opt/Zalo`, `/usr/{lib,share}/zalo`, `~/.local/share/Zalo`, `~/Applications/Zalo`, `~/zalo-*/app`, `squashfs-root` (see [desktop/README.md](./desktop/README.md)). AppImage mounts are often read-only.
- **CI:** Actions → **Windows build** / **Linux build** → download `zahue-windows` / `zahue-linux`

See [desktop/README.md](./desktop/README.md).

## Optional CLI (developers)

Node 18+ helper at repo root (macOS + Windows + Linux):

```bash
npm install

node install.js list [--mode light|dark]
node install.js status [ZaloPath]
node install.js install <theme-id> [ZaloPath] [--font "Family"] [--weight 600]
node install.js uninstall [ZaloPath]
```

Examples:

```bash
node install.js install rose-pine-dawn
node install.js install rose-pine-dawn --font "SF Pro Text" --weight 500
node install.js install rose-pine-moon --font "Segoe UI"
node install.js uninstall
```

Shortcuts in `package.json`: `npm run theme:list`, `theme:dawn`, `theme:moon`, `theme:restore`.

## Important notes

- Re-apply after every Zalo update (updates can replace `app.asar`)
- Keep Zalo’s built-in appearance on **Light** when using light themes (recommended for most palettes)
- Modifies a third-party app — may conflict with Zalo ToS / future integrity checks
- Needs write access under `/Applications/Zalo.app` (macOS), the Zalo install folder (Windows), or a writable Linux extract
- Linux AppImages are often read-only — extract first, then point ZaHue at that folder

## Repo layout

```
themes/terminalcolors.json   # 80-theme catalog
assets/theme.js              # Tiny bootstrap injected into Zalo
assets/theme.css             # Placeholder (CSS is generated at apply time)
install.js                   # Optional Node CLI (ASAR extract → inject)
macos/                       # Native SwiftUI app + build script
desktop/                     # Tauri + React Windows/Linux app
docs/assets/                 # README / branding artwork
.github/workflows/           # macOS + Windows + Linux CI builds
```

## Customize

- **Pick a theme:** use ZaHue.app / Desktop GUI, or `node install.js list`
- **Catalog:** edit / extend `themes/terminalcolors.json`
- **Fonts:** choose any installed family in the GUI, or `--font` on the CLI

## License

[MPL-2.0](./LICENSE) — technique adapted from ZaDark; palettes from terminalcolors.com.
