// Carrousel — landing copy editor (local, not deployed).
// Serves the real landing in an iframe for live editing, patches the edited
// FR/EN copy straight back into ../landing/index.html (with a backup), and can
// deploy to Netlify. Page copy only — it never touches structure, CSS, or the
// iPad rotation. Dependency-free.
//
//   node server.mjs   →   http://127.0.0.1:4620
import { createServer } from 'node:http'
import { readFile, writeFile, mkdir, copyFile, stat } from 'node:fs/promises'
import { exec } from 'node:child_process'
import { dirname, resolve, extname, normalize } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const APP = resolve(HERE, '..')                 // le-galet-ios
const LANDING = resolve(APP, 'landing')
const INDEX = resolve(LANDING, 'index.html')
const BACKUPS = resolve(HERE, 'backups')
const PORT = 4620
const SITE_ID = '27099727-9f62-4bbe-84f1-94bf3b66ebf1'

const TYPES = {
  '.html':'text/html; charset=utf-8', '.css':'text/css; charset=utf-8',
  '.js':'text/javascript; charset=utf-8', '.mjs':'text/javascript; charset=utf-8',
  '.json':'application/json; charset=utf-8', '.jpg':'image/jpeg', '.jpeg':'image/jpeg',
  '.png':'image/png', '.svg':'image/svg+xml', '.ico':'image/x-icon',
  '.webmanifest':'application/manifest+json', '.woff2':'font/woff2', '.txt':'text/plain; charset=utf-8',
}

// ── the one load-bearing routine: locate every editable FR/EN span's inner
// range in the source, depth-aware so nested <span class="soft"> is handled. ──
function editableRanges(src) {
  const ranges = []
  const openTarget = /<span class="(?:fr|en)">/g
  let m
  while ((m = openTarget.exec(src))) {
    const innerStart = m.index + m[0].length
    const tok = /<span\b|<\/span>/g
    tok.lastIndex = innerStart
    let depth = 1, innerEnd = -1, t
    while ((t = tok.exec(src))) {
      if (t[0][1] === '/') { if (--depth === 0) { innerEnd = t.index; break } }
      else depth++
    }
    if (innerEnd === -1) throw new Error(`unbalanced span near offset ${m.index}`)
    ranges.push([innerStart, innerEnd])
    openTarget.lastIndex = innerEnd
  }
  return ranges
}

const balancedSpans = (html) =>
  (html.match(/<span\b/g)?.length || 0) === (html.match(/<\/span>/g)?.length || 0)

function readBody(req) {
  return new Promise((res, rej) => {
    let b = ''; req.on('data', c => { b += c; if (b.length > 5e6) req.destroy() })
    req.on('end', () => res(b)); req.on('error', rej)
  })
}
const json = (r, code, obj) => { r.writeHead(code, { 'content-type': 'application/json' }); r.end(JSON.stringify(obj)) }

async function handleSave(req, res) {
  const { count, edits } = JSON.parse(await readBody(req) || '{}')
  const src = await readFile(INDEX, 'utf8')
  const ranges = editableRanges(src)
  if (count !== ranges.length)
    return json(res, 409, { ok:false, error:`span count mismatch (editor ${count} ≠ file ${ranges.length}); reload the editor` })
  if (!Array.isArray(edits) || !edits.length)
    return json(res, 200, { ok:true, changed:0 })
  for (const e of edits) {
    if (typeof e.i !== 'number' || e.i < 0 || e.i >= ranges.length) return json(res, 400, { ok:false, error:`bad index ${e.i}` })
    if (typeof e.html !== 'string' || /<\/?(script|style|iframe)\b/i.test(e.html) || !balancedSpans(e.html))
      return json(res, 400, { ok:false, error:`rejected content for span ${e.i}` })
  }
  // splice from the end so earlier offsets stay valid
  let out = src
  for (const e of [...edits].sort((a, b) => b.i - a.i)) {
    const [s, en] = ranges[e.i]
    out = out.slice(0, s) + e.html + out.slice(en)
  }
  await mkdir(BACKUPS, { recursive: true })
  const stamp = new Date().toISOString().replace(/[:.]/g, '-')
  await copyFile(INDEX, resolve(BACKUPS, `index-${stamp}.html`))
  try { await stat(resolve(BACKUPS, 'index.original.html')) }
  catch { await copyFile(INDEX, resolve(BACKUPS, 'index.original.html')) }  // keep the very first
  await writeFile(INDEX, out)
  json(res, 200, { ok:true, changed: edits.length, backup: `index-${stamp}.html` })
}

function handleDeploy(res) {
  const cmd = `netlify deploy --dir landing --prod --site ${SITE_ID}`
  exec(cmd, { cwd: APP, timeout: 180000, maxBuffer: 10 * 1024 * 1024 }, (err, stdout, stderr) => {
    const log = (stdout + '\n' + stderr).trim()
    const url = (log.match(/https:\/\/[^\s]*carrousel-app\.netlify\.app/) || [])[0] || 'https://carrousel-app.netlify.app'
    if (err) return json(res, 500, { ok:false, error: err.message, log: log.slice(-1500) })
    json(res, 200, { ok:true, url, log: log.slice(-1200) })
  })
}

async function serveStatic(res, base, urlPath) {
  const clean = normalize(decodeURIComponent(urlPath)).replace(/^(\.\.[/\\])+/, '')
  let file = resolve(base, clean.replace(/^\/+/, ''))
  if (!file.startsWith(base)) return json(res, 403, { error:'forbidden' })
  try {
    if ((await stat(file)).isDirectory()) file = resolve(file, 'index.html')
  } catch {}
  try {
    const buf = await readFile(file)
    res.writeHead(200, { 'content-type': TYPES[extname(file).toLowerCase()] || 'application/octet-stream', 'cache-control':'no-store' })
    res.end(buf)
  } catch { res.writeHead(404); res.end('not found') }
}

const server = createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`)
    const p = url.pathname
    if (p === '/' ) return serveStatic(res, HERE, '/app.html')
    if (p === '/app.html' || p === '/app.js') return serveStatic(res, HERE, p)
    if (p === '/api/save' && req.method === 'POST') return handleSave(req, res)
    if (p === '/api/deploy' && req.method === 'POST') return handleDeploy(res)
    if (p === '/site' || p === '/site/') return serveStatic(res, LANDING, '/index.html')
    if (p.startsWith('/site/')) return serveStatic(res, LANDING, p.slice('/site'.length))
    res.writeHead(404); res.end('not found')
  } catch (e) { json(res, 500, { ok:false, error: String(e && e.message || e) }) }
})

server.listen(PORT, '127.0.0.1', () => {
  console.log(`\n  Carrousel editor  →  http://127.0.0.1:${PORT}\n  Editing:          ${INDEX}\n  Deploy target:    carrousel-app.netlify.app\n`)
})
