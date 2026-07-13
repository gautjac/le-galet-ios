// Extra hero pebbles for the Carrousel landing page — NOT the App Store set.
// Renders three more family photos (through the app's photo-display treatment:
// caption + resting clock + bottom scrim) and a new Reminders card, then
// downscales each to the 1600×1200 landing pebble format used by index.html.
//
//   node gen-extra.mjs
//
// Output: ../../landing/assets/{06-ski,07-beach,08-birthday,09-reminder}-{en,fr}.jpg
// Mirrors the scene language + palette of generate.mjs so the new pebbles sit
// seamlessly beside 01-photo / 02-quote / 03-event.
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync, rmSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const LANDING = resolve(HERE, '../../landing/assets')
const TMP = resolve(HERE, '.tmp-extra')
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const W = 2752, H = 2064

rmSync(TMP, { recursive: true, force: true }); mkdirSync(TMP, { recursive: true })

// palette (from generate.mjs / LeGalet/Theme/Palette.swift), + reminder greens
const C = {
  stoneBase:'#1C1D22', stoneDeep:'#141519', mist:'#D9D3C8', mistSoft:'#A8A298',
  quoteInk:'#ECE6DB', amber:'#CD9A5C', amberSoft:'#E0C39B',
  reminderTop:'#1E3F39', reminderBot:'#15302B', reminderAccent:'#8FB3A1',
}
const SERIF = `ui-serif, "New York", Georgia, serif`
const SANS = `-apple-system, "SF Pro Text", system-ui, sans-serif`
const img = (name) => `file://${resolve(HERE, 'assets/' + name)}`

// an open to-do circle with a check — the "a reminder is due" glyph
const rem = (col) => `<svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="${col}" stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8.6"/><path d="M8.4 12.3l2.5 2.5 4.7-5.2"/></svg>`

// ── scenes ───────────────────────────────────────────────────────────────────
function photoScene(file, caption, clock, pos) {
  return `<div class="canvas photo">
    <div class="realphoto" style="background:#181109 url('${img(file)}') center ${pos}/cover no-repeat"></div>
    <div class="botscrim"></div>
    <div class="pcap">${caption}</div>
    <div class="clock">${clock}</div>
  </div>`
}
function reminderScene(title, sub) {
  return `<div class="canvas glow">
    <div class="cardwrap"><div class="card rcard">
      ${rem(C.reminderAccent)}
      <div class="rule rrule"></div>
      <div class="ctitle">${title}</div>
      <div class="csub">${sub}</div>
    </div></div>
  </div>`
}

const items = {
  en: [
    { slug:'06-ski',      scene: photoScene('photo-ski.png',      'February 2024 · Mont-Sainte-Anne', '09:15', '46%') },
    { slug:'07-beach',    scene: photoScene('photo-beach.png',    'July 2023 · Kouchibouguac',        '18:47', '52%') },
    { slug:'08-birthday', scene: photoScene('photo-birthday.png', 'May 2024 · at home',               '18:30', '54%') },
    { slug:'09-reminder', scene: reminderScene('Pick up the dry cleaning', 'TODAY · BEFORE 5:00 PM') },
  ],
  fr: [
    { slug:'06-ski',      scene: photoScene('photo-ski.png',      'Février 2024 · Mont-Sainte-Anne',  '09:15', '46%') },
    { slug:'07-beach',    scene: photoScene('photo-beach.png',    'Juillet 2023 · Kouchibouguac',     '18:47', '52%') },
    { slug:'08-birthday', scene: photoScene('photo-birthday.png', 'Mai 2024 · à la maison',           '18:30', '54%') },
    { slug:'09-reminder', scene: reminderScene('Passer chercher le nettoyage à sec', 'AUJOURD’HUI · AVANT 17 H') },
  ],
}

// ── page shell (CLEAN: no marketing headline; card vertically centred) ─────────
function page(inner) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${W}px;height:${H}px;overflow:hidden;background:${C.stoneDeep}}
  .canvas{position:relative;width:${W}px;height:${H}px;overflow:hidden;font-family:${SANS}}
  .glow{background:radial-gradient(120% 90% at 50% 38%, #24201b 0%, ${C.stoneBase} 42%, ${C.stoneDeep} 100%)}
  .photo{background:#181109}
  .realphoto{position:absolute;inset:0;filter:saturate(1.03) brightness(.98)}
  .botscrim{position:absolute;inset:0;background:linear-gradient(transparent 50%, ${C.stoneDeep}cc 100%)}
  .pcap{position:absolute;left:0;right:0;bottom:230px;text-align:center;color:${C.quoteInk}e8;font:300 italic 56px/1 ${SERIF}}
  .clock{position:absolute;left:0;right:0;bottom:120px;text-align:center;color:${C.mist}99;font:200 88px/1 ${SANS};letter-spacing:2px}
  .cardwrap{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}
  .card{width:1180px;padding:96px 92px;border-radius:60px;text-align:center;
     box-shadow:0 40px 90px rgba(0,0,0,.5);display:flex;flex-direction:column;align-items:center}
  .rcard{background:linear-gradient(${C.reminderTop},${C.reminderBot});border:2px solid ${C.reminderAccent}4d}
  .rule{width:78px;height:2px;margin:34px 0 40px}
  .rrule{background:${C.reminderAccent}b0}
  .ctitle{color:${C.quoteInk};font:300 84px/1.1 ${SANS}}
  .csub{margin-top:30px;color:${C.mistSoft};font:400 38px/1 ${SANS};letter-spacing:3px}
  </style></head><body>${inner}</body></html>`
}

// ── render → downscale → landing/assets ────────────────────────────────────────
let n = 0
for (const lang of ['en', 'fr']) {
  for (const it of items[lang]) {
    const html = page(it.scene)
    const htmlPath = resolve(TMP, `${it.slug}-${lang}.html`)
    const pngPath  = resolve(TMP, `${it.slug}-${lang}.png`)
    writeFileSync(htmlPath, html)
    execFileSync(CHROME, [
      '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
      `--window-size=${W},${H}`, `--screenshot=${pngPath}`, `file://${htmlPath}`,
    ], { stdio: 'ignore' })
    const jpg = resolve(LANDING, `${it.slug}-${lang}.jpg`)
    execFileSync('sips', ['-s', 'format', 'jpeg', '-s', 'formatOptions', '82', '-z', '1200', '1600', pngPath, '--out', jpg], { stdio: 'ignore' })
    n++
    console.log('✓', jpg.replace(resolve(HERE, '../../') + '/', ''))
  }
}
rmSync(TMP, { recursive: true, force: true })
console.log(`\nDone — ${n} landing pebbles in landing/assets/ (1600×1200 JPG).`)
