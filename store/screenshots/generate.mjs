// Generates App Store screenshots for Carousel / Carrousel.
// 5 scenes × 2 languages, 2752×2064 (13-inch iPad, landscape), rendered with
// headless Chrome so the type is real SF / New York — the same faces the app uses.
//
//   node generate.mjs
//
// Output: ./out/NN-scene-lang.png
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync, rmSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
// CLEAN=1 omits the marketing headline band → pure app screens for the web page,
// where the landing page's own type carries the message.
const CLEAN = !!process.env.CLEAN
const OUT = resolve(HERE, CLEAN ? 'out-clean' : 'out')
const TMP = resolve(HERE, '.tmp')
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const W = 2752, H = 2064

rmSync(OUT, { recursive: true, force: true }); mkdirSync(OUT, { recursive: true })
rmSync(TMP, { recursive: true, force: true }); mkdirSync(TMP, { recursive: true })

// ── palette (from LeGalet/Theme/Palette.swift) ──────────────────────────────
const C = {
  stoneBase:'#1C1D22', stoneDeep:'#141519', stoneRaise:'#23242A', stoneCard:'#2B2C33',
  stoneLine:'#3E3F48', mist:'#D9D3C8', mistSoft:'#A8A298', mistFaint:'#938C81',
  quoteInk:'#ECE6DB', amber:'#CD9A5C', amberSoft:'#E0C39B', slate:'#6F8190',
  slateSoft:'#9AA9B5', eventTop:'#1C3D49', eventBot:'#142D37',
}
const SERIF = `ui-serif, "New York", Georgia, serif`
const SANS = `-apple-system, "SF Pro Text", system-ui, sans-serif`
const PHOTO = `file://${resolve(HERE, 'assets/photo-lake.png')}` // a real photo for the hero shot

const cal = (col) => `<svg width="78" height="78" viewBox="0 0 24 24" fill="none" stroke="${col}" stroke-width="1.1" stroke-linecap="round"><rect x="3" y="4.5" width="18" height="16" rx="2.5"/><path d="M3 9h18M8 2.5v4M16 2.5v4"/></svg>`

// ── scene builders: each returns the inner HTML of the full-bleed canvas ─────
function chrome(eyebrow, headline){
  if (CLEAN) return ''   // pure app screen — the landing page supplies the copy
  return `<div class="top">
    <div class="scrim"></div>
    <div class="eyebrow">${eyebrow}</div>
    <div class="headline">${headline}</div>
  </div>`
}

const scenes = {
  photo: (t) => `
    <div class="canvas photo">
      <div class="realphoto"></div>
      <div class="botscrim"></div>
      ${chrome(t.eyebrow, t.headline)}
      <div class="pcap">${t.caption}</div>
      <div class="clock">16:42</div>
    </div>`,

  quote: (t) => `
    <div class="canvas glow">
      ${chrome(t.eyebrow, t.headline)}
      <div class="qwrap">
        <div class="quote">${t.quote}</div>
        <div class="byline">${t.author}</div>
      </div>
    </div>`,

  event: (t) => `
    <div class="canvas glow">
      ${chrome(t.eyebrow, t.headline)}
      <div class="cardwrap">
        <div class="card">
          ${cal(C.amber)}
          <div class="rule"></div>
          <div class="ctitle">${t.title}</div>
          <div class="csub">${t.sub}</div>
          <div class="hair"></div>
          <div class="cnote">${t.note}</div>
        </div>
      </div>
    </div>`,

  composer: (t) => `
    <div class="canvas glow">
      ${chrome(t.eyebrow, t.headline)}
      <div class="panel">
        ${t.rows.map(r => `
          <div class="row">
            <div class="thumb" style="background:${r.bg}">${r.glyph||''}</div>
            <div class="rlabel"><div class="rname">${r.name}</div><div class="rkind">${r.kind}</div></div>
            <div class="dots">${[0,1,2].map(i=>`<span class="dot ${i<r.weight?'on':''}"></span>`).join('')}</div>
          </div>`).join('')}
      </div>
    </div>`,

  settings: (t) => `
    <div class="canvas glow">
      ${chrome(t.eyebrow, t.headline)}
      <div class="panel">
        <div class="scard">
          <div class="slabel">${t.dayNight}</div>
          <div class="daynight"><span class="sun">☀</span><span class="moon">☾</span></div>
        </div>
        <div class="scard">
          <div class="slabel">${t.textSize}</div>
          <div class="slider"><span class="aSmall">A</span><div class="track"><div class="fill"></div><div class="knob"></div></div><span class="aBig">A</span></div>
        </div>
        <div class="scard">
          <div class="slabel">${t.pace}</div>
          <div class="slider"><div class="track wide"><div class="fill third"></div><div class="knob third"></div></div></div>
        </div>
      </div>
    </div>`,
}

