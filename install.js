#!/usr/bin/env node
/**
 * Zalo PC (macOS) multi-theme installer
 * Themes sourced from https://terminalcolors.com (Alacritty palettes)
 * Technique adapted from ZaDark (MPL-2.0): https://github.com/ncdai/zadark
 *
 * Usage:
 *   node install.js list [--mode light|dark]
 *   node install.js status [Zalo.app]
 *   node install.js install <theme-id> [Zalo.app] [--font "Family"] [--weight 600]
 *   node install.js uninstall [Zalo.app]
 */

const os = require('os')
const path = require('path')
const fs = require('fs-extra')
const asar = require('@electron/asar')
const HTMLParser = require('node-html-parser')
const { spawnSync } = require('child_process')

const ASSET_DIR_NAME = 'zalo-theme'
const MARKER = 'data-zalo-theme-tool'
const DEFAULT_ZALO = '/Applications/Zalo.app'
const TMP = path.join(os.homedir(), 'zalo-theme-tmp')
const STATE_FILE = 'theme-state.json'
const CATALOG_PATH = path.join(__dirname, 'themes', 'terminalcolors.json')

const ALIASES = {
  'rose-pine': 'rose-pine-default'
}

function die (msg) {
  console.error(`\n[error] ${msg}`)
  process.exit(1)
}

function info (msg) {
  console.log(`[info] ${msg}`)
}

function isFile (p) {
  try { return fs.statSync(p).isFile() } catch { return false }
}

function isDir (p) {
  try { return fs.statSync(p).isDirectory() } catch { return false }
}

function loadCatalog () {
  if (!isFile(CATALOG_PATH)) die(`Theme catalog missing: ${CATALOG_PATH}`)
  const list = fs.readJsonSync(CATALOG_PATH)
  const byId = {}
  for (const theme of list) byId[theme.id] = theme
  return { list, byId }
}

function resolveThemeId (id) {
  return ALIASES[id] || id
}

function parseArgs (argv) {
  const out = { _: [], flags: {} }
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a === '--font' || a === '--weight' || a === '--mode' || a === '--zalo') {
      out.flags[a.slice(2)] = argv[++i]
    } else if (a.startsWith('--font=')) {
      out.flags.font = a.slice(7)
    } else if (a.startsWith('--weight=')) {
      out.flags.weight = a.slice(9)
    } else if (a.startsWith('--mode=')) {
      out.flags.mode = a.slice(7)
    } else {
      out._.push(a)
    }
  }
  return out
}

function getResourcesDir (zaloAppPath) {
  const resources = path.join(zaloAppPath, 'Contents', 'Resources')
  if (!isDir(resources)) die(`Resources not found: ${resources}`)
  return resources
}

function quitZalo () {
  info('Quitting Zalo if running...')
  spawnSync('killall', ['Zalo'], { stdio: 'ignore' })
  spawnSync('killall', ['zalo'], { stdio: 'ignore' })
}

function hexToRgb (hex) {
  const h = String(hex || '').replace('#', '')
  if (h.length !== 6) return { r: 0, g: 0, b: 0 }
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16)
  }
}

function rgbToHex ({ r, g, b }) {
  const clamp = (n) => Math.max(0, Math.min(255, Math.round(n)))
  return '#' + [clamp(r), clamp(g), clamp(b)].map((n) => n.toString(16).padStart(2, '0')).join('')
}

function mix (a, b, t) {
  const A = hexToRgb(a)
  const B = hexToRgb(b)
  return rgbToHex({
    r: A.r + (B.r - A.r) * t,
    g: A.g + (B.g - A.g) * t,
    b: A.b + (B.b - A.b) * t
  })
}

