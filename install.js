#!/usr/bin/env node
/**
 * Zalo PC (macOS) multi-theme installer
 * Maple Font + Rosé Pine (Dawn / Moon / Main)
 *
 * Technique adapted from ZaDark (MPL-2.0):
 * https://github.com/ncdai/zadark
 *
 * Usage:
 *   node install.js list
 *   node install.js status [/Applications/Zalo.app]
 *   node install.js install <theme-id> [/Applications/Zalo.app]
 *   node install.js uninstall [/Applications/Zalo.app]
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

const THEMES = {
  'rose-pine-dawn': {
    id: 'rose-pine-dawn',
    name: 'Rosé Pine Dawn',
    mode: 'light',
    description: 'Warm light pastel'
  },
  'rose-pine-moon': {
    id: 'rose-pine-moon',
    name: 'Rosé Pine Moon',
    mode: 'dark',
    description: 'Soft dark purple'
  },
  'rose-pine': {
    id: 'rose-pine',
    name: 'Rosé Pine',
    mode: 'dark',
    description: 'Classic dark'
  }
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

function themeJsSource (themeId) {
  return `/*
  Zalo Theme — ${THEMES[themeId].name} + Maple Font
*/
(function () {
  const THEME = ${JSON.stringify(themeId)}
  const html = document.documentElement
  const body = document.body

  html.setAttribute('data-zalo-theme', THEME)
  body.classList.add('zalo-theme')
  body.classList.remove('zalo-maple-dawn', 'zalo-maple-dawn--darwin')

  if (html.getAttribute('data-zalo-os') === 'macOS') {
    body.classList.add('zalo-theme--darwin')
  }

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

  head.insertAdjacentHTML(
    'beforeend',
    `<link rel="stylesheet" href="${ASSET_DIR_NAME}/theme.css" ${MARKER}="1">`
  )
  body.insertAdjacentHTML(
    'beforeend',
    `<script src="${ASSET_DIR_NAME}/theme.js" ${MARKER}="1"></script>`
  )

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

function copyThemeAssets (appRoot, themeId) {
  const destAssets = path.join(appRoot, 'pc-dist', ASSET_DIR_NAME)
  fs.ensureDirSync(destAssets)
  fs.copyFileSync(path.join(__dirname, 'assets', 'theme.css'), path.join(destAssets, 'theme.css'))
  fs.writeFileSync(path.join(destAssets, 'theme.js'), themeJsSource(themeId))
  fs.writeJsonSync(path.join(destAssets, STATE_FILE), {
    themeId,
    installedAt: new Date().toISOString(),
    tool: 'zalo-theme-switcher'
  }, { spaces: 2 })
  // Remove legacy folder if present
  const legacy = path.join(appRoot, 'pc-dist', 'zalo-maple-dawn')
  if (isDir(legacy)) fs.rmSync(legacy, { recursive: true, force: true })
  info(`Copied theme assets → ${destAssets} (${themeId})`)
}

function readInstalledTheme (appAsarPath) {
  if (!isDir(appAsarPath)) return null
  const statePath = path.join(appAsarPath, 'pc-dist', ASSET_DIR_NAME, STATE_FILE)
  if (isFile(statePath)) {
    try { return fs.readJsonSync(statePath).themeId || null } catch { return null }
  }
  // legacy dawn-only
  if (isDir(path.join(appAsarPath, 'pc-dist', 'zalo-maple-dawn'))) return 'rose-pine-dawn'
  return null
}

function printStatus (zaloAppPath) {
  const resources = getResourcesDir(zaloAppPath)
  const appAsarPath = path.join(resources, 'app.asar')
  const appAsarBakPath = path.join(resources, 'app.asar.bak')
  const zaloExists = isDir(zaloAppPath)
  const asarFile = isFile(appAsarPath)
  const asarDir = isDir(appAsarPath)
  const hasBackup = isFile(appAsarBakPath)
  const themeId = readInstalledTheme(appAsarPath)

  const status = {
    ok: true,
    zaloPath: zaloAppPath,
    zaloExists,
    appAsarIsFile: asarFile,
    appAsarIsDirectory: asarDir,
    hasBackup,
    themeId,
    themed: Boolean(themeId),
    themes: Object.values(THEMES)
  }

  console.log(JSON.stringify(status, null, 2))
  return status
}

function listThemes () {
  const list = Object.values(THEMES)
  console.log(JSON.stringify({ themes: list }, null, 2))
}

async function install (themeId, zaloAppPath) {
  if (os.platform() !== 'darwin') die('This installer currently targets macOS only.')
  if (!THEMES[themeId]) die(`Unknown theme "${themeId}". Use: ${Object.keys(THEMES).join(', ')}`)

  const resources = getResourcesDir(zaloAppPath)
  const appAsarPath = path.join(resources, 'app.asar')
  const appAsarBakPath = path.join(resources, 'app.asar.bak')
  const extractPath = path.join(TMP, 'app')

  if (!isFile(appAsarPath) && !isDir(appAsarPath) && !isFile(appAsarBakPath)) {
    die(`Neither app.asar nor app.asar.bak found in ${resources}`)
  }

  quitZalo()

  // Fast path: already unpacked + themed → just swap assets
  if (isDir(appAsarPath) && (readInstalledTheme(appAsarPath) || isFile(appAsarBakPath))) {
    info('Updating theme assets in existing unpacked app.asar')
    copyThemeAssets(appAsarPath, themeId)
    patchIndexHtml(appAsarPath, themeId)
    console.log(JSON.stringify({ ok: true, action: 'switch', themeId }, null, 2))
    console.log(`\nDone. Applied ${THEMES[themeId].name}. Open Zalo PC.`)
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

  if (!isFile(appAsarPath)) {
    die(`app.asar missing at ${appAsarPath}`)
  }

  fs.mkdirSync(TMP, { recursive: true })
  info(`Extracting ${appAsarPath}`)
  asar.uncacheAll()
  asar.extractAll(appAsarPath, extractPath)

  copyThemeAssets(extractPath, themeId)
  patchIndexHtml(extractPath, themeId)

  if (!isFile(appAsarBakPath)) {
    fs.renameSync(appAsarPath, appAsarBakPath)
    info(`Backup created: ${appAsarBakPath}`)
  }

  await fs.move(extractPath, appAsarPath)
  fs.rmSync(TMP, { recursive: true, force: true })

  console.log(JSON.stringify({ ok: true, action: 'install', themeId }, null, 2))
  console.log(`\nDone. Applied ${THEMES[themeId].name}. Open Zalo PC.`)
  if (THEMES[themeId].mode === 'light') {
    console.log('Tip: set Zalo appearance to Light for Dawn.')
  }
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
  node install.js list
  node install.js status [Zalo.app path]
  node install.js install <theme-id> [Zalo.app path]
  node install.js uninstall [Zalo.app path]

Themes:
  rose-pine-dawn   Rosé Pine Dawn (light)
  rose-pine-moon   Rosé Pine Moon (soft dark)
  rose-pine        Rosé Pine (dark)

Default path: ${DEFAULT_ZALO}

Requires macOS App Management permission for this app/Terminal.
Re-run after every Zalo update.`)
  process.exit(exitCode)
}

async function main () {
  const argv = process.argv.slice(2)
  const cmd = argv[0]

  if (!cmd || cmd === '-h' || cmd === '--help') printHelp(0)

  try {
    if (cmd === 'list') {
      listThemes()
      return
    }

    if (cmd === 'status') {
      printStatus(argv[1] || DEFAULT_ZALO)
      return
    }

    if (cmd === 'uninstall') {
      uninstall(argv[1] || DEFAULT_ZALO)
      return
    }

    if (cmd === 'install') {
      const themeId = argv[1]
      const zaloPath = argv[2] || DEFAULT_ZALO
      if (!themeId) printHelp(1)
      await install(themeId, zaloPath)
      return
    }

    // Back-compat: `install` without theme used to mean dawn
    printHelp(1)
  } catch (err) {
    die(err.message || String(err))
  }
}

main()