// ── copy ────────────────────────────────────────────────────────────────────
const COPY = {
  en: {
    photo: { eyebrow:'YOUR PHOTOS, STAYING YOURS', headline:'Your own photos, drifting by.', caption:'June 2024 · Montréal' },
    quote: { eyebrow:'WORDS WORTH KEEPING', headline:'A line worth keeping.', quote:'Not till we are lost do we begin to find ourselves.', author:'HENRY DAVID THOREAU' },
    event: { eyebrow:'THE DAY, GENTLY SURFACED', headline:'Today, gently surfaced.', title:"Dinner at Grandma's", sub:'TODAY · 6:30 – 8:00 PM', note:'Bring the photo albums.' },
    composer: { eyebrow:'YOU CURATE IT', headline:'You choose what drifts.',
      rows:[ {name:'Summer at the lake', kind:'Album · 64 photos', bg:'linear-gradient(135deg,#7d6b53,#3a3128)', weight:3},
             {name:'A line from Thoreau', kind:'Quote', bg:C.stoneRaise, glyph:'“', weight:2},
             {name:"Today's calendar", kind:'Events', bg:'linear-gradient(135deg,#1C3D49,#142D37)', glyph:'', weight:2},
             {name:'Reminders', kind:'Due soon', bg:'linear-gradient(135deg,#1E3F39,#15302B)', glyph:'', weight:1} ] },
    settings: { eyebrow:'CALM BY DESIGN', headline:'Calm by day, dim by night.', dayNight:'Day → Night warmth', textSize:'Text size', pace:'Pace' },
  },
  fr: {
    photo: { eyebrow:'VOS PHOTOS, QUI RESTENT LES VÔTRES', headline:'Vos propres photos, qui dérivent.', caption:'Juin 2024 · Montréal' },
    quote: { eyebrow:'DES MOTS À GARDER', headline:'Une parole à garder.', quote:'La vie est une fleur dont l’amour est le miel.', author:'VICTOR HUGO' },
    event: { eyebrow:'LA JOURNÉE, EN DOUCEUR', headline:'Aujourd’hui, tout en douceur.', title:'Souper chez Mamie', sub:'AUJOURD’HUI · 18 H 30 – 20 H', note:'Apporter les albums photo.' },
    composer: { eyebrow:'VOUS CHOISISSEZ', headline:'Vous choisissez ce qui dérive.',
      rows:[ {name:'Été au chalet', kind:'Album · 64 photos', bg:'linear-gradient(135deg,#7d6b53,#3a3128)', weight:3},
             {name:'Une parole de Hugo', kind:'Citation', bg:C.stoneRaise, glyph:'“', weight:2},
             {name:'Le calendrier du jour', kind:'Événements', bg:'linear-gradient(135deg,#1C3D49,#142D37)', glyph:'', weight:2},
             {name:'Rappels', kind:'Bientôt dus', bg:'linear-gradient(135deg,#1E3F39,#15302B)', glyph:'', weight:1} ] },
    settings: { eyebrow:'CALME PAR NATURE', headline:'Calme le jour, tamisé la nuit.', dayNight:'Chaleur jour → nuit', textSize:'Taille du texte', pace:'Rythme' },
  },
}

