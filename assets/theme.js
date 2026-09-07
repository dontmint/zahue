/*
  Zalo Theme — default bootstrap (Dawn)
  install.js rewrites this per selected theme.
*/
(function () {
  const THEME = 'rose-pine-dawn'
  const html = document.documentElement
  const body = document.body

  html.setAttribute('data-zalo-theme', THEME)
  body.classList.add('zalo-theme')

  if (html.getAttribute('data-zalo-os') === 'macOS') {
    body.classList.add('zalo-theme--darwin')
  }

  console.info('[zalo-theme]', THEME, 'active')
})()
