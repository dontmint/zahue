#!/usr/bin/env node
/**
 * Minimal Zalo PC (macOS) theme installer
 * Maple Font + Rosé Pine Dawn
 *
 * Technique adapted from ZaDark (MPL-2.0):
 * https://github.com/ncdai/zadark
 *
 * Usage:
 *   node install.js install
 *   node install.js uninstall
 *   node install.js install /Applications/Zalo.app
 */

const os = require('os')
const path = require('path')
const fs = require('fs-extra')
const asar = require('@electron/asar')
const HTMLParser = require('node-html-parser')
const { spawnSync } = require('child_process')

const THEME_ID = 'zalo-maple-dawn'
const MARKER = `data-${THEME_ID}`
const DEFAULT_ZALO = '/Applications/Zalo.app'
const TMP = path.join(os.homedir(), `${THEME_ID}-tmp`)

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

function cleanInjected (head, body) {
  head.querySelectorAll(`link[${MARKER}]`).forEach((el) => el.remove())
  body.querySelectorAll(`script[${MARKER}]`).forEach((el) => el.remove())
  // legacy cleanup if re-installing
  head.querySelectorAll('link[href*="zalo-maple-dawn"]').forEach((el) => el.remove())
  body.querySelectorAll('script[src*="zalo-maple-dawn"]').forEach((el) => el.remove())
}

function patchIndexHtml (appRoot) {
  const indexPath = path.join(appRoot, 'pc-dist', 'index.html')
  if (!isFile(indexPath)) die(`Missing ${indexPath}`)

  const root = HTMLParser.parse(fs.readFileSync(indexPath, 'utf8'))
  const html = root.getElementsByTagName('html')[0]
  const head = root.getElementsByTagName('head')[0]
  const body = root.getElementsByTagName('body')[0]

  cleanInjected(head, body)

  head.insertAdjacentHTML(
    'beforeend',
    `<link rel="stylesheet" href="zalo-maple-dawn/theme.css" ${MARKER}="1">`
  )
  body.insertAdjacentHTML(
    'beforeend',
    `<script src="zalo-maple-dawn/theme.js" ${MARKER}="1"></script>`
  )

  html.setAttribute('data-zalo-os', 'macOS')
  html.setAttribute('data-zalo-theme', 'rose-pine-dawn')
  body.classList.add('zalo-maple-dawn', 'zalo-maple-dawn--darwin')

  // Soften CSP enough for local assets (usually already fine for relative hrefs)
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

async function install (zaloAppPath) {
  if (os.platform() !== 'darwin') die('This installer currently targets macOS only.')

  const resources = getResourcesDir(zaloAppPath)
  const appAsarPath = path.join(resources, 'app.asar')
  const appAsarBakPath = path.join(resources, 'app.asar.bak')
  const extractPath = path.join(TMP, 'app')

  if (!isFile(appAsarPath) && !isFile(appAsarBakPath)) {
    die(`Neither app.asar nor app.asar.bak found in ${resources}`)
  }

  quitZalo()

  if (isDir(TMP)) fs.rmSync(TMP, { recursive: true, force: true })
  if (isDir(appAsarPath)) fs.rmSync(appAsarPath, { recursive: true, force: true })

  // Always start from pristine backup when available
  if (isFile(appAsarPath) && isFile(appAsarBakPath)) {
    fs.rmSync(appAsarPath, { force: true })
    fs.renameSync(appAsarBakPath, appAsarPath)
  }

  if (!isFile(appAsarPath)) die(`app.asar missing at ${appAsarPath}`)

  fs.mkdirSync(TMP, { recursive: true })
  info(`Extracting ${appAsarPath}`)
  asar.uncacheAll()
  asar.extractAll(appAsarPath, extractPath)

  const destAssets = path.join(extractPath, 'pc-dist', 'zalo-maple-dawn')
  fs.copySync(path.join(__dirname, 'assets'), destAssets)
  info(`Copied theme assets → ${destAssets}`)

  patchIndexHtml(extractPath)

  if (!isFile(appAsarBakPath)) {
    fs.renameSync(appAsarPath, appAsarBakPath)
    info(`Backup created: ${appAsarBakPath}`)
  }

  // Keep unpacked directory named app.asar (same as ZaDark; avoids clipboard image bugs)
  await fs.move(extractPath, appAsarPath)
  fs.rmSync(TMP, { recursive: true, force: true })

  console.log('\nDone. Open Zalo PC.')
  console.log('Tip: set Zalo appearance to Light before judging colors.')
  console.log('Font: install Maple Mono locally for best results:')
  console.log('  https://github.com/subframe7536/maple-font')
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
  console.log('\nRestored original app.asar. Open Zalo PC.')
}

function printHelp (exitCode = 0) {
  console.log(`Usage:
  node install.js install [Zalo.app path]
  node install.js uninstall [Zalo.app path]

Default path: ${DEFAULT_ZALO}

Requires macOS App Management permission for Terminal (or sudo).
Re-run after every Zalo update.`)
  process.exit(exitCode)
}

async function main () {
  const [cmd, zaloPathArg] = process.argv.slice(2)
  const zaloPath = zaloPathArg || DEFAULT_ZALO

  if (!cmd || cmd === '-h' || cmd === '--help') printHelp(0)
  if (!['install', 'uninstall'].includes(cmd)) printHelp(1)

  try {
    if (cmd === 'install') await install(zaloPath)
    if (cmd === 'uninstall') uninstall(zaloPath)
  } catch (err) {
    die(err.message || String(err))
  }
}

main()
