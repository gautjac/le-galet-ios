#!/usr/bin/env node
// asc.mjs — App Store Connect release helper for Carousel (com.jac.LeGalet).
//
// Auth: ES256 JWT from ~/.appstoreconnect/private_keys/AuthKey_<KID>.p8,
// signature in ieee-p1363 form (DER is rejected). Key id / issuer id below.
//
// Commands:
//   status                         Show app, versions, their state + localizations, recent builds.
//   create-version <ver>           Create a PREPARE_FOR_SUBMISSION version (idempotent).
//   set-copy <ver>                 Push description/promo/keywords/whatsNew from store/metadata/*.md
//                                    to the version localizations (en-US, fr-FR, fr-CA).
//   attach-build <ver> [--build N] Attach the newest VALID build (or CFBundleVersion N) to the version.
//   submit <ver>                   Create the ReviewSubmission and add the version item (submit for review).
//   release-flow <ver> [--build N] create-version → set-copy → attach-build → submit, waiting for a VALID build.
//
// Run from the repo root or store/asc/.
import fs from 'fs'; import crypto from 'crypto'; import path from 'path'; import { fileURLToPath } from 'url';

const KID = 'H8L98GV62V';
const ISS = '69a6de70-83d6-47e3-e053-5b8c7c11a4d1';
const BUNDLE = 'com.jac.LeGalet';
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const keyPath = `${process.env.HOME}/.appstoreconnect/private_keys/AuthKey_${KID}.p8`;
const key = fs.readFileSync(keyPath);

function jwt() {
  const b64 = o => Buffer.from(JSON.stringify(o)).toString('base64url'), now = Math.floor(Date.now() / 1000);
  const h = b64({ alg: 'ES256', kid: KID, typ: 'JWT' });
  const p = b64({ iss: ISS, iat: now, exp: now + 900, aud: 'appstoreconnect-v1' });
  return `${h}.${p}.` + crypto.sign('sha256', Buffer.from(`${h}.${p}`), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url');
}
async function api(method, p, data) {
  const r = await fetch('https://api.appstoreconnect.apple.com' + p, { method,
    headers: { Authorization: 'Bearer ' + jwt(), 'Content-Type': 'application/json' },
    body: data ? JSON.stringify(data) : undefined });
  const t = await r.text(); const j = t ? JSON.parse(t) : {};
  if (r.status >= 400) { const e = new Error(`${method} ${p} → ${r.status} ${(j.errors || []).map(x => x.code + ': ' + (x.detail || x.title)).join('; ')}`); e.status = r.status; e.body = j; throw e; }
  return j;
}
const ok = m => console.log('✔ ' + m), info = m => console.log('  ' + m), warn = m => console.log('… ' + m);
const args = process.argv.slice(2);
const cmd = args[0];
const flag = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };

async function getApp() {
  const apps = await api('GET', `/v1/apps?filter[bundleId]=${encodeURIComponent(BUNDLE)}&fields[apps]=name,bundleId,primaryLocale`);
  const app = (apps.data || []).find(a => a.attributes.bundleId === BUNDLE);
  if (!app) throw new Error(`No app record for ${BUNDLE}`);
  return app;
}
async function versions(appId) {
  return (await api('GET', `/v1/apps/${appId}/appStoreVersions?fields[appStoreVersions]=versionString,appStoreState,platform,createdDate&limit=20`)).data;
}
async function findVersion(appId, ver) {
  return (await versions(appId)).find(v => v.attributes.versionString === ver && v.attributes.platform === 'IOS');
}

// ---- metadata from store/metadata/*.md -------------------------------------
// Each locale file has fenced blocks under headers. We extract by header.
function mdField(md, header) {
  // header line contains `header`; the value is the first fenced ``` block after it.
  const idx = md.indexOf(header);
  if (idx < 0) return null;
  const after = md.slice(idx);
  const m = after.match(/```[a-z]*\n([\s\S]*?)```/);
  return m ? m[1].replace(/\s+$/, '') : null;
}
function loadCopy(localeFile, keys) {
  const md = fs.readFileSync(path.join(repo, 'store', 'metadata', localeFile), 'utf8');
  const out = {};
  for (const [field, header] of Object.entries(keys)) out[field] = mdField(md, header);
  return out;
}

