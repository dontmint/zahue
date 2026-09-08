# ZaHue Desktop (Windows + Linux)

Tauri + React GUI that applies catalog themes to **Zalo PC** on Windows and Linux.

There is **no official Zalo Linux client**. ZaHue targets unofficial Linux ports shipped as AppImage or `.deb` (and similar Electron layouts).

Same technique as the macOS app / ZaDark-style Electron patching:

1. Locate Zalo `resources/app.asar`
2. Unpack (or update an existing unpacked tree)
3. Inject `pc-dist/zalo-theme/theme.css` + `theme.js`
4. Keep `app.asar.bak` for Restore

No Node.js runtime is required for end users — installer logic is native Rust.

## Requirements

### End users

**Windows**
- Windows 10/11
- Zalo PC installed (default `%LOCALAPPDATA%\Programs\Zalo`)
- Permission to write under the Zalo install folder (Run as Administrator if needed)

**Linux**
- Unofficial Zalo Linux port (AppImage / `.deb` / extracted Electron tree)
- A **writable** Zalo install directory (see AppImage note below)
- Permission to write under that install folder

Keep Zalo’s built-in appearance on **Light** for correct colors.

### Developers
- Node.js 18+
- Rust toolchain (`rustup`)
- **Windows:** WebView2 (usually preinstalled on Windows 10/11)
- **Linux:** WebKitGTK + build deps (see Tauri Linux prerequisites / CI workflow)

## AppImage / read-only installs (Linux)

AppImages are often mounted **read-only**. ZaHue must write next to `app.asar`, so point it at an **extracted / writable** copy, for example:

- Extract with `./Zalo*.AppImage --appimage-extract` → use `squashfs-root/`
- Gear Lever / AppImageLauncher “extract” / integrated writable install
- System package under `/opt/Zalo` (or similar)
- A cloned Electron `app/` tree you own

In the UI, set the Zalo path to the folder that contains `resources/app.asar` (or the port’s equivalent resources root).

## Default path candidates

**Windows:** `%LOCALAPPDATA%\Programs\Zalo` (also tries `%LOCALAPPDATA%\ZaloPC` / `Programs\ZaloPC`).

**Linux** (`default_zalo_path`; first match wins, else `/opt/Zalo`):

1. `/opt/Zalo`
2. `/opt/zalo`
3. `/usr/lib/zalo`
4. `/usr/share/zalo`
5. `$HOME/.local/share/Zalo`
6. `$HOME/.local/share/zalo`
7. `$HOME/Applications/Zalo`
8. `$HOME/Applications/zalo`
9. `$HOME/zalo-for-linux/app`
10. `$HOME/zalo-linux/app`
11. `$HOME/zalo-linux-2026/app`
12. `$HOME/squashfs-root`
13. `./squashfs-root`

Fallback: `/opt/Zalo`

`resources_dir` also probes `path/resources`, `path/squashfs-root/resources`, and `path/app/resources` (plus macOS `Contents/Resources` variants).

Edit the path in the UI if your install differs.

## Develop

```bash
cd desktop
npm install
npm run tauri:dev
```

## Build via CI (recommended)

Push to `main` or run the workflows manually:

1. Open https://github.com/dontmint/zahue/actions
2. Choose **Windows build** or **Linux build** → **Run workflow**
3. Download artifacts:
   - **zahue-windows** — `.msi` / NSIS `.exe`
   - **zahue-linux** — `.AppImage` / `.deb` (`.rpm` if produced)

Workflows:

- `.github/workflows/windows-build.yml`
- `.github/workflows/linux-build.yml`

## Build locally

```bash
cd desktop
npm install
npm run tauri:build
```

Artifacts land under `src-tauri/target/release/bundle/` (`nsis` / `msi` on Windows; `appimage` / `deb` on Linux).

> Cross-compiling full Tauri installers across OS boundaries is unreliable. Prefer GitHub Actions or a machine matching the target OS.

## Features

- 80 themes from `themes/terminalcolors.json`
- Live palette preview in the switcher UI
- Font family / weight / size (rem scale)
- Vietnamese default + English flag toggle
- Apply / Restore with installer log

## Shared CLI (optional)

The repo-root `install.js` supports Windows and Linux paths:

```bash
node install.js status
node install.js install rose-pine-dawn --font "Segoe UI" --weight 400
node install.js uninstall
```

## Notes

- After Zalo updates, re-apply the theme (update may replace `app.asar`).
- Default path can be edited in the UI if your Zalo install differs.
- Linux: always use a writable extracted install — AppImage mounts will fail apply/restore.
