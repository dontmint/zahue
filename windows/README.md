# ZaHue (Windows)

Tauri + React GUI that applies catalog themes to **Zalo PC on Windows**.

Same technique as the macOS app / ZaDark-style Electron patching:

1. Locate Zalo `resources/app.asar`
2. Unpack (or update an existing unpacked tree)
3. Inject `pc-dist/zalo-theme/theme.css` + `theme.js`
4. Keep `app.asar.bak` for Restore

No Node.js runtime is required for end users — installer logic is native Rust.

## Requirements

### End users
- Windows 10/11
- Zalo PC installed (default `%LOCALAPPDATA%\Programs\Zalo`)
- Permission to write under the Zalo install folder (Run as Administrator if needed)
- Keep Zalo’s built-in appearance on **Light** for correct colors

### Developers
- Node.js 18+
- Rust toolchain (`rustup`)
- WebView2 (usually preinstalled on Windows 10/11)

## Develop

```bash
cd windows
npm install
npm run tauri:dev
```

## Build Windows installer / portable exe

### Option A — GitHub Actions (recommended from macOS)

You do **not** need a Windows PC. Push to `main` (or run the workflow manually):

1. Open https://github.com/dontmint/zahue/actions
2. Choose **Windows build** → **Run workflow**
3. When it finishes, download the **zahue-windows** artifact (`.msi` / NSIS `.exe`)

The workflow lives at `.github/workflows/windows-build.yml`.

### Option B — Build on a Windows machine

```bash
cd windows
npm install
npm run tauri:build
```

Artifacts land under:

- `src-tauri/target/release/ZaHue.exe`
- `src-tauri/target/release/bundle/msi/`
- `src-tauri/target/release/bundle/nsis/`

> Cross-compiling a full Tauri Windows installer **from macOS** is unreliable
> (needs Windows linkers + NSIS/WiX). Prefer GitHub Actions or a Windows box.

## Features

- 80 themes from `themes/terminalcolors.json`
- Live palette preview in the switcher UI
- Font family / weight / size (rem scale)
- Vietnamese default + English flag toggle
- Apply / Restore with installer log

## Shared CLI (optional)

The repo-root `install.js` also supports Windows paths:

```bash
node install.js status
node install.js install rose-pine-dawn --font "Segoe UI" --weight 400
node install.js uninstall
```

## Notes

- After Zalo updates, re-apply the theme (update may replace `app.asar`).
- Default path can be edited in the UI if your Zalo install differs.
