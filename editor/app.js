// Carrousel editor — client. Loads the real landing in an iframe (same origin),
// makes every FR/EN copy span click-to-edit, tracks changes by their stable
// document order, and patches them back into index.html via /api/save.
(function () {
  const $ = (s) => document.querySelector(s)
  const iframe = $('#site'), statusEl = $('#status')
  const saveBtn = $('#save'), deployBtn = $('#deploy'), resetBtn = $('#reset')
  const toastEl = $('#toast')

  let spans = [], originals = [], edits = {}, lang = 'fr', editing = null

  const EDIT_CSS = `
    .cme{outline:1px dashed rgba(211,165,103,0);transition:outline-color .15s,background .15s;
      border-radius:3px;cursor:text}
    .cme:hover{outline-color:rgba(211,165,103,.55);background:rgba(211,165,103,.06)}
    .cme-on{outline:2px solid #D3A567 !important;background:rgba(211,165,103,.12) !important}`

  function toast(msg, kind = '', ms = 3200) {
    toastEl.className = 'toast show ' + kind
    toastEl.innerHTML = msg
    clearTimeout(toast._t); toast._t = setTimeout(() => (toastEl.className = 'toast ' + kind), ms)
  }

  function dirtyCount() {
    let n = 0
    for (const i in edits) if (edits[i] !== originals[i]) n++
    return n
  }
  function refresh() {
    const n = dirtyCount()
    saveBtn.disabled = n === 0
    if (n === 0) { statusEl.textContent = 'Aucune modification'; statusEl.className = 'status' }
    else { statusEl.innerHTML = `<b>${n}</b> modification${n > 1 ? 's' : ''} à enregistrer`; statusEl.className = 'status' }
  }

  function finishEdit() {
    if (!editing) return
    editing.contentEditable = 'false'
    editing.classList.remove('cme-on')
    editing = null
  }
  function startEdit(span, i) {
    if (editing === span) return
    finishEdit()
    editing = span
    span.contentEditable = 'true'
    span.classList.add('cme-on')
    span.focus()
    span.oninput = () => { edits[i] = span.innerHTML; refresh() }
    span.onkeydown = (e) => {
      if (e.key === 'Escape') { e.preventDefault(); finishEdit() }
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); finishEdit() }
    }
    span.onblur = () => { edits[i] = span.innerHTML; finishEdit(); refresh() }
  }

  function setLang(l) {
    lang = l
    document.querySelectorAll('.seg button').forEach(b => b.setAttribute('aria-pressed', b.dataset.lang === l ? 'true' : 'false'))
    const doc = iframe.contentDocument
    const btn = doc && doc.querySelector(`.langtoggle button[data-lang="${l}"]`)
    if (btn) btn.click()
  }

  function init() {
    const doc = iframe.contentDocument
    if (!doc) return
    // editing affordance styles
    const st = doc.createElement('style'); st.textContent = EDIT_CSS; doc.head.appendChild(st)
    // keep the preview on index — swallow in-iframe link navigations
    doc.addEventListener('click', (e) => {
      const a = e.target.closest && e.target.closest('a[href]')
      if (a && !a.getAttribute('href').startsWith('#')) e.preventDefault()
    }, true)

    spans = [...doc.querySelectorAll('span.fr, span.en')]
    originals = spans.map(s => s.innerHTML)
    edits = {}
    spans.forEach((s, i) => {
      s.classList.add('cme')
      s.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); startEdit(s, i) })
    })
    // sync language with whatever the page loaded in
    lang = (doc.body.className.indexOf('lang-en') > -1) ? 'en' : 'fr'
    document.querySelectorAll('.seg button').forEach(b => b.setAttribute('aria-pressed', b.dataset.lang === lang ? 'true' : 'false'))
    refresh()
    statusEl.textContent = 'Aucune modification'
    toast(`Prêt · ${spans.length} textes modifiables`, 'ok', 2200)
  }

  async function save() {
    finishEdit()
    const changed = []
    for (const i in edits) if (edits[i] !== originals[i]) changed.push({ i: +i, html: edits[i] })
    if (!changed.length) return
    saveBtn.disabled = true; saveBtn.textContent = 'Enregistrement…'
    try {
      const r = await fetch('/api/save', {
        method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ count: spans.length, edits: changed }),
      })
      const d = await r.json()
      if (!d.ok) throw new Error(d.error || 'échec')
      changed.forEach(e => { originals[e.i] = e.html }); edits = {}
      toast(`Enregistré · ${d.changed} texte${d.changed > 1 ? 's' : ''} ✓`, 'ok')
    } catch (e) { toast('Erreur : ' + e.message, 'err', 5000) }
    finally { saveBtn.textContent = 'Enregistrer'; refresh() }
  }

  async function deploy() {
    if (dirtyCount() && !confirm('Des modifications ne sont pas enregistrées. Publier quand même la dernière version enregistrée ?')) return
    if (!confirm('Publier la page Carrousel en ligne ?')) return
    deployBtn.disabled = true; deployBtn.innerHTML = '<span class="spin"></span>Publication…'
    try {
      const r = await fetch('/api/deploy', { method: 'POST' })
      const d = await r.json()
      if (!d.ok) throw new Error(d.error || 'échec du déploiement')
      toast(`En ligne ✓ · <a href="${d.url}" target="_blank" rel="noopener">${d.url.replace('https://', '')}</a>`, 'ok', 8000)
    } catch (e) { toast('Déploiement : ' + e.message, 'err', 6000) }
    finally { deployBtn.disabled = false; deployBtn.textContent = 'Publier' }
  }

  document.querySelectorAll('.seg button').forEach(b => b.addEventListener('click', () => setLang(b.dataset.lang)))
  saveBtn.addEventListener('click', save)
  deployBtn.addEventListener('click', deploy)
  resetBtn.addEventListener('click', () => {
    if (dirtyCount() && !confirm('Annuler les modifications non enregistrées ?')) return
    iframe.src = '/site/?r=' + Date.now()
  })
  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 's') { e.preventDefault(); save() }
  })
  iframe.addEventListener('load', init)
  if (iframe.contentDocument && iframe.contentDocument.readyState === 'complete') init()
})()
