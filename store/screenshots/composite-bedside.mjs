// Composites a real Carrousel screen onto the (near front-facing) iPad in the
// generated bedside scene (bedside-raw.png). The tablet faces the camera almost
// straight on, so a placed screen rectangle seats cleanly — no projective warp
// needed. Renders with headless Chrome; writes language-aware night lifestyle
// images into landing/assets.
//
//   node composite-bedside.mjs
import { execFileSync } from 'node:child_process'
import { writeFileSync, rmSync, mkdirSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const LANDING = resolve(HERE, '../../landing/assets')
const TMP = resolve(HERE, '.tmp-bed')
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const W = 1376, H = 768
rmSync(TMP, { recursive: true, force: true }); mkdirSync(TMP, { recursive: true })

const bg = `file://${resolve(HERE, 'assets/bedside-raw.png')}`

// iPad inner-screen box in bedside-raw px space (tablet is ~front-facing)
const S = { left: 600, top: 273, width: 368, height: 286, radius: 9, tilt: -0.8 }

function page(screenFile){
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0}
  html,body{width:${W}px;height:${H}px;overflow:hidden;background:#000}
  .stage{position:relative;width:${W}px;height:${H}px}
  .bgimg{position:absolute;inset:0;width:${W}px;height:${H}px}
  .screen{position:absolute;left:${S.left}px;top:${S.top}px;width:${S.width}px;height:${S.height}px;
    transform:perspective(1500px) rotateY(${S.tilt}deg);transform-origin:50% 50%;border-radius:${S.radius}px}
  .screen img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;display:block;border-radius:${S.radius}px;
    filter:brightness(.8) saturate(.94) contrast(1.02)}
  .screen .tint{position:absolute;inset:0;border-radius:${S.radius}px;
    background:radial-gradient(72% 64% at 50% 44%,rgba(120,92,52,.13),transparent 72%),
      linear-gradient(180deg,rgba(10,11,14,.08),rgba(10,11,14,.30))}
  .screen .sheen{position:absolute;inset:0;border-radius:${S.radius}px;pointer-events:none;
    background:linear-gradient(122deg,rgba(255,250,240,.09) 0%,rgba(255,250,240,.02) 15%,transparent 36%)}
  .screen .edge{position:absolute;inset:0;border-radius:${S.radius}px;box-shadow:inset 0 0 16px rgba(0,0,0,.5),inset 0 0 0 1px rgba(0,0,0,.4)}
  </style></head><body>
    <div class="stage">
      <img class="bgimg" src="${bg}">
      <div class="screen">
        <img src="file://${screenFile}">
        <div class="tint"></div><div class="sheen"></div><div class="edge"></div>
      </div>
    </div>
  </body></html>`
}

let n = 0
for (const lang of ['en', 'fr']) {
  const screenFile = resolve(LANDING, `02-quote-${lang}.jpg`)  // a calm quote reads right at night
  const htmlPath = resolve(TMP, `bed-${lang}.html`)
  const pngPath  = resolve(TMP, `bed-${lang}.png`)
  writeFileSync(htmlPath, page(screenFile))
  execFileSync(CHROME, [
    '--headless=new','--disable-gpu','--hide-scrollbars','--force-device-scale-factor=1',
    `--window-size=${W},${H}`, `--screenshot=${pngPath}`, `file://${htmlPath}`,
  ], { stdio: 'ignore' })
  const jpg = resolve(LANDING, `bedside-night-${lang}.jpg`)
  execFileSync('sips', ['-s','format','jpeg','-s','formatOptions','86', pngPath, '--out', jpg], { stdio: 'ignore' })
  n++
  console.log('✓', jpg.replace(resolve(HERE,'../../')+'/',''))
}
rmSync(TMP, { recursive: true, force: true })
console.log(`\nDone — ${n} bedside composites.`)
