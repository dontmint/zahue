# Zalo Theme — Maple Font + Rosé Pine Dawn

Minimal custom macOS theme injector for **Zalo PC**.

Not a ZaDark fork with full UI — just:

1. Unpack Zalo `app.asar`
2. Inject Rosé Pine Dawn CSS token overrides
3. Prefer **Maple Mono** if installed on the system
4. Keep an `app.asar.bak` for clean uninstall

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


## macOS Theme Switcher (SwiftUI)

Fully **native Swift** installer (no Node.js in the app):

```bash
./macos/scripts/build-app.sh
open dist/ZaloThemeSwitcher.app
```

- Default UI follows **System Default** (macOS Light/Dark)
- Selecting a catalog theme live-previews that palette in the switcher
- Apply/Restore uses Swift ASAR extract + HTML/CSS injection
- App size ~3MB (no embedded Node runtime)

Optional developer CLI (Node) still available in `install.js`, but the `.app` does not use it.

See [macos/README.md](./macos/README.md).