function rgba (hex, alpha) {
  const { r, g, b } = hexToRgb(hex)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

function themeCssSource (theme, fontFamily, fontWeight) {
  const bg = theme.background
  const fg = theme.foreground
  const accent = theme.accent || theme.blue || theme.cyan
  const isLight = theme.mode === 'light'
  const surface = isLight ? mix(bg, '#ffffff', 0.55) : mix(bg, '#ffffff', 0.04)
  const overlay = isLight ? mix(bg, fg, 0.08) : mix(bg, '#ffffff', 0.08)
  const hlLow = isLight ? mix(bg, fg, 0.05) : mix(bg, '#ffffff', 0.05)
  const hlMed = isLight ? mix(bg, fg, 0.14) : mix(bg, '#ffffff', 0.14)
  const hlHigh = isLight ? mix(bg, fg, 0.22) : mix(bg, '#ffffff', 0.22)
  const muted = theme.bright_black || mix(fg, bg, 0.45)
  const subtle = mix(fg, bg, 0.25)
  const selfBubble = isLight ? mix(accent, bg, 0.82) : mix(accent, bg, 0.75)
  const selfBorder = mix(accent, bg, 0.55)
  const family = fontFamily || 'Maple Mono'
  const weight = Number(fontWeight) || 600
  const strong = Math.min(900, weight + 100)

  return `/*
  Zalo Theme — ${theme.name}
  Source: terminalcolors.com / ${theme.id}
*/
:root {
  --zalo-ui-font: "${family}", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --zalo-ui-weight: ${weight};
  --zalo-ui-weight-strong: ${strong};
  --medium: ${weight};
  --semibold: ${weight};
  --bold: ${strong};
}

html[data-zalo-theme="${theme.id}"] {
  --rp-base: ${bg};
  --rp-surface: ${surface};
  --rp-overlay: ${overlay};
  --rp-muted: ${muted};
  --rp-subtle: ${subtle};
  --rp-text: ${fg};
  --rp-love: ${theme.red};
  --rp-gold: ${theme.yellow};
  --rp-rose: ${theme.magenta};
  --rp-pine: ${theme.blue};
  --rp-foam: ${theme.cyan};
  --rp-iris: ${theme.bright_magenta || theme.magenta};
  --rp-hl-low: ${hlLow};
  --rp-hl-med: ${hlMed};
  --rp-hl-high: ${hlHigh};
  --rp-self-bubble: ${selfBubble};
  --rp-self-bubble-border: ${selfBorder};
  --rp-self-selected: ${mix(selfBubble, accent, 0.18)};
  --rp-selection: ${theme.selection_bg || rgba(accent, 0.35)};
  --message-view-gradient: linear-gradient(to top, ${hlLow}, ${bg});
  --item-select: ${mix(accent, bg, 0.82)};
  --B10: ${mix(theme.blue, bg, 0.85)}; --B15: ${mix(theme.blue, bg, 0.85)};
  --B20: ${mix(theme.blue, bg, 0.7)}; --B25: ${mix(theme.blue, bg, 0.7)};
  --B30: ${mix(theme.blue, bg, 0.45)}; --B40: ${mix(theme.blue, bg, 0.2)};
  --B50: ${theme.cyan}; --B55: ${theme.cyan}; --B60: ${theme.blue}; --B70: ${theme.blue};
  --B80: ${theme.bright_blue || theme.blue}; --B85: ${theme.bright_blue || theme.blue};
  --B90: ${theme.bright_blue || theme.blue}; --B95: ${theme.bright_blue || theme.blue}; --B100: ${theme.bright_blue || theme.blue};
  --B50-alpha-10: ${rgba(theme.cyan, 0.1)}; --B50-alpha-20: ${rgba(theme.cyan, 0.2)}; --B50-alpha-30: ${rgba(theme.cyan, 0.3)};
  --R10: ${mix(theme.red, bg, 0.85)}; --R15: ${mix(theme.red, bg, 0.85)};
  --R20: ${mix(theme.red, bg, 0.7)}; --R25: ${mix(theme.red, bg, 0.7)};
  --R30: ${mix(theme.red, bg, 0.45)}; --R40: ${mix(theme.red, bg, 0.2)};
  --R50: ${theme.red}; --R55: ${theme.red}; --R60: ${theme.red}; --R70: ${theme.bright_red || theme.red};
  --R80: ${theme.bright_red || theme.red}; --R85: ${theme.bright_red || theme.red}; --R90: ${theme.bright_red || theme.red};
  --R95: ${theme.bright_red || theme.red}; --R100: ${theme.bright_red || theme.red};
  --R50-alpha-10: ${rgba(theme.red, 0.1)}; --R50-alpha-20: ${rgba(theme.red, 0.2)}; --R50-alpha-30: ${rgba(theme.red, 0.3)};
  --OR50: ${theme.yellow}; --OR55: ${theme.yellow}; --OR60: ${theme.yellow};
  --Y50: ${theme.yellow}; --Y60: ${theme.yellow};
  --G50: ${theme.green}; --G60: ${theme.green};
  --P50: ${theme.magenta}; --P60: ${theme.magenta};
  --PK50: ${theme.bright_magenta || theme.magenta}; --PK60: ${theme.bright_magenta || theme.magenta};
  --BA0: transparent; --BA10: ${rgba(fg, 0.08)}; --BA20: ${rgba(fg, 0.12)}; --BA30: ${rgba(fg, 0.18)};
  --BA40: ${rgba(fg, 0.25)}; --BA50: ${rgba(fg, 0.35)}; --BA70: ${rgba(fg, 0.55)}; --BA80: ${rgba(fg, 0.7)};
  --BA100: ${isLight ? '#fff' : fg};
  --WA0: transparent; --WA10: ${rgba(bg, 0.4)}; --WA15: ${rgba(overlay, 0.7)}; --WA50: ${rgba(surface, 0.7)};
  --WA70: ${rgba(surface, 0.85)}; --WA80: ${rgba(surface, 0.92)}; --WA100: ${surface};

  --N10: var(--rp-hl-low); --N15: var(--rp-hl-low); --N20: var(--rp-overlay); --N25: var(--rp-overlay);
  --N30: var(--rp-hl-med); --N40: var(--rp-muted); --N50: var(--rp-muted); --N60: var(--rp-subtle);
  --N70: var(--rp-subtle); --N80: var(--rp-subtle); --N90: var(--rp-text); --N100: var(--rp-text);
  --N200: var(--rp-text); --N300: var(--rp-text); --N350: var(--rp-text);
  --NG10: var(--rp-base); --NG15: var(--rp-base); --NG20: var(--rp-overlay); --NG25: var(--rp-overlay);
  --NG30: var(--rp-hl-med); --NG40: var(--rp-muted); --NG50: var(--rp-muted); --NG55: var(--rp-subtle);
  --NG60: var(--rp-subtle); --NG70: var(--rp-text); --NG80: var(--rp-text); --NG85: var(--rp-text);
  --NG90: var(--rp-text); --NG95: var(--rp-text); --NG100: var(--rp-text);

  --bg-default: var(--rp-surface); --title-bar: var(--rp-base);
  --surface-background: var(--rp-base); --surface-background-subtle: var(--rp-hl-low);
  --surface-alt: var(--rp-surface); --surface-background-overlay: var(--rp-overlay);
  --layer-background: var(--rp-surface); --layer-background-subtle: var(--rp-base);
  --layer-background-hover: var(--rp-hl-low); --layer-background-disabled: var(--rp-overlay);
  --layer-background-selected: var(--item-select); --layer-background-inverse: var(--rp-text);
  --layer-background-inverse-subtle: var(--rp-subtle);
  --layer-background-leftmenu: var(--rp-base); --layer-background-leftmenu-hover: var(--rp-overlay);
  --layer-background-leftmenu-selected: var(--rp-overlay);
  --layer-background-navbar-normal: var(--rp-base); --layer-background-navbar-hover: var(--rp-overlay);
  --layer-background-navbar-selected: var(--rp-overlay);
  --text-primary: var(--rp-text); --text-primary-50: ${rgba(fg, 0.55)};
  --text-secondary: var(--rp-subtle); --text-placeholder: var(--rp-muted); --text-disabled: var(--rp-muted);
  --text-on-color: ${isLight ? '#fff' : bg}; --text-errors: var(--rp-love); --text-success: var(--rp-foam);
  --text-warning: var(--rp-gold); --text-information: var(--rp-pine); --text-mention: var(--rp-pine);
  --icon-primary: var(--rp-subtle); --icon-secondary: var(--rp-muted); --icon-disabled: var(--rp-muted);
  --icon-on-color: ${isLight ? '#fff' : bg}; --icon-errors: var(--rp-love); --icon-success: var(--rp-foam);
  --icon-warning: var(--rp-gold); --icon-information: var(--rp-pine);
  --icon-count-noti-enable-bg: var(--rp-love); --icon-count-noti-disable-bg: var(--rp-muted);
  --border: var(--rp-hl-med); --border-subtle: var(--rp-hl-low); --border-bold: var(--rp-hl-high);
  --border-disabled: var(--rp-hl-med); --border-focused: var(--rp-foam); --border-selected: var(--rp-pine);
  --border-errors: var(--rp-love); --border-success: var(--rp-foam); --border-warning: var(--rp-gold);
  --border-information: var(--rp-pine); --divider: var(--rp-hl-med); --divider-subtle: var(--rp-hl-low); --divider-bold: var(--rp-hl-high);
  --link: var(--rp-pine); --success: var(--rp-foam); --tab-txt: var(--rp-subtle); --tab-inactive: var(--rp-subtle); --tab-active: var(--rp-pine);
  --scrollbar: var(--rp-hl-high); --scrollbar-opacity: 0.55; --selection: var(--rp-selection); --selection-text: var(--rp-text);
  --blue-message: var(--rp-self-bubble); --blue-message-selected: var(--rp-self-selected);
  --blue-message-selected-border: var(--rp-self-bubble-border); --blue-message-border: var(--rp-self-bubble-border);
  --blue-message-action: var(--rp-self-selected); --blue-message-action-border: var(--rp-self-bubble-border);
  --blue-message-btn: var(--rp-overlay); --blue-message-btn-border: var(--rp-hl-med);
  --blue-quote: var(--rp-overlay); --blue-quote-selected: var(--rp-overlay); --blue-quote-border: var(--rp-self-bubble-border);
  --blue-quote-line: var(--rp-foam); --blue-link: var(--rp-pine); --blue-file-progress-track: var(--rp-overlay); --blue-message-shadow: transparent;
  --white-message: var(--rp-surface); --white-message-selected: var(--rp-hl-low); --white-message-selected-border: var(--rp-hl-med);
  --white-message-border: var(--rp-hl-med); --white-message-action: var(--rp-base); --white-message-action-border: var(--rp-hl-med);
  --white-message-btn: var(--rp-overlay); --white-message-btn-border: var(--rp-hl-med);
  --white-quote: var(--rp-hl-low); --white-quote-selected: var(--rp-hl-low); --white-quote-border: var(--rp-hl-med);
  --white-quote-line: var(--rp-iris); --white-link: var(--rp-pine); --white-file-progress-track: var(--rp-hl-med);
  --button-primary-normal: var(--rp-pine); --button-primary-hover: var(--rp-foam); --button-primary-pressed: var(--rp-pine);
  --button-primary-text: ${isLight ? '#fff' : bg}; --button-secondary-normal: ${rgba(theme.cyan, 0.12)};
  --button-secondary-hover: ${rgba(theme.cyan, 0.2)}; --button-secondary-text: var(--rp-pine);
  --button-danger-normal: var(--rp-love); --button-danger-text: ${isLight ? '#fff' : bg};
  --input-field-bg-filled: var(--rp-overlay); --input-field-bg-filled-hover: var(--rp-hl-med);
  --field-bg-filled: var(--rp-overlay); --field-bg-filled-hover: var(--rp-hl-med);
  --field-bg-outline: var(--rp-surface); --field-bg-outline-hover: var(--rp-hl-low);
  --item-wa-hover: var(--rp-hl-low); --item-wa-select: var(--item-select); --brand-primary: var(--rp-pine);
}

html[data-zalo-theme="${theme.id}"] body.zalo-theme {
  font-family: var(--zalo-ui-font) !important;
  font-weight: var(--zalo-ui-weight) !important;
  background-color: var(--rp-surface);
  color: var(--rp-text);
  -webkit-font-smoothing: antialiased;
}

html[data-zalo-theme="${theme.id}"] body.zalo-theme .message-view,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .card--text,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .rich-input,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .rich-text-input,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .chat-box-input__content__input,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .conv-message,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .z-conv-message,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .chat-info-general__item--title,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .title-name {
  font-family: var(--zalo-ui-font) !important;
  font-weight: var(--zalo-ui-weight) !important;
}

html[data-zalo-theme="${theme.id}"] body.zalo-theme b,
html[data-zalo-theme="${theme.id}"] body.zalo-theme strong,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .font-semibold,
html[data-zalo-theme="${theme.id}"] body.zalo-theme [style*="font-weight: 500"],
html[data-zalo-theme="${theme.id}"] body.zalo-theme [style*="font-weight:500"] {
  font-weight: var(--zalo-ui-weight-strong) !important;
}

html[data-zalo-theme="${theme.id}"] body.zalo-theme .message-view__blur__overlay,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .message-view__blur__overlay_noavatar {
  background-image: var(--message-view-gradient) !important;
}

html[data-zalo-theme="${theme.id}"] body.zalo-theme #main-tab { border-right: 1px solid var(--border); }
html[data-zalo-theme="${theme.id}"] body.zalo-theme.zalo-theme--darwin .nav__tabs__zalo {
  padding-top: 40px; padding-bottom: 16px; height: auto;
}
html[data-zalo-theme="${theme.id}"] body.zalo-theme .leftbar-tab { color: var(--rp-subtle); }
html[data-zalo-theme="${theme.id}"] body.zalo-theme .leftbar-tab:hover,
html[data-zalo-theme="${theme.id}"] body.zalo-theme .leftbar-tab.selected { color: var(--rp-pine); }
html[data-zalo-theme="${theme.id}"] body.zalo-theme .card.me {
  background-color: var(--blue-message); border-color: var(--blue-message-border);
}
html[data-zalo-theme="${theme.id}"] body.zalo-theme .card:not(.me) {
  background-color: var(--white-message); border-color: var(--white-message-border);
}
html[data-zalo-theme="${theme.id}"] body.zalo-theme ::selection {
  background: var(--selection) !important; color: var(--selection-text) !important;
}
html[data-zalo-theme="${theme.id}"] body.zalo-theme div::-webkit-scrollbar-thumb {
  background: var(--scrollbar) !important; opacity: var(--scrollbar-opacity) !important;
}
html[data-zalo-theme="${theme.id}"] body.zalo-theme .setting-section:has(> .setting-section-content__theme) {
  display: none;
}
`
}

function themeJsSource (themeId) {
  return `/*
  Zalo Theme bootstrap — ${themeId}
*/
(function () {
  const THEME = ${JSON.stringify(themeId)}
  const html = document.documentElement
  const body = document.body
  html.setAttribute('data-zalo-theme', THEME)
  body.classList.add('zalo-theme')
  body.classList.remove('zalo-maple-dawn', 'zalo-maple-dawn--darwin')
  if (html.getAttribute('data-zalo-os') === 'macOS') body.classList.add('zalo-theme--darwin')
  console.info('[zalo-theme]', THEME, 'active')
})()
`
}

function cleanInjected (head, body) {
  head.querySelectorAll(`link[${MARKER}]`).forEach((el) => el.remove())
  body.querySelectorAll(`script[${MARKER}]`).forEach((el) => el.remove())
  head.querySelectorAll('link[href*="zalo-theme"], link[href*="zalo-maple-dawn"]').forEach((el) => el.remove())
  body.querySelectorAll('script[src*="zalo-theme"], script[src*="zalo-maple-dawn"]').forEach((el) => el.remove())
}

function patchIndexHtml (appRoot, themeId) {
  const indexPath = path.join(appRoot, 'pc-dist', 'index.html')
  if (!isFile(indexPath)) die(`Missing ${indexPath}`)
  const root = HTMLParser.parse(fs.readFileSync(indexPath, 'utf8'))
  const html = root.getElementsByTagName('html')[0]
  const head = root.getElementsByTagName('head')[0]
  const body = root.getElementsByTagName('body')[0]
  cleanInjected(head, body)
  head.insertAdjacentHTML('beforeend', `<link rel="stylesheet" href="${ASSET_DIR_NAME}/theme.css" ${MARKER}="1">`)
  body.insertAdjacentHTML('beforeend', `<script src="${ASSET_DIR_NAME}/theme.js" ${MARKER}="1"></script>`)
  html.setAttribute('data-zalo-os', 'macOS')
  html.setAttribute('data-zalo-theme', themeId)
  body.classList.add('zalo-theme', 'zalo-theme--darwin')
  body.classList.remove('zalo-maple-dawn', 'zalo-maple-dawn--darwin')
  const csp = head.querySelector('meta[http-equiv="Content-Security-Policy"]')
  if (csp) {
    let content = csp.getAttribute('content') || ''
    if (!content.includes("'unsafe-inline'") && content.includes('style-src')) {
      content = content.replace(/style-src[^;]*/, (m) => `${m} 'unsafe-inline'`)
      csp.setAttribute('content', content)
    }
  }
  fs.writeFileSync(indexPath, root.toString())
  info(`Patched ${indexPath}`)
}

function copyThemeAssets (appRoot, theme, fontFamily, fontWeight) {
  const destAssets = path.join(appRoot, 'pc-dist', ASSET_DIR_NAME)
  fs.ensureDirSync(destAssets)
  fs.writeFileSync(path.join(destAssets, 'theme.css'), themeCssSource(theme, fontFamily, fontWeight))
  fs.writeFileSync(path.join(destAssets, 'theme.js'), themeJsSource(theme.id))
  fs.writeJsonSync(path.join(destAssets, STATE_FILE), {
    themeId: theme.id,
    themeName: theme.name,
    mode: theme.mode,
    fontFamily: fontFamily || 'Maple Mono',
    fontWeight: Number(fontWeight) || 600,
    installedAt: new Date().toISOString(),
    tool: 'zalo-theme-switcher',
    source: 'terminalcolors.com'
  }, { spaces: 2 })
  const legacy = path.join(appRoot, 'pc-dist', 'zalo-maple-dawn')
  if (isDir(legacy)) fs.rmSync(legacy, { recursive: true, force: true })
  info(`Copied theme assets → ${destAssets} (${theme.id}, font=${fontFamily || 'Maple Mono'} ${fontWeight || 600})`)
}

function readInstalledState (appAsarPath) {
  if (!isDir(appAsarPath)) return null
  const statePath = path.join(appAsarPath, 'pc-dist', ASSET_DIR_NAME, STATE_FILE)
  if (isFile(statePath)) {
    try { return fs.readJsonSync(statePath) } catch { return null }
  }
  if (isDir(path.join(appAsarPath, 'pc-dist', 'zalo-maple-dawn'))) {
    return { themeId: 'rose-pine-dawn', fontFamily: 'Maple Mono', fontWeight: 600 }
  }
  return null
}

function printStatus (zaloAppPath, catalog) {
  const resources = getResourcesDir(zaloAppPath)
  const appAsarPath = path.join(resources, 'app.asar')
  const appAsarBakPath = path.join(resources, 'app.asar.bak')
  const state = readInstalledState(appAsarPath)
  const status = {
    ok: true,
    zaloPath: zaloAppPath,
    zaloExists: isDir(zaloAppPath),
    appAsarIsFile: isFile(appAsarPath),
    appAsarIsDirectory: isDir(appAsarPath),
    hasBackup: isFile(appAsarBakPath),
    themeId: state?.themeId || null,
    themeName: state?.themeName || null,
    fontFamily: state?.fontFamily || null,
    fontWeight: state?.fontWeight || null,
    themed: Boolean(state?.themeId),
    // Catalog is loaded by the app from themes/terminalcolors.json (keep status small).
    themeCount: catalog.list.length
  }
  console.log(JSON.stringify(status, null, 2))
}

function listThemes (catalog, mode) {
  let themes = catalog.list
  if (mode === 'light' || mode === 'dark') themes = themes.filter((t) => t.mode === mode)
  console.log(JSON.stringify({
    count: themes.length,
    themes: themes.map((t) => ({
      id: t.id,
      name: t.name,
      mode: t.mode,
      family: t.family,
      accent: t.accent,
      background: t.background,
      foreground: t.foreground
    }))
  }, null, 2))
}

async function install (themeIdRaw, zaloAppPath, fontFamily, fontWeight, catalog) {
  if (os.platform() !== 'darwin') die('This installer currently targets macOS only.')
  const themeId = resolveThemeId(themeIdRaw)
  const theme = catalog.byId[themeId]
  if (!theme) die(`Unknown theme "${themeIdRaw}". Run: node install.js list`)

  const resources = getResourcesDir(zaloAppPath)
  const appAsarPath = path.join(resources, 'app.asar')
  const appAsarBakPath = path.join(resources, 'app.asar.bak')
  const extractPath = path.join(TMP, 'app')

  if (!isFile(appAsarPath) && !isDir(appAsarPath) && !isFile(appAsarBakPath)) {
    die(`Neither app.asar nor app.asar.bak found in ${resources}`)
  }

  quitZalo()

  if (isDir(appAsarPath) && (readInstalledState(appAsarPath) || isFile(appAsarBakPath))) {
    info('Updating theme assets in existing unpacked app.asar')
    copyThemeAssets(appAsarPath, theme, fontFamily, fontWeight)
    patchIndexHtml(appAsarPath, theme.id)
    console.log(JSON.stringify({
      ok: true,
      action: 'switch',
      themeId: theme.id,
      fontFamily: fontFamily || 'Maple Mono',
      fontWeight: Number(fontWeight) || 600
    }, null, 2))
    console.log(`\nDone. Applied ${theme.name}. Open Zalo PC.`)
    return
  }

  if (isDir(TMP)) fs.rmSync(TMP, { recursive: true, force: true })
  if (isDir(appAsarPath)) {
    info(`Removing previous unpacked install: ${appAsarPath}`)
    fs.rmSync(appAsarPath, { recursive: true, force: true })
  }
  if (isFile(appAsarBakPath)) {
    if (isFile(appAsarPath)) fs.rmSync(appAsarPath, { force: true })
    info('Restoring original app.asar from app.asar.bak')
    fs.renameSync(appAsarBakPath, appAsarPath)
  }
  if (!isFile(appAsarPath)) die(`app.asar missing at ${appAsarPath}`)

  fs.mkdirSync(TMP, { recursive: true })
  info(`Extracting ${appAsarPath}`)
  asar.uncacheAll()
  asar.extractAll(appAsarPath, extractPath)
  copyThemeAssets(extractPath, theme, fontFamily, fontWeight)
  patchIndexHtml(extractPath, theme.id)
  if (!isFile(appAsarBakPath)) {
    fs.renameSync(appAsarPath, appAsarBakPath)
    info(`Backup created: ${appAsarBakPath}`)
  }
  await fs.move(extractPath, appAsarPath)
  fs.rmSync(TMP, { recursive: true, force: true })
  console.log(JSON.stringify({
    ok: true,
    action: 'install',
    themeId: theme.id,
    fontFamily: fontFamily || 'Maple Mono',
    fontWeight: Number(fontWeight) || 600
  }, null, 2))
  console.log(`\nDone. Applied ${theme.name}. Open Zalo PC.`)
  if (theme.mode === 'light') console.log('Tip: set Zalo appearance to Light for light themes.')
}

function uninstall (zaloAppPath) {
  const resources = getResourcesDir(zaloAppPath)
  const appAsarPath = path.join(resources, 'app.asar')
  const appAsarBakPath = path.join(resources, 'app.asar.bak')
  if (!isFile(appAsarBakPath)) {
    die('No app.asar.bak found. Reinstall Zalo PC to restore (do not delete chat data casually).')
  }
  quitZalo()
  if (fs.existsSync(appAsarPath)) fs.rmSync(appAsarPath, { recursive: true, force: true })
  fs.renameSync(appAsarBakPath, appAsarPath)
  console.log(JSON.stringify({ ok: true, action: 'uninstall', themeId: null }, null, 2))
  console.log('\nRestored original app.asar. Open Zalo PC.')
}

function printHelp (exitCode = 0) {
  console.log(`Usage:
  node install.js list [--mode light|dark]
  node install.js status [Zalo.app]
  node install.js install <theme-id> [Zalo.app] [--font "Family"] [--weight 600]
  node install.js uninstall [Zalo.app]

Themes: ${CATALOG_PATH}
Source: https://terminalcolors.com
Default path: ${DEFAULT_ZALO}`)
  process.exit(exitCode)
}

async function main () {
  const parsed = parseArgs(process.argv.slice(2))
  const cmd = parsed._[0]
  if (!cmd || cmd === '-h' || cmd === '--help') printHelp(0)
  const catalog = loadCatalog()

  try {
    if (cmd === 'list') {
      listThemes(catalog, parsed.flags.mode)
      return
    }
    if (cmd === 'status') {
      printStatus(parsed._[1] || parsed.flags.zalo || DEFAULT_ZALO, catalog)
      return
    }
    if (cmd === 'uninstall') {
      uninstall(parsed._[1] || parsed.flags.zalo || DEFAULT_ZALO)
      return
    }
    if (cmd === 'install') {
      const themeId = parsed._[1]
      if (!themeId) printHelp(1)
      const maybePath = parsed._[2]
      const zaloPath = (maybePath && maybePath.startsWith('/'))
        ? maybePath
        : (parsed.flags.zalo || DEFAULT_ZALO)
      await install(themeId, zaloPath, parsed.flags.font, parsed.flags.weight, catalog)
      return
    }
    printHelp(1)
  } catch (err) {
    die(err.message || String(err))
  }
}

main()