async function cmdStatus() {
  const app = await getApp();
  ok(`app "${app.attributes.name}" (${app.id}) · primaryLocale ${app.attributes.primaryLocale}`);
  const vs = await versions(app.id);
  for (const v of vs.filter(v => v.attributes.platform === 'IOS')) {
    console.log(`\n  version ${v.attributes.versionString} — ${v.attributes.appStoreState} (${v.id})`);
    const locs = (await api('GET', `/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale,description,promotionalText,keywords,whatsNew`)).data;
    for (const l of locs) {
      const a = l.attributes;
      console.log(`    ${a.locale}: subtitle/promo="${(a.promotionalText||'').slice(0,40)}..." kw="${(a.keywords||'').slice(0,40)}" desc=${(a.description||'').length}ch whatsNew=${(a.whatsNew||'').length}ch`);
    }
    // attached build?
    try {
      const b = await api('GET', `/v1/appStoreVersions/${v.id}/build?fields[builds]=version,processingState`);
      if (b.data) console.log(`    build attached: ${b.data.attributes.version} (${b.data.attributes.processingState})`);
      else console.log('    build attached: none');
    } catch { console.log('    build attached: none'); }
  }
  console.log('\n  recent builds:');
  const builds = (await api('GET', `/v1/builds?filter[app]=${app.id}&sort=-uploadedDate&limit=6&fields[builds]=version,processingState,uploadedDate,expired`)).data;
  for (const b of builds) info(`build ${b.attributes.version}: ${b.attributes.processingState}${b.attributes.expired ? ' (expired)' : ''} — ${b.attributes.uploadedDate}`);
  // app info (name/subtitle live)
  const infos = (await api('GET', `/v1/apps/${app.id}/appInfos?fields[appInfos]=appStoreState`)).data;
  for (const ai of infos) {
    const locs = (await api('GET', `/v1/appInfos/${ai.id}/appInfoLocalizations?fields[appInfoLocalizations]=locale,name,subtitle`)).data;
    console.log(`\n  appInfo ${ai.id} (${ai.attributes.appStoreState}):`);
    for (const l of locs) info(`${l.attributes.locale}: name="${l.attributes.name}" subtitle="${l.attributes.subtitle}"`);
  }
  return app;
}

async function cmdCreateVersion(ver) {
  const app = await getApp();
  let v = await findVersion(app.id, ver);
  if (v) { ok(`version ${ver} already exists — ${v.attributes.appStoreState} (${v.id})`); return { app, v }; }
  v = (await api('POST', '/v1/appStoreVersions', { data: { type: 'appStoreVersions',
    attributes: { platform: 'IOS', versionString: ver },
    relationships: { app: { data: { type: 'apps', id: app.id } } } } })).data;
  ok(`created version ${ver} (${v.id}) — PREPARE_FOR_SUBMISSION`);
  return { app, v };
}

const LOCALES = {
  'en-US': { file: 'en.md', keys: { description: '## Description', promotionalText: '## Promotional Text', keywords: '## Keywords', whatsNew: "## What's New" } },
  'fr-FR': { file: 'fr.md', keys: { description: '## Description', promotionalText: '## Texte promotionnel', keywords: '## Mots-clés', whatsNew: '## Nouveautés de cette version' } },
  'fr-CA': { file: 'fr.md', keys: { description: '## Description', promotionalText: '## Texte promotionnel', keywords: '## Mots-clés', whatsNew: '## Nouveautés de cette version' } },
};

async function cmdSetCopy(ver) {
  const app = await getApp();
  const v = await findVersion(app.id, ver);
  if (!v) throw new Error(`version ${ver} not found — create it first`);
  const locs = (await api('GET', `/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale`)).data;
  for (const [locale, spec] of Object.entries(LOCALES)) {
    const copy = loadCopy(spec.file, spec.keys);
    const attrs = {};
    for (const k of ['description', 'promotionalText', 'keywords', 'whatsNew']) if (copy[k]) attrs[k] = copy[k];
    let loc = locs.find(l => l.attributes.locale === locale);
    if (!loc) {
      loc = (await api('POST', '/v1/appStoreVersionLocalizations', { data: { type: 'appStoreVersionLocalizations',
        attributes: { locale, ...attrs }, relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: v.id } } } } })).data;
      ok(`created ${locale} localization`);
    } else {
      await api('PATCH', `/v1/appStoreVersionLocalizations/${loc.id}`, { data: { type: 'appStoreVersionLocalizations', id: loc.id, attributes: attrs } });
      ok(`updated ${locale}: promo=${(attrs.promotionalText||'').length} kw=${(attrs.keywords||'').length} desc=${(attrs.description||'').length} whatsNew=${(attrs.whatsNew||'').length}`);
    }
  }
}

