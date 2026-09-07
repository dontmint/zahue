/*
  Zalo Theme — Maple Font + Rosé Pine Dawn
*/
(function () {
  const THEME = 'rose-pine-dawn'
  const html = document.documentElement
  const body = document.body

  html.setAttribute('data-zalo-theme', THEME)
  body.classList.add('zalo-maple-dawn')

  if (html.getAttribute('data-zalo-os') === 'macOS') {
    body.classList.add('zalo-maple-dawn--darwin')
  }

  console.info('[zalo-maple-dawn] Rosé Pine Dawn + Maple Font active')
})()
