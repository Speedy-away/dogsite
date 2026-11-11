'use strict';

// Read-only source audit. Publishes metadata, never Lua or game-model payloads.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const zlib = require('node:zlib');
const ROOT = path.resolve(__dirname, '../..');
const SOURCES = path.dirname(ROOT);
const OUTPUT = path.join(ROOT, 'project/community-menu-sources/biggerscript-public.json');
const REPOSITORY = 'themilkman554/BiggerScriptAssests';
const ORIGIN = `https://github.com/${REPOSITORY}`;
const GTA = path.join(SOURCES, 'Scooby-Op/GTA5/EE/GTA - Main Src');
const sha = data => crypto.createHash('sha256').update(data).digest('hex');
const gitSha = data => crypto.createHash('sha1').update(`blob ${data.length}\0`).update(data).digest('hex');
const slug = value => value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'file';
const read = relative => JSON.parse(fs.readFileSync(path.join(ROOT, relative), 'utf8'));
const text = bytes => (bytes[0] === 0xff && bytes[1] === 0xfe ? bytes.subarray(2).toString('utf16le') : bytes.toString('utf8')).replace(/^\ufeff/, '');
const normalizedHash = bytes => sha(text(bytes).replace(/\r\n?/g, '\n').trim());
const publicUrl = (revision, filename, raw = false) => (raw ? `https://raw.githubusercontent.com/${REPOSITORY}/${revision}/` : `${ORIGIN}/blob/${revision}/`) + filename.split('/').map(encodeURIComponent).join('/');
async function request(url, range) {
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:' || !['api.github.com', 'raw.githubusercontent.com'].includes(parsed.hostname)) throw Error('Unexpected source URL');
  const r = await fetch(url, { headers: { 'User-Agent': 'Scooby public BiggerScript asset audit', Accept: 'application/vnd.github+json', ...(range ? { Range: range } : {}) }, signal: AbortSignal.timeout(30000) });
  if (![200, 206].includes(r.status)) { await r.body?.cancel(); throw Error(`Public source HTTP ${r.status}: ${url}`); }
  return r;
}
async function json(url) { return (await request(url)).json(); }
async function limited(values, callback, count = 5) {
  const output = new Array(values.length); let next = 0;
  await Promise.all(Array.from({ length: Math.min(count, values.length) }, async () => {
    for (;;) { const i = next++; if (i >= values.length) break; output[i] = await callback(values[i], i); }
  })); return output;
}
function localData() {
  const exact = new Map(), normalized = new Map(), mapsByPath = new Map();
  const push = (record, bytes) => {
    const key = gitSha(bytes), normal = normalizedHash(bytes);
    if (!exact.has(key)) exact.set(key, []); exact.get(key).push(record);
    if (!normalized.has(normal)) normalized.set(normal, []); normalized.get(normal).push(record);
  };
  const vehicles = read('community/data/vehicles/local-assets.json');
  for (const [index, asset] of Object.entries(vehicles)) if (asset.file) {
    const file = path.resolve(ROOT, 'community', asset.file.replace(/^\.\//, ''));
    if (!file.startsWith(path.join(ROOT, 'community', 'media') + path.sep)) throw Error('Legacy payload escapes media');
    if (fs.existsSync(file)) push({ family: 'vehicles', index: Number(index), localPath: path.relative(ROOT, file).split(path.sep).join('/'), preview: asset.preview ? `/resources/${asset.preview.replace(/^\.\//, '')}` : undefined }, fs.readFileSync(file));
  }
  const library = read('community/data/library.json');
  for (const item of library.items.filter(item => item.game === 'gta5' && ['vehicles', 'maps'].includes(item.category))) {
    for (const f of item.files || []) if (f.path) {
      const file = path.resolve(SOURCES, 'cool-repo', f.path);
      if (fs.existsSync(file)) push({ id: item.id }, fs.readFileSync(file));
    }
  }
  const packed = path.join(GTA, 'assets/maps/BiggerScriptMaps.json.zlib');
  const manifest = JSON.parse(fs.readFileSync(path.join(GTA, 'assets/maps/manifest.json'), 'utf8'));
  const installed = JSON.parse(zlib.inflateSync(fs.readFileSync(packed)));
  for (const row of installed) {
    const relative = row.path.replace(/\\/g, '/');
    const id = `gta5-map-${slug(path.posix.basename(relative, '.xml'))}-${sha(relative).slice(0, 8)}`;
    const item = library.items.find(item => item.id === id);
    if (!item || item.files[0]?.sha256 !== sha(Buffer.from(row.xml))) throw Error(`Missing or changed existing BiggerScript map: ${relative}`);
    const source = manifest.maps.find(map => map.path === row.path);
    mapsByPath.set(`XML Maps/${relative}`, { id, localInstalledSha256: sha(Buffer.from(row.xml)), sourceArchiveSha256: manifest.source_archive_sha256, ...source });
  }
  return { exact, normalized, mapsByPath, manifest, installedCount: installed.length, legacyCount: Object.keys(vehicles).length };
}
function inspect(filename, bytes) {
  const value = text(bytes), ext = path.posix.extname(filename).toLowerCase();
  const category = /^(?:XML|JSON) Maps\//.test(filename) ? 'maps' : 'vehicles';
  if (ext === '.json') {
    const parsed = JSON.parse(value);
    if (category === 'maps' && Array.isArray(parsed) && parsed.length && parsed.every(row => Array.isArray(row) && row.length >= 8 && typeof row[0] === 'string' && Number.isFinite(row[1]) && row.slice(2, 8).every(Number.isFinite))) {
      return { category, format: 'Impulse/JamezGamez array JSON placements', schema: 'impulse-array-of-arrays', placements: parsed.length,
        supportedMenus: ['cherax'], requirementLabel: 'Legacy Impulse/JamezGamez array JSON; the inspected BiggerScript loader for Cherax has a dedicated importer. Native Scooby, Nenyoo and Stand support for this exact schema was not established.' };
    }
    if (parsed?.base && typeof parsed.base === 'object' && (parsed.base.model || parsed.base.data?.model) && /Jackz|JSTAND/i.test(String(parsed.version || parsed.base.savedata?.Format || ''))) {
      return { category, format: 'Jackz Builder / JSTAND JSON construct', schema: 'jackz-base-json', model: parsed.base.model || parsed.base.data?.model,
        version: typeof parsed.version === 'string' ? parsed.version : undefined, supportedMenus: category === 'vehicles' ? ['stand', 'cherax'] : ['stand'],
        requirementLabel: 'Jackz Builder/JSTAND JSON format; requires the matching Stand builder. BiggerScript for Cherax explicitly normalizes this format in its vehicle loader only. Native Scooby/Nenyoo importer support was not established.' };
    }
    if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object' || (!parsed.model && !parsed.hash && !parsed.children)) throw Error('Not a recognized entity/children construct');
    return { category, format: 'Constructor / entity-children JSON', schema: 'entity-children-json', author: typeof parsed.author === 'string' ? parsed.author : undefined,
      model: parsed.model || parsed.hash, version: typeof parsed.version === 'string' ? parsed.version : undefined,
      targetVersion: typeof parsed.target_version === 'string' ? parsed.target_version : undefined,
      children: Array.isArray(parsed.children) ? parsed.children.length : 0,
      supportedMenus: category === 'maps' ? ['scooby', 'stand', 'cherax'] : ['nenyoo', 'stand', 'cherax'],
      requirementLabel: category === 'maps' ? 'Entity/children JSON placement format; use Scooby’s JSON map importer, Stand Constructor, or the matching BiggerScript loader for Cherax. Runtime parity is unverified.' : 'Constructor JSON vehicle format; use Nenyoo’s matching importer, Stand Constructor, or the matching BiggerScript loader for Cherax. Scooby vehicle schema support requires review.' };
  }
  if (ext === '.xml') {
    const xml = value.replace(/<\?xml[^]*?\?>/i, '').replace(/<!--[\s\S]*?-->/g, '').trim();
    const root = xml.match(/^<([A-Za-z][\w:]*)\b/)?.[1];
    if (category === 'maps' && root !== 'SpoonerPlacements') throw Error(`Unexpected map XML root: ${root}`);
    if (category === 'vehicles' && !['Vehicle', 'SpoonerPlacements'].includes(root)) throw Error(`Unexpected vehicle XML root: ${root}`);
    if (category === 'vehicles' && !/<ModelHash\b/i.test(xml)) throw Error('Vehicle XML lacks a model');
    return { category, format: category === 'maps' ? 'Menyoo Spooner XML placements' : 'Menyoo XML vehicle construct', schema: root,
      placements: (xml.match(/<(?:Placement|Attachment)\b/g) || []).length,
      supportedMenus: ['scooby', 'nenyoo', 'stand', 'cherax'],
      requirementLabel: 'Menyoo/Spooner XML data; use the matching importer. Stand requires Constructor and Cherax requires the corresponding BiggerScript loader. Referenced models are separate dependencies; runtime parity is unverified.' };
  }
  if (ext === '.ini') {
    const section = value.match(/^\s*\[(Vehicle0?|VEHICLE)\][^]*?(?=^\s*\[|(?![\s\S]))/im)?.[0];
    if (section && /^\s*(?:model|hash|modelhash)\s*=/im.test(section)) return { category, format: 'Menyoo INI vehicle construct', schema: /^\s*\[Vehicle0\]/im.test(section) ? 'Vehicle0/Hash INI' : 'Vehicle/model INI', supportedMenus: ['scooby', 'nenyoo', 'stand', 'cherax'],
      requirementLabel: 'Vehicle/Vehicle0 INI data; use the matching vehicle importer. Stand requires Constructor and Cherax requires the corresponding BiggerScript loader. Runtime parity is unverified.' };
  }
  throw Error('Unrecognized saved-vehicle data schema');
}
function validateManifest(output) {
  if (output.repository?.name !== REPOSITORY || !/^[a-f0-9]{40}$/.test(output.repository.revision)) throw Error('Invalid BiggerScript provenance');
  const library = new Map(read('community/data/library.json').items.map(item => [item.id, item]));
  const legacyCount = read('community/data/vehicles/index.json').items.length;
  const source = new Map(output.audit.records.map(row => [row.sourcePath, row]));
  const ids = new Set(), legacy = new Set(), overrides = new Set();
  for (const item of output.items) {
    if (ids.has(item.id) || library.has(item.id)) throw Error('Duplicate resource identity'); ids.add(item.id);
    if (!['vehicles', 'maps'].includes(item.category) || item.game !== 'gta5' || item.files?.length !== 1) throw Error('Unexpected BiggerScript payload type');
    const record = source.get(item.sourcePath), file = item.files[0];
    if (!record?.inspection || record.excludedReason || file.sha256 !== record.sha256 || file.size !== record.size) throw Error('Download differs from inspected public data');
    if (file.url !== publicUrl(output.repository.revision, item.sourcePath, true) || !/\.(?:xml|ini|json)$/i.test(file.name)) throw Error('Not an original pinned data download');
    if (file.downloadMethod === 'direct') throw Error('Text data must use the fetch/blob download path');
    if (!/^[a-f0-9]{64}$/.test(file.sha256) || !Number.isSafeInteger(file.size) || file.size < 1) throw Error('Missing actual file evidence');
    if (!item.requirementLabel || !item.supportedMenus?.length) throw Error('Missing schema-specific importer requirements');
  }
  for (const row of output.libraryOverrides) {
    if (overrides.has(row.id) || !library.has(row.id) || row.files || row.sourceMenu) throw Error('Existing library identity/files/origin must be retained'); overrides.add(row.id);
    const record = source.get(row.sourcePath);
    if (!record?.bundledMap || record.sha256 !== record.bundledMap.source_sha256) throw Error('Bundled map does not match its original source');
  }
  for (const row of output.legacyOverrides) {
    const key = `${row.family}:${row.index}`;
    if (legacy.has(key) || row.family !== 'vehicles' || !Number.isSafeInteger(row.index) || row.index < 0 || row.index >= legacyCount || row.files || row.sourceMenu) throw Error('Invalid duplicate-safe legacy override'); legacy.add(key);
  }
  for (const row of [...output.items, ...output.libraryOverrides, ...output.legacyOverrides].filter(row => row.previewVerified)) {
    const record = source.get(row.sourcePath);
    if (!record?.preview || row.preview !== record.preview.url || ![200, 206].includes(record.preview.status)) throw Error('Unverified preview');
    if (record.preview.sourcePath.replace(/\.[^.]+$/, '').toLowerCase() !== row.sourcePath.replace(/\.[^.]+$/, '').toLowerCase()) throw Error('Preview does not match its data filename');
  }
  if (output.summary.existingBundledMaps !== overrides.size || output.summary.newItems !== ids.size || output.summary.existingLegacyOverrides !== legacy.size) throw Error('Manifest counts are inconsistent');
  return { newItems: ids.size, libraryOverrides: overrides.size, legacyOverrides: legacy.size, excludedRecords: output.audit.records.filter(row => row.excludedReason).length };
}
async function audit({ cachedRevision = false } = {}) {
  const local = localData();
  const previous = fs.existsSync(OUTPUT) ? JSON.parse(fs.readFileSync(OUTPUT, 'utf8')) : {};
  const api = `https://api.github.com/repos/${REPOSITORY}`;
  let repo, commit, files, inventoryFileCount;
  if (cachedRevision) {
    if (previous.repository?.name !== REPOSITORY || !previous.audit?.records?.length) throw Error('No complete pinned source snapshot to resume');
    repo = { license: { spdx_id: previous.repository.license } };
    commit = { sha: previous.repository.revision, commit: { author: { date: previous.repository.commitDate } } };
    files = previous.audit.records.map(row => ({ type: 'blob', path: row.sourcePath, sha: row.gitBlobSha, size: row.size }));
    for (const row of previous.audit.records) if (row.preview) files.push({ type: 'blob', path: row.preview.sourcePath, sha: row.preview.gitBlobSha, size: row.preview.size });
    inventoryFileCount = previous.summary.inspectedRepositoryFiles;
  } else {
    [repo, commit] = await Promise.all([json(api), json(`${api}/commits/main`)]);
  }
  if (!/^[a-f0-9]{40}$/.test(commit.sha)) throw Error('Invalid public revision');
  const revision = commit.sha;
  if (!cachedRevision) {
    const tree = await json(`${api}/git/trees/${revision}?recursive=1`);
    if (tree.truncated) throw Error('Public tree is incomplete');
    files = tree.tree.filter(file => file.type === 'blob'); inventoryFileCount = files.length;
  }
  // This fallback is a previously observed API commit, never an inferred branch
  // head. Cached mode resumes the already audited revision after API failure.
  const loaderCommit = cachedRevision ? { sha: '954fae44c4f747d30a88c9d20ef48d79379f3c29', commit: { author: { date: '2026-06-15T02:35:47Z' } } }
    : await json('https://api.github.com/repos/themilkman554/BiggerScript/commits/BiggestScript');
  if (!/^[a-f0-9]{40}$/.test(loaderCommit.sha)) throw Error('Invalid original loader revision');
  const loaderPath = 'BiggerScript/lib/spawning.lua';
  const loaderSource = `https://github.com/themilkman554/BiggerScript/blob/${loaderCommit.sha}/${loaderPath}`;
  const loaderBytes = Buffer.from(await (await request(`https://raw.githubusercontent.com/themilkman554/BiggerScript/${loaderCommit.sha}/${loaderPath}`)).arrayBuffer());
  const loaderLines = text(loaderBytes).split(/\r?\n/);
  const originalLoader = { repository: 'https://github.com/themilkman554/BiggerScript', revision: loaderCommit.sha, commitDate: loaderCommit.commit.author.date,
    path: loaderPath, sourceUrl: loaderSource, sha256: sha(loaderBytes), functions: ['spawnVehicleFromXML', 'spawnVehicleFromINI', 'spawnVehicleFromJSON', 'spawnMapFromXML', 'spawnMapFromJSON', 'spawnMapFromImpulseJSON']
      .map(name => ({ name, line: loaderLines.findIndex(line => new RegExp(`function\\s+M\\.${name}\\b`).test(line)) + 1 })).filter(item => item.line > 0) };
  const candidates = files.filter(file => /^(?:INI Vehicles|JSON Vehicles|XML Vehicles|JSON Maps|XML Maps)\//.test(file.path) && /\.(?:xml|ini|json)$/i.test(file.path));
  const images = new Map(files.filter(file => /\.(?:png|jpe?g|webp)$/i.test(file.path)).map(file => [file.path.replace(/\.[^.]+$/, '').toLowerCase(), file]));
  const previousRecords = new Map((previous.audit?.records || []).map(row => [row.sourcePath, row]));
  let completed = 0;
  const records = await limited(candidates, async entry => {
    const sourceUrl = publicUrl(revision, entry.path), url = publicUrl(revision, entry.path, true);
    const old = previousRecords.get(entry.path);
    let matches = local.exact.get(entry.sha), signature, bodySha, canonicalSha256, mode = 'exact-public-blob-matches-existing-local-file';
    const bundled = local.mapsByPath.get(entry.path);
    const cached = old?.gitBlobSha === entry.sha && old.inspectionVersion === 2 && old.inspection && old.canonicalSha256;
    try {
      if (cached) { signature = old.inspection; bodySha = old.sha256; canonicalSha256 = old.canonicalSha256; matches ||= local.normalized.get(canonicalSha256); mode = 'previously-verified-public-blob'; }
      else {
        let bytes;
        if (matches?.length) {
          const record = matches[0];
          if (record.family) bytes = fs.readFileSync(path.join(ROOT, record.localPath));
          else {
            const item = read('community/data/library.json').items.find(item => item.id === record.id);
            bytes = fs.readFileSync(path.join(SOURCES, 'cool-repo', item.files[0].path));
          }
        } else {
          if (entry.size > 8 * 1024 * 1024) throw Error('Asset exceeds bounded text-data inspection size');
          const response = await request(url);
          bytes = Buffer.from(await response.arrayBuffer());
          mode = 'public-raw-file-fetched-and-hashed';
        }
        if (bytes.length !== entry.size || gitSha(bytes) !== entry.sha) throw Error('Public file does not match pinned Git blob');
        bodySha = sha(bytes); canonicalSha256 = normalizedHash(bytes); signature = inspect(entry.path, bytes);
        matches ||= local.normalized.get(canonicalSha256);
      }
      const image = images.get(entry.path.replace(/\.[^.]+$/, '').toLowerCase());
      let preview;
      if (image) {
        const response = await request(publicUrl(revision, image.path, true), 'bytes=0-31');
        const reader = response.body.getReader(); let header;
        try { header = Buffer.from((await reader.read()).value || []); } finally { await reader.cancel(); }
        const png = header.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]));
        const jpeg = header[0] === 255 && header[1] === 216 && header[2] === 255;
        const webp = header.subarray(0, 4).toString() === 'RIFF' && header.subarray(8, 12).toString() === 'WEBP';
        if (!/^image\//i.test(response.headers.get('content-type') || '') || !(png || jpeg || webp)) throw Error('Preview is not a verified image response');
        preview = { url: publicUrl(revision, image.path, true), sourcePath: image.path, gitBlobSha: image.sha, size: image.size, status: response.status,
          ...(png && header.length >= 24 ? { width: header.readUInt32BE(16), height: header.readUInt32BE(20) } : {}), association: 'Exact sibling filename stem in original asset repository' };
      }
      const row = { sourcePath: entry.path, sourceUrl, url, gitBlobSha: entry.sha, size: entry.size, sha256: bodySha, canonicalSha256, verification: mode, inspectionVersion: 2, inspection: signature,
        ...(bundled ? { bundledMap: bundled } : {}), ...(matches?.length ? { existingMatches: matches } : {}), ...(preview ? { preview } : {}) };
      if (++completed % 200 === 0) process.stdout.write(`Inspected ${completed}/${candidates.length} public data records.\n`);
      return row;
    } catch (error) { completed++; return { sourcePath: entry.path, sourceUrl, gitBlobSha: entry.sha, size: entry.size, excludedReason: error.message }; }
  });
  const items = [], libraryOverrides = [], legacyOverrides = [], duplicates = new Map();
  for (const row of records) {
    if (!row.inspection) continue;
    const info = row.inspection;
    const metadata = { sourceCollection: 'BiggerScript public asset collection', collection: 'public-author-asset-repository',
      supportedMenus: info.supportedMenus, listedMenus: [...new Set(['scooby', 'nenyoo', ...info.supportedMenus])], format: info.format,
      sourceUrl: row.sourceUrl, sourceRevision: revision, sourcePath: row.sourcePath,
      tags: ['BiggerScript', 'BiggerScript assets', info.format, row.sourcePath.split('/')[0], ...row.sourcePath.split('/').slice(1, -1)],
      credits: info.author ? `${info.author} (author field in source data); collection maintained by TheMilkMan` : 'Original build/map authors; collection maintained by TheMilkMan. Individual authorship is unverified.',
      compatibility: info.requirementLabel, requirementLabel: info.requirementLabel,
      compatibilityStatus: 'static-format-evidence-not-runtime-tested',
      requirements: ['The matching original file-format importer', 'Referenced vehicle, ped and object models', 'The edition and build required by the importer'],
      sourceProvenance: [{ kind: 'pinned-public-author-asset-repository', url: row.sourceUrl, gitBlobSha: row.gitBlobSha, sha256: row.sha256,
        ...(row.bundledMap ? { localInstalledSha256: row.bundledMap.localInstalledSha256, sourceArchiveSha256: row.bundledMap.sourceArchiveSha256, declarationRepaired: row.bundledMap.declaration_repaired } : {}) }],
      changelog: [],
      ...(row.preview ? { preview: row.preview.url, previewVerified: true, previewEvidence: row.preview, previewCaption: 'Original collection preview matched by filename; not a generated illustration.' } : {}),
    };
    if (row.bundledMap) libraryOverrides.push({ id: row.bundledMap.id, ...metadata });
    else if (row.existingMatches?.length) {
      for (const match of row.existingMatches) {
        if (match.family) {
          const additions = { ...metadata };
          // The same data can appear in a map folder and an existing vehicle
          // library. Retain that record's mode-specific compatibility contract.
          if (info.category !== match.family) for (const key of ['supportedMenus', 'listedMenus', 'format', 'compatibility', 'requirementLabel', 'compatibilityStatus', 'requirements']) delete additions[key];
          legacyOverrides.push({ family: match.family, index: match.index, ...additions });
        }
        else libraryOverrides.push({ id: match.id, ...metadata });
      }
    } else if (duplicates.has(row.canonicalSha256)) duplicates.get(row.canonicalSha256).sourceAliases.push(row.sourcePath);
    else {
      const item = { id: `gta5-biggerscript-${info.category}-${sha(row.sourcePath).slice(0, 16)}`, game: 'gta5', category: info.category,
        sourceMenu: info.schema === 'jackz-base-json' && info.category === 'maps' ? 'stand' : 'cherax',
        name: path.posix.basename(row.sourcePath, path.posix.extname(row.sourcePath)).replace(/_/g, ' '),
        description: `${info.category === 'maps' ? 'Object-placement map data' : 'Saved vehicle construct data'} from the public BiggerScript asset collection. This file contains placement/customization instructions, not streamed YMAP/RPF model assets.`,
        ...metadata, files: [{ url: row.url, name: path.posix.basename(row.sourcePath), size: row.size, sha256: row.sha256 }],
        downloadStatus: 'available', sourceAliases: [row.sourcePath], guide: `/resources/guides/?game=gta5&category=${info.category}` };
      items.push(item); duplicates.set(row.canonicalSha256, item);
    }
  }
  const distinct = (rows, key) => [...new Map(rows.map(row => [key(row), row])).values()];
  const library = distinct(libraryOverrides, row => row.id), legacy = distinct(legacyOverrides, row => `${row.family}:${row.index}`);
  const output = { schemaVersion: 1, version: 1, source: 'BiggerScript public asset collection', auditedAt: new Date().toISOString(),
    repository: { name: REPOSITORY, url: ORIGIN, revision, commitDate: commit.commit.author.date, apiTreeTruncated: false, license: repo.license?.spdx_id || 'No repository license declared; original author terms apply. Original public file URLs only.' },
    summary: { inspectedRepositoryFiles: inventoryFileCount, dataRecords: candidates.length, inspectedValidDataRecords: records.filter(row => row.inspection).length,
      existingBundledMaps: local.installedCount, placements: local.manifest.maps.reduce((sum, row) => sum + row.placements, 0), repairedMapDeclarations: local.manifest.maps.filter(row => row.declaration_repaired).length,
      existingLibraryOverrides: library.length, existingLegacyOverrides: legacy.length, newItems: items.length, exactSiblingPreviews: records.filter(row => row.preview).length,
      mapSourcesAlreadyRepresentedAsVehicles: records.filter(row => row.inspection?.category === 'maps' && row.existingMatches?.some(match => match.family === 'vehicles')).length,
      excludedDataRecords: records.filter(row => row.excludedReason).length,
      byFormat: records.filter(row => row.inspection).reduce((out, row) => (out[row.inspection.format] = (out[row.inspection.format] || 0) + 1, out), {}),
      newByCategory: items.reduce((out, item) => (out[item.category] = (out[item.category] || 0) + 1, out), {}) },
    items, libraryOverrides: library, legacyOverrides: legacy,
    coverage: [{ collection: 'BiggerScript public asset repository', status: 'pinned-public-static-data-audit', inspectedDataRecords: candidates.length, existingBundledMaps: local.installedCount, originalArchiveSha256: local.manifest.source_archive_sha256, discordPostsInspected: 0 }],
    evidence: { localBundle: { path: path.join(GTA, 'assets/maps/BiggerScriptMaps.json.zlib'), sha256: sha(fs.readFileSync(path.join(GTA, 'assets/maps/BiggerScriptMaps.json.zlib'))) },
      localMapManifest: { path: path.join(GTA, 'assets/maps/manifest.json'), sha256: sha(fs.readFileSync(path.join(GTA, 'assets/maps/manifest.json'))) },
      importer: path.join(GTA, 'tools/import_biggerscript_maps.py'),
      formatSourcePaths: ['Scooby-Op/GTA5/EE/GTA - Main Src/src/core/services/xml_maps/XMLMapService.cpp', 'Scooby-Op/GTA5/EE/GTA - Main Src/src/core/services/xml_maps/ImpulseMapJson.hpp', 'Scooby-Op/GTA5/EE/GTA - Main Src/src/game/backend/SavedVehicles.cpp', 'project-native-gui/GTAV/src/spooner/preset_loader.cpp', 'project-native-gui/GTAV/src/spooner/spooner_io.cpp'],
      originalLoader, standConstructor: { sourceUrl: 'https://github.com/hexarobi/stand-lua-constructor/tree/06761fc151b367c5cae7e9d3fdd19c3847531cde', evidence: 'Existing stand-public-audit.json records the author README’s JSON/XML/INI/TXT format support; legacy JSTAND requires its matching builder.' } },
    gaps: ['No Discord channel/post history was inspected. Public repository membership does not establish membership in a particular Discord share channel.',
      'TheMilkMan maintains the collection; individual vehicle/map authorship is only asserted when an author field exists in the source JSON.',
      'No game runtime or appearance parity test was run. Stand requires the appropriate Constructor script; Cherax requires the matching BiggerScript loader.',
      'Cherax format evidence comes from the pinned BiggestScript spawning module. The default BiggerScript main branch is a launcher redirect; it is not a tested or republished loader package here.',
      'Constructor vehicle JSON is not labeled as natively supported by Scooby without a schema-specific vehicle adapter check. Nenyoo JSON map import was not established.',
      'Jobs, outfits, SpoonerAssets, ipls.json and decorative logos are outside this vehicle/placement-map audit.',
      'Vehicle screenshots are absent from the audited vehicle directories; no substitute or generated preview was invented.'],
    audit: { publicInventoryMode: cachedRevision ? 'resumed-existing-pinned-public-api-snapshot' : 'fresh-public-api-snapshot', records } };
  validateManifest(output);
  fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
  const temporary = `${OUTPUT}.tmp`; fs.writeFileSync(temporary, JSON.stringify(output)); fs.renameSync(temporary, OUTPUT);
  return output;
}
module.exports = { audit, inspect, localData, validateManifest };
if (require.main === module) {
  const run = process.argv.includes('--check') ? Promise.resolve(validateManifest(JSON.parse(fs.readFileSync(OUTPUT, 'utf8'))))
    : audit({ cachedRevision: process.argv.includes('--cached-revision') }).then(output => output.summary);
  run.then(result => process.stdout.write(JSON.stringify(result, null, 2) + '\n')).catch(error => { process.stderr.write((error.stack || error.message) + '\n'); process.exitCode = 1; });
}
