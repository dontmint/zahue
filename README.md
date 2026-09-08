<p align="center">
  <img src="docs/assets/zahue-logo-256.png" alt="ZaHue" width="160" />
</p>

<h1 align="center">ZaHue</h1>

<p align="center">
  <strong>Theme switcher for Zalo PC</strong> — 80+ palettes, custom fonts, native installers.
</p>

<p align="center">
  <a href="https://github.com/dontmint/zahue/actions/workflows/macos-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/macos-build.yml?branch=main&style=for-the-badge&logo=apple&logoColor=white&label=macOS" alt="macOS build" /></a>
  <a href="https://github.com/dontmint/zahue/actions/workflows/windows-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/windows-build.yml?branch=main&style=for-the-badge&logo=windows&logoColor=white&label=Windows" alt="Windows build" /></a>
  <img src="https://img.shields.io/badge/themes-80%2B-7c3aed?style=for-the-badge&logo=palette&logoColor=white" alt="80+ themes" />
  <img src="https://img.shields.io/badge/license-MPL--2.0-blue?style=for-the-badge" alt="MPL-2.0" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-native-F05138?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Tauri-Windows-FFC131?style=flat-square&logo=tauri&logoColor=black" alt="Tauri" />
  <img src="https://img.shields.io/badge/VI%20%2F%20EN-localized-00A86B?style=flat-square" alt="Localized" />
  <img src="https://img.shields.io/badge/Electron-ASAR%20patch-47848F?style=flat-square&logo=electron&logoColor=white" alt="Electron ASAR" />
  <a href="https://github.com/dontmint/zahue/stargazers"><img src="https://img.shields.io/github/stars/dontmint/zahue?style=flat-square" alt="Stars" /></a>
</p>

**ZaHue** applies catalog themes to **Zalo PC** on macOS and Windows:

1. Unpack Zalo `app.asar`
2. Inject CSS token overrides + optional UI font / size
3. Keep an `app.asar.bak` for clean Restore
4. Switch themes without reinstalling Zalo

Inspired by [ZaDark](https://github.com/ncdai/zadark) (MPL-2.0) Electron ASAR patching.

## Theme

| Role | Hex |
|------|-----|
| Base | `#faf4ed` |
| Surface | `#fffaf3` |
| Overlay | `#f2e9e1` |
| Muted | `#9893a5` |
| Subtle | `#797593` |
| Text | `#575279` |
| Love | `#b4637a` |
| Gold | `#ea9d34` |
| Rose | `#d7827e` |
| Pine | `#286983` |
| Foam | `#56949f` |
| Iris | `#907aa9` |

Font stack:

```css
"Maple Mono", "Maple Mono NL", "Maple Mono NF", "Maple Mono Normal",
ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif
```

Default weight is **SemiBold (`600`)**, with emphasis at **Bold (`700`)**.

Tune in `assets/theme.css`:

```css
--zalo-maple-weight: 600;        /* UI / messages */
--zalo-maple-weight-strong: 700; /* b / strong */
```

If Maple is not installed, Zalo falls back to system UI fonts. Make sure the SemiBold/Bold Maple faces (or variable font) are installed in Font Book.

## Install Maple Font

Download from: https://github.com/subframe7536/maple-font

Install the `.ttf` / `.otf` into **Font Book**, then restart Zalo.

## Usage (macOS)

```bash
cd ~/Projects/zalo-theme-maple-dawn
npm install

# Grant Terminal App Management permission first (System Settings → Privacy & Security)
# Set Zalo appearance to Light

# Quit Zalo, then:
node install.js install

# Restore original:
node install.js uninstall
```

Custom Zalo path:

```bash
node install.js install /path/to/Zalo.app
```

## Important notes

- Re-install after every Zalo update (updates overwrite the patch)
- Needs write access under `/Applications/Zalo.app`
- Modifies a third-party app — may conflict with Zalo ToS / future integrity checks
- Dawn is a **light** theme; keep Zalo's built-in theme on Light
- Chat UI in monospace is intentional; switch the CSS font stack if you prefer proportional text

## Files

```
assets/theme.css   # Rosé Pine Dawn → Zalo token map + Maple font
assets/theme.js    # Tiny bootstrap (sets data attributes / classes)
install.js         # ASAR extract → inject → replace
```

## Customize

- Colors: edit `assets/theme.css` (`--rp-*` variables)
- Font: change `--zalo-maple-font`
- Then run `node install.js install` again


## ZaHue for macOS (SwiftUI)

Fully **native Swift** installer (no Node.js in the app):

```bash
./macos/scripts/build-app.sh
open dist/ZaHue.app
```

- Default UI follows **System Default** (macOS Light/Dark)
- Selecting a catalog theme live-previews that palette in the switcher
- Apply/Restore uses Swift ASAR extract + HTML/CSS injection
- App size ~3MB (no embedded Node runtime)
- **CI:** GitHub Actions → **macOS build** workflow uploads `ZaHue.dmg`

Optional developer CLI (Node) still available in `install.js`, but the `.app` does not use it.

See [macos/README.md](./macos/README.md) for ZaHue macOS details.

## ZaHue for Windows (Tauri)

Cross-platform GUI twin for Windows (React + Rust installer):

```bash
cd windows
npm install
npm run tauri:dev      # develop (UI on any OS; Apply needs Windows Zalo)
npm run tauri:build    # produce .exe / .msi on a Windows machine
```

- Same ASAR unpack + CSS/JS inject technique
- Default Zalo path: `%LOCALAPPDATA%\Programs\Zalo`
- Vietnamese / English UI, theme preview, font size, Apply / Restore
- **From macOS:** use GitHub Actions → **Windows build** workflow, then download the `zahue-windows` artifact

See [windows/README.md](./windows/README.md) for ZaHue Windows details.

Shared CLI also supports Windows:

```bash
node install.js status
node install.js install rose-pine-dawn --font "Segoe UI"
```