// Newest build ON A GIVEN TRAIN (preReleaseVersion == trainVer), so a 1.0.1
// version never accidentally grabs an older 1.0.0 build. If wantBuild is set,
// it further pins the CFBundleVersion.
async function newestBuild(appId, wantBuild, trainVer) {
  const filter = wantBuild ? `&filter[version]=${encodeURIComponent(wantBuild)}` : '';
  const b = await api('GET', `/v1/builds?filter[app]=${appId}${filter}&sort=-uploadedDate&limit=25&fields[builds]=version,processingState,preReleaseVersion&include=preReleaseVersion&fields[preReleaseVersions]=version`);
  const trainOf = build => {
    const rel = build.relationships?.preReleaseVersion?.data;
    const inc = rel && (b.included || []).find(i => i.id === rel.id);
    return inc?.attributes?.version;
  };
  const list = b.data.filter(x => !trainVer || trainOf(x) === trainVer);
  return list[0];
}
async function waitForValidBuild(appId, wantBuild, trainVer) {
  const t0 = Date.now();
  let b = await newestBuild(appId, wantBuild, trainVer);
  while ((!b || b.attributes.processingState === 'PROCESSING') && Date.now() - t0 < 45 * 60e3) {
    warn(`build on train ${trainVer ?? '*'} ${wantBuild ?? ''}: ${b ? b.attributes.processingState : 'not visible yet'}… (${Math.round((Date.now()-t0)/1000)}s)`);
    await new Promise(r => setTimeout(r, 30e3));
    b = await newestBuild(appId, wantBuild, trainVer);
  }
  return b;
}

async function cmdAttachBuild(ver, wantBuild, doWait) {
  const app = await getApp();
  const v = await findVersion(app.id, ver);
  if (!v) throw new Error(`version ${ver} not found`);
  let b = doWait ? await waitForValidBuild(app.id, wantBuild, ver) : await newestBuild(app.id, wantBuild, ver);
  if (!b) throw new Error(`no build on the ${ver} train found yet`);
  if (b.attributes.processingState !== 'VALID') { warn(`build ${b.attributes.version} is ${b.attributes.processingState}, not VALID yet`); return { app, v, build: b, valid: false }; }
  await api('PATCH', `/v1/appStoreVersions/${v.id}/relationships/build`, { data: { type: 'builds', id: b.id } });
  ok(`attached build ${b.attributes.version} (VALID) to version ${ver}`);
  return { app, v, build: b, valid: true };
}

// Match the approved baseline: en-US + fr-CA only. Remove any stray locale.
async function cmdPruneLocales(ver, keep = ['en-US', 'fr-CA']) {
  const app = await getApp();
  const v = await findVersion(app.id, ver);
  if (!v) throw new Error(`version ${ver} not found`);
  const locs = (await api('GET', `/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale`)).data;
  for (const l of locs) {
    if (!keep.includes(l.attributes.locale)) {
      await api('DELETE', `/v1/appStoreVersionLocalizations/${l.id}`);
      ok(`removed locale ${l.attributes.locale}`);
    }
  }
}

// Upload the 5 iPad Pro 12.9" screenshots to each locale, in order.
// en-US ← store/screenshots/out/*-en.png ; fr-CA ← *-fr.png
const SHOTS = {
  'en-US': ['01-photo-en', '02-quote-en', '03-event-en', '04-composer-en', '05-settings-en'],
  'fr-CA': ['01-photo-fr', '02-quote-fr', '03-event-fr', '04-composer-fr', '05-settings-fr'],
};
const DISPLAY_TYPE = 'APP_IPAD_PRO_3GEN_129';
async function cmdUploadScreenshots(ver) {
  const app = await getApp();
  const v = await findVersion(app.id, ver);
  if (!v) throw new Error(`version ${ver} not found`);
  const locs = (await api('GET', `/v1/appStoreVersions/${v.id}/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale`)).data;
  for (const [locale, files] of Object.entries(SHOTS)) {
    const loc = locs.find(l => l.attributes.locale === locale);
    if (!loc) { warn(`no ${locale} localization — skipping screenshots`); continue; }
    // find or create the display-type set
    let sets = (await api('GET', `/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets?include=appScreenshots`));
    let set = (sets.data || []).find(s => s.attributes.screenshotDisplayType === DISPLAY_TYPE);
    if (!set) {
      set = (await api('POST', '/v1/appScreenshotSets', { data: { type: 'appScreenshotSets',
        attributes: { screenshotDisplayType: DISPLAY_TYPE },
        relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: loc.id } } } } })).data;
      ok(`${locale}: created ${DISPLAY_TYPE} set`);
    }
    const existing = (set.relationships?.appScreenshots?.data || []).length;
    if (existing >= files.length) { ok(`${locale}: already has ${existing} screenshots — skipping`); continue; }
    for (const base of files) {
      const fp = path.join(repo, 'store', 'screenshots', 'out', base + '.png');
      const bytes = fs.readFileSync(fp);
      const md5 = crypto.createHash('md5').update(bytes).digest('hex');
      // 1. reserve
      const res = (await api('POST', '/v1/appScreenshots', { data: { type: 'appScreenshots',
        attributes: { fileName: base + '.png', fileSize: bytes.length },
        relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: set.id } } } } })).data;
      // 2. upload bytes to each operation
      for (const op of res.attributes.uploadOperations) {
        const headers = {}; for (const h of (op.requestHeaders || [])) headers[h.name] = h.value;
        const chunk = bytes.subarray(op.offset, op.offset + op.length);
        const r = await fetch(op.url, { method: op.method, headers, body: chunk });
        if (r.status >= 400) throw new Error(`upload ${base} → ${r.status} ${await r.text()}`);
      }
      // 3. commit
      await api('PATCH', `/v1/appScreenshots/${res.id}`, { data: { type: 'appScreenshots', id: res.id,
        attributes: { uploaded: true, sourceFileChecksum: md5 } } });
      info(`${locale}: uploaded ${base}.png (${(bytes.length/1024|0)} KB)`);
    }
    ok(`${locale}: ${files.length} screenshots uploaded`);
  }
}

