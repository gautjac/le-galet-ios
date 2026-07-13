// Open Graph / Twitter share image for the Carrousel landing (1200×630).
// Candle-lit card: wordmark + tagline beside a framed landscape iPad showing a
// real app screen. Rendered with headless Chrome → landing/assets/share.jpg.
//   node share-card.mjs
import { execFileSync } from 'node:child_process'
import { writeFileSync, rmSync, mkdirSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const LANDING = resolve(HERE, '../../landing/assets')
const TMP = resolve(HERE, '.tmp-share')
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const W = 1200, H = 630
rmSync(TMP, { recursive: true, force: true }); mkdirSync(TMP, { recursive: true })

const SCREEN = `file://${resolve(LANDING, '01-photo-fr.jpg')}`  // warm lake photo pebble

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  :root{--bg:#131418;--ink:#F0EADF;--muted:#ABA59A;--amber:#D3A567;--amber2:#E6C9A0;
    --serif:ui-serif,"New York",Georgia,serif;--sans:-apple-system,"SF Pro Text",system-ui,sans-serif}
  html,body{width:${W}px;height:${H}px;overflow:hidden;background:var(--bg)}
  .card{position:relative;width:${W}px;height:${H}px;display:flex;align-items:center;gap:44px;
    padding:0 76px;font-family:var(--sans)}
  .card::before{content:"";position:absolute;inset:0;
    background:radial-gradient(120% 80% at 22% -10%,rgba(160,120,70,.24),transparent 55%),
      radial-gradient(90% 70% at 100% 120%,rgba(70,84,96,.12),transparent 60%)}
  .copy{position:relative;flex:0 0 auto;width:470px}
  .eyebrow{font-weight:600;font-size:19px;letter-spacing:.22em;text-transform:uppercase;color:var(--amber);margin-bottom:22px}
  h1{font-family:var(--serif);font-weight:400;color:var(--ink);font-size:96px;line-height:.98;letter-spacing:-.02em}
  .tag{margin-top:26px;font-size:30px;line-height:1.4;color:var(--muted);max-width:22ch}
  .stage{position:relative;flex:1;display:flex;justify-content:center}
  .ipad{position:relative;width:560px;aspect-ratio:4/3;padding:2.1%;border-radius:30px;
    background:linear-gradient(145deg,#43454c,#24262c 38%,#1b1d22 62%,#35373e);
    box-shadow:inset 0 0 0 1px rgba(255,255,255,.1),inset 0 0 0 3px rgba(0,0,0,.55),
      0 40px 80px -30px rgba(0,0,0,.85)}
  .cam{position:absolute;top:10px;left:50%;transform:translateX(-50%);width:6px;height:6px;border-radius:50%;
    background:radial-gradient(circle at 40% 35%,#3a4652,#10151b 60%,#05070a);z-index:3}
  .screen{position:relative;width:100%;height:100%;border-radius:15px;overflow:hidden;background:#16171c}
  .screen img{width:100%;height:100%;object-fit:cover;display:block}
  .glass{position:absolute;inset:0;border-radius:15px;
    background:linear-gradient(120deg,rgba(255,255,255,.06),rgba(255,255,255,.015) 18%,transparent 40%)}
</style></head><body>
  <div class="card">
    <div class="copy">
      <div class="eyebrow">Pour iPad</div>
      <h1>Carrousel</h1>
      <div class="tag">Vos photos et votre journée, une chose calme à la fois.</div>
    </div>
    <div class="stage">
      <div class="ipad">
        <span class="cam"></span>
        <div class="screen"><img src="${SCREEN}"><div class="glass"></div></div>
      </div>
    </div>
  </div>
</body></html>`

const htmlPath = resolve(TMP, 'share.html')
const pngPath = resolve(TMP, 'share.png')
writeFileSync(htmlPath, html)
execFileSync(CHROME, ['--headless=new','--disable-gpu','--hide-scrollbars','--force-device-scale-factor=1',
  `--window-size=${W},${H}`, `--screenshot=${pngPath}`, `file://${htmlPath}`], { stdio: 'ignore' })
execFileSync('sips', ['-s','format','jpeg','-s','formatOptions','88', pngPath, '--out', resolve(LANDING, 'share.jpg')], { stdio: 'ignore' })
rmSync(TMP, { recursive: true, force: true })
console.log('✓ landing/assets/share.jpg (1200×630)')
