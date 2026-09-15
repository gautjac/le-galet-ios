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

async function newestBuild(appId, wantBuild) {
  const filter = wantBuild ? `&filter[version]=${encodeURIComponent(wantBuild)}` : '';
  const b = await api('GET', `/v1/builds?filter[app]=${appId}${filter}&sort=-uploadedDate&limit=1&fields[builds]=version,processingState`);
  return b.data[0];
}
async function waitForValidBuild(appId, wantBuild) {
  const t0 = Date.now();
  let b = await newestBuild(appId, wantBuild);
  while ((!b || b.attributes.processingState === 'PROCESSING') && Date.now() - t0 < 45 * 60e3) {
    warn(`build ${wantBuild ?? ''}: ${b ? b.attributes.processingState : 'not visible yet'}… (${Math.round((Date.now()-t0)/1000)}s)`);
    await new Promise(r => setTimeout(r, 30e3));
    b = await newestBuild(appId, wantBuild);
  }
  return b;
}

async function cmdAttachBuild(ver, wantBuild, doWait) {
  const app = await getApp();
  const v = await findVersion(app.id, ver);
  if (!v) throw new Error(`version ${ver} not found`);
  let b = doWait ? await waitForValidBuild(app.id, wantBuild) : await newestBuild(app.id, wantBuild);
  if (!b) throw new Error('no build found');
  if (b.attributes.processingState !== 'VALID') { warn(`build ${b.attributes.version} is ${b.attributes.processingState}, not VALID yet`); return { app, v, build: b, valid: false }; }
  await api('PATCH', `/v1/appStoreVersions/${v.id}/relationships/build`, { data: { type: 'builds', id: b.id } });
  ok(`attached build ${b.attributes.version} (VALID) to version ${ver}`);
  return { app, v, build: b, valid: true };
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
  else if (cmd === 'attach-build') await cmdAttachBuild(args[1], flag('--build'), args.includes('--wait'));
  else if (cmd === 'submit') await cmdSubmit(args[1]);
  else if (cmd === 'release-flow') await cmdReleaseFlow(args[1], flag('--build'));
  else { console.error('usage: asc.mjs status|create-version <v>|set-copy <v>|attach-build <v> [--build N] [--wait]|submit <v>|release-flow <v> [--build N]'); process.exit(2); }
} catch (e) { console.error('✘ ' + e.message); process.exit(1); }