async function cmdSubmit(ver) {
  const app = await getApp();
  const v = await findVersion(app.id, ver);
  if (!v) throw new Error(`version ${ver} not found`);
  // Create a review submission for the platform, then add the version as an item.
  let sub;
  const existing = (await api('GET', `/v1/reviewSubmissions?filter[app]=${app.id}&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW&fields[reviewSubmissions]=state,platform`)).data
    .find(s => s.attributes.platform === 'IOS');
  if (existing) { sub = existing; info(`reusing review submission ${sub.id} (${sub.attributes.state})`); }
  else {
    sub = (await api('POST', '/v1/reviewSubmissions', { data: { type: 'reviewSubmissions',
      attributes: { platform: 'IOS' }, relationships: { app: { data: { type: 'apps', id: app.id } } } } })).data;
    ok(`created review submission ${sub.id}`);
  }
  // Add the version item (idempotent-ish: ignore if already added)
  try {
    await api('POST', '/v1/reviewSubmissionItems', { data: { type: 'reviewSubmissionItems',
      relationships: { reviewSubmission: { data: { type: 'reviewSubmissions', id: sub.id } },
        appStoreVersion: { data: { type: 'appStoreVersions', id: v.id } } } } });
    ok(`added version ${ver} to submission`);
  } catch (e) { if (e.status === 409) info('version already an item on this submission'); else throw e; }
  // Submit: set state to READY_FOR_REVIEW / submitted
  await api('PATCH', `/v1/reviewSubmissions/${sub.id}`, { data: { type: 'reviewSubmissions', id: sub.id, attributes: { submitted: true } } });
  ok(`submitted version ${ver} for review 🚀`);
}

async function cmdReleaseFlow(ver, wantBuild) {
  await cmdCreateVersion(ver);
  await cmdSetCopy(ver);
  const { app } = await cmdAttachBuild(ver, wantBuild, true);
  const res = await cmdAttachBuild(ver, wantBuild, false);
  if (!res.valid) { warn('build not VALID yet — rerun attach-build then submit'); return; }
  await cmdSubmit(ver);
}

try {
  if (cmd === 'status') await cmdStatus();
  else if (cmd === 'create-version') await cmdCreateVersion(args[1]);
  else if (cmd === 'set-copy') await cmdSetCopy(args[1]);
  else if (cmd === 'prune-locales') await cmdPruneLocales(args[1]);
  else if (cmd === 'upload-screenshots') await cmdUploadScreenshots(args[1]);
  else if (cmd === 'attach-build') await cmdAttachBuild(args[1], flag('--build'), args.includes('--wait'));
  else if (cmd === 'submit') await cmdSubmit(args[1]);
  else if (cmd === 'release-flow') await cmdReleaseFlow(args[1], flag('--build'));
  else { console.error('usage: asc.mjs status|create-version <v>|set-copy <v>|attach-build <v> [--build N] [--wait]|submit <v>|release-flow <v> [--build N]'); process.exit(2); }
} catch (e) { console.error('✘ ' + e.message); process.exit(1); }