// ── page shell + CSS ─────────────────────────────────────────────────────────
function page(inner){
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:${W}px;height:${H}px;overflow:hidden;background:${C.stoneDeep}}
  .canvas{position:relative;width:${W}px;height:${H}px;overflow:hidden;font-family:${SANS}}
  .glow{background:radial-gradient(120% 90% at 50% 38%, #24201b 0%, ${C.stoneBase} 42%, ${C.stoneDeep} 100%)}
  /* top headline */
  .top{position:absolute;top:0;left:0;right:0;height:520px;z-index:5;text-align:center}
  .scrim{position:absolute;inset:0;background:linear-gradient(${C.stoneDeep}f2, ${C.stoneDeep}6e 46%, transparent)}
  .eyebrow{position:relative;margin-top:150px;color:${C.amber};font:600 30px/1 ${SANS};letter-spacing:8px}
  .headline{position:relative;margin-top:34px;color:${C.mist};font:300 92px/1.05 ${SERIF};letter-spacing:.5px}
  /* photo scene */
  .photo{background:#181109}
  .realphoto{position:absolute;inset:0;background:url("${PHOTO}") center 42%/cover no-repeat;filter:saturate(1.03) brightness(.98)}
  .botscrim{position:absolute;inset:0;background:linear-gradient(transparent 50%, ${C.stoneDeep}cc 100%)}
  .pcap{position:absolute;left:0;right:0;bottom:230px;text-align:center;color:${C.quoteInk}e8;font:300 italic 56px/1 ${SERIF}}
  .clock{position:absolute;left:0;right:0;bottom:120px;text-align:center;color:${C.mist}99;font:200 88px/1 ${SANS};letter-spacing:2px}
  /* quote scene */
  .qwrap{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:0 14%}
  .quote{color:${C.quoteInk};font:300 116px/1.32 ${SERIF};text-align:center;max-width:1900px}
  .byline{margin-top:64px;color:${C.amber}d9;font:300 34px/1 ${SANS};letter-spacing:7px}
  /* event card */
  .cardwrap{position:absolute;inset:0;display:flex;align-items:center;justify-content:center}
  .card{margin-top:120px;width:1180px;padding:96px 92px;border-radius:60px;text-align:center;
     background:linear-gradient(${C.eventTop},${C.eventBot});border:2px solid ${C.amber}47;
     box-shadow:0 40px 90px rgba(0,0,0,.5);display:flex;flex-direction:column;align-items:center}
  .rule{width:78px;height:2px;background:${C.amber}8c;margin:34px 0 40px}
  .ctitle{color:${C.quoteInk};font:300 84px/1.1 ${SANS}}
  .csub{margin-top:30px;color:${C.mistSoft};font:400 38px/1 ${SANS};letter-spacing:3px}
  .hair{width:52px;height:1px;background:${C.amber}40;margin:46px 0 36px}
  .cnote{color:${C.mist}d2;font:300 44px/1.4 ${SANS};max-width:760px}
  /* composer + settings panels */
  .panel{position:absolute;left:50%;top:560px;transform:translateX(-50%);width:1760px;display:flex;flex-direction:column;gap:30px}
  .row{display:flex;align-items:center;gap:42px;background:${C.stoneCard};border:1px solid ${C.stoneLine};border-radius:34px;padding:38px 50px}
  .thumb{width:128px;height:128px;border-radius:24px;flex:0 0 auto;display:flex;align-items:center;justify-content:center;color:${C.mistSoft};font:300 90px/1 ${SERIF}}
  .rlabel{flex:1 1 auto;text-align:left}
  .rname{color:${C.mist};font:400 52px/1.1 ${SANS}}
  .rkind{margin-top:12px;color:${C.mistFaint};font:400 32px/1 ${SANS}}
  .dots{display:flex;gap:18px}
  .dot{width:30px;height:30px;border-radius:50%;background:${C.stoneLine}}
  .dot.on{background:${C.amber}}
  .scard{background:${C.stoneCard};border:1px solid ${C.stoneLine};border-radius:34px;padding:54px 60px}
  .slabel{color:${C.mist};font:400 46px/1 ${SANS};margin-bottom:44px}
  .daynight{height:70px;border-radius:35px;background:linear-gradient(90deg,${C.amber},#9c8a78,${C.slate});position:relative;display:flex;align-items:center;justify-content:space-between;padding:0 36px;color:#1c1d22;font-size:42px}
  .slider{display:flex;align-items:center;gap:40px}
  .aSmall{color:${C.mistSoft};font:400 40px/1 ${SANS}}
  .aBig{color:${C.mistSoft};font:400 80px/1 ${SANS}}
  .track{position:relative;flex:1;height:14px;border-radius:7px;background:${C.stoneLine}}
  .track.wide{flex:1}
  .fill{position:absolute;left:0;top:0;bottom:0;width:62%;border-radius:7px;background:${C.amber}}
  .fill.third{width:38%}
  .knob{position:absolute;top:50%;left:62%;transform:translate(-50%,-50%);width:54px;height:54px;border-radius:50%;background:${C.amberSoft};box-shadow:0 6px 16px rgba(0,0,0,.5)}
  .knob.third{left:38%}
  /* clean mode: no headline band, so re-centre the content vertically */
  .clean .panel{top:50%;transform:translate(-50%,-50%)}
  .clean .card{margin-top:0}
  </style></head><body class="${CLEAN?'clean':''}">${inner}</body></html>`
}

// ── render ───────────────────────────────────────────────────────────────────
const order = ['photo','quote','event','composer','settings']
let n = 0
for (const lang of ['en','fr']) {
  let i = 0
  for (const key of order) {
    i++
    const html = page(scenes[key](COPY[lang][key]))
    const htmlPath = resolve(TMP, `${key}-${lang}.html`)
    const pngPath = resolve(OUT, `${String(i).padStart(2,'0')}-${key}-${lang}.png`)
    writeFileSync(htmlPath, html)
    execFileSync(CHROME, [
      '--headless=new','--disable-gpu','--hide-scrollbars','--force-device-scale-factor=1',
      `--window-size=${W},${H}`, `--screenshot=${pngPath}`, `file://${htmlPath}`,
    ], { stdio: 'ignore' })
    n++
    console.log('✓', pngPath.replace(HERE+'/',''))
  }
}
rmSync(TMP, { recursive: true, force: true })
console.log(`\nDone — ${n} screenshots in store/screenshots/out/ (${W}×${H}).`)
