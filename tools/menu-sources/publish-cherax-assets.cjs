'use strict';

// Copies already-downloaded public asset bodies only. Default --check is wholly
// read-only; --publish requires the exact user-authorized sibling checkout.
// No Git commands, network calls, extraction, Lua execution or shared catalogs.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const TARGET = path.resolve(ROOT, '../cool-repo');
const STAGE_REL = 'project/community-menu-sources/cherax-downloads';
const CATALOG = 'catalog/cherax-acquired-assets.json';
const NAMESPACES = ['downloads/gta5/menus/cherax', 'previews/gta5/menus/cherax'];
const SCHEMA = 'cherax-acquired-assets.v1';
const SOURCES_REL = 'project/community-menu-sources';
const MAX_PART_BYTES = 95000000;
const DIRECTLY_BLOCKED = /\.(?:exe|dll|asi|bat|cmd|ps1|lnk|com|scr|msi|vbs|js|html?|svg|url|pif|jar|py|sh)$/i;
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const within = (root, file) => { const relative = path.relative(root, file); return relative === '' || (!relative.startsWith('..' + path.sep) && relative !== '..' && !path.isAbsolute(relative)); };

function safeRelative(value) {
  if (typeof value !== 'string' || !value || value.includes('\\') || value.includes(':') || value.includes('\0') || path.posix.isAbsolute(value) || value.split('/').some(part => !part || part === '.' || part === '..')) throw new Error('Unsafe relative asset path.');
  return value;
}
function noLinks(file) {
  const absolute = path.resolve(file), parsed = path.parse(absolute);
  let current = parsed.root;
  for (const part of absolute.slice(parsed.root.length).split(path.sep).filter(Boolean)) {
    current = path.join(current, part);
    try { if (fs.lstatSync(current).isSymbolicLink()) throw new Error(`Linked path rejected: ${current}`); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
}
function child(root, relative) {
  const file = path.resolve(root, safeRelative(relative));
  if (!within(root, file) || file === root) throw new Error('Asset path escaped its namespace.');
  noLinks(file); return file;
}
function inspect(bytes, asset) {
  if (asset.actual.extension === '.part') {
    if (asset.expectedKind !== 'split-part' || asset.actual.magic !== 'split-part' || !asset.reconstructionOf || bytes.length > MAX_PART_BYTES) throw new Error('Unbound/oversized reconstruction part rejected.');
    return { magic: 'split-part', extension: '.part' };
  }
  let magic, extension;
  if (bytes.subarray(0, 3).equals(Buffer.from([255, 216, 255]))) { magic = 'JPEG'; extension = '.jpg'; }
  else if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) { magic = 'PNG'; extension = '.png'; }
  else if (/^GIF8[79]a$/.test(bytes.subarray(0, 6).toString())) { magic = 'GIF'; extension = '.gif'; }
  else if (bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP') { magic = 'WEBP'; extension = '.webp'; }
  else if (bytes.subarray(0, 2).toString() === 'BM') { magic = 'BMP'; extension = '.bmp'; }
  else if (bytes.subarray(4, 8).toString() === 'ftyp' && /avif|avis/.test(bytes.subarray(8, 32).toString())) { magic = 'AVIF'; extension = '.avif'; }
  else if (['49492a00', '4d4d002a'].includes(bytes.subarray(0, 4).toString('hex'))) { magic = 'TIFF'; extension = asset.actual.extension === '.tiff' ? '.tiff' : '.tif'; }
  else if (bytes.subarray(0, 4).toString('hex') === '00000100') { magic = 'ICO'; extension = '.ico'; }
  else if (bytes.subarray(0, 9).toString() === 'gimp xcf ') { magic = 'XCF'; extension = '.xcf'; }
  else if (bytes.subarray(0, 4).toString() === '8BPS') { magic = 'PSD'; extension = '.psd'; }
  else if (['504b0304', '504b0506', '504b0708'].includes(bytes.subarray(0, 4).toString('hex'))) { magic = 'ZIP'; extension = '.zip'; }
  else if (bytes.subarray(0, 7).equals(Buffer.from([82, 97, 114, 33, 26, 7, 0])) || bytes.subarray(0, 8).equals(Buffer.from([82, 97, 114, 33, 26, 7, 1, 0]))) { magic = 'RAR'; extension = '.rar'; }
  else if (bytes.subarray(0, 6).equals(Buffer.from([55, 122, 188, 175, 39, 28]))) { magic = '7Z'; extension = '.7z'; }
  else if (asset.actual.extension === '.handling' && bytes.length >= 32 && bytes.length <= 1024 * 1024 && bytes.subarray(0, 12).toString('hex') === '371300000000000002000000') { magic = 'Cherax-handling'; extension = '.handling'; }
  else if (asset.actual.extension === '.jxr' && bytes.length >= 10 && bytes.subarray(0, 4).toString('hex') === '4949bc01') {
    const firstDirectory = bytes.readUInt32LE(4);
    if (firstDirectory >= 8 && firstDirectory <= bytes.length - 2 && firstDirectory % 2 === 0) { magic = 'JPEG-XR'; extension = '.jxr'; }
  }
  else if (bytes.length >= 16 && (bytes.readUInt32LE(0) === 0x52504637 || bytes.subarray(0, 4).toString() === 'RPF7') && bytes.readUInt32LE(12) === 0x4e45504f) { magic = 'RPF7'; extension = '.rpf'; }
  else if (bytes.subarray(0, 4).toString('hex') === '00010000') { magic = 'TTF'; extension = '.ttf'; }
  else if (bytes.subarray(0, 4).toString() === 'OTTO') { magic = 'OTF'; extension = '.otf'; }
  else if (bytes.subarray(0, 4).toString() === 'wOFF') { magic = 'WOFF'; extension = '.woff'; }
  else if (bytes.subarray(0, 4).toString() === 'wOF2') { magic = 'WOFF2'; extension = '.woff2'; }
  else if (['.mp4', '.mov'].includes(asset.actual.extension) && bytes.subarray(4, 8).toString() === 'ftyp') { magic = asset.actual.extension === '.mov' ? 'MOV' : 'MP4'; extension = asset.actual.extension; }
  else if (asset.actual.extension === '.webm' && bytes.subarray(0, 4).toString('hex') === '1a45dfa3') { magic = 'WEBM'; extension = '.webm'; }
  else if (bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'AVI ') { magic = 'AVI'; extension = '.avi'; }
  else if (bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WAVE') { magic = 'WAV'; extension = '.wav'; }
  else if (bytes.subarray(0, 4).toString() === 'OggS') { magic = 'OGG'; extension = '.ogg'; }
  else if (bytes.subarray(0, 4).toString() === 'fLaC') { magic = 'FLAC'; extension = '.flac'; }
  else if (asset.actual.extension === '.m4a' && bytes.subarray(4, 8).toString() === 'ftyp' && /M4A|isom/.test(bytes.subarray(8, 32).toString())) { magic = 'M4A'; extension = '.m4a'; }
  else if (bytes.subarray(0, 3).toString() === 'ID3' || (bytes[0] === 255 && (bytes[1] & 0xe0) === 0xe0)) { magic = 'MP3'; extension = '.mp3'; }
  else if (asset.actual.extension === '.json') {
    const json = JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
    if (!json || typeof json !== 'object') throw new Error('Unexpected JSON resource structure.');
    if (asset.actual.jsonFormat && (json.format !== asset.actual.jsonFormat || json.type !== asset.actual.entityType || json.model !== asset.actual.model)) throw new Error('Entity JSON differs from acquired structure metadata.');
    magic = 'JSON'; extension = '.json';
  }
  else if (['.lua', '.luac'].includes(asset.actual.extension) && bytes[0] === 0x1b && /^(?:Lua|LJ)/.test(bytes.subarray(1, 4).toString())) { magic = 'Lua-bytecode'; extension = asset.actual.extension; }
  else if (['.txt', '.ini', '.lua', '.xml'].includes(asset.actual.extension)) {
    const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    if (text.includes('\0')) throw new Error('NUL-containing text resource rejected.');
    extension = asset.actual.extension;
    if (extension === '.xml') {
      if (/<!DOCTYPE|<!ENTITY/i.test(text) || !/^\s*(?:<\?xml[^>]*>\s*)?<[:A-Za-z_][^>]*>/.test(text)) throw new Error('Unsafe/unrecognized XML resource.');
      magic = 'XML';
    } else magic = extension === '.lua' ? 'UTF8-source-only' : 'UTF8-text';
  }
  const aliases = { 'RIFF-WEBP': 'WEBP', BM: 'BMP', 'ftyp-avif': 'AVIF', '00000100': 'ICO', 'RPF7|7FPR': 'RPF7', '7FPR': 'RPF7', '00010000': 'TTF', OTTO: 'OTF', wOFF: 'WOFF', wOF2: 'WOFF2', 'RIFF-WAVE': 'WAV', OggS: 'OGG', fLaC: 'FLAC', ID3: 'MP3', 'MPEG-frame': 'MP3', 'ftyp-M4A': 'M4A', 'ftyp-isom': 'M4A', 'ftyp-MP4': 'MP4', 'ftyp-MOV': 'MOV', EBML: 'WEBM', 'RIFF-AVI': 'AVI' };
  if (!magic || magic !== (aliases[asset.actual.magic] || asset.actual.magic) || extension !== asset.actual.extension) throw new Error(`Asset magic/extension mismatch: ${asset.assetKey}`);
  if (asset.role === 'thumbnail' && !['JPEG', 'PNG', 'GIF', 'WEBP', 'BMP', 'AVIF', 'TIFF', 'ICO'].includes(magic)) throw new Error('Non-image thumbnail rejected.');
  return { magic, extension };
}
function verifyBody(file, asset, verifyMagic = true) {
  noLinks(file);
  const stat = fs.statSync(file);
  if (!stat.isFile() || stat.size !== asset.actual.size) throw new Error(`Asset size mismatch: ${asset.assetKey}`);
  const bytes = fs.readFileSync(file);
  if (hash(bytes) !== asset.actual.sha256) throw new Error(`Asset SHA-256 mismatch: ${asset.assetKey}`);
  if (verifyMagic) inspect(bytes, asset);
  return bytes;
}
function attributeBody(file) {
  noLinks(file);
  const previous = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  const rules = previous.split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('#'));
  return rules.at(-1) === '* -text' ? previous : previous + (previous && !previous.endsWith('\n') ? '\n' : '') + '* -text\n';
}

function validateReconstructions(records, planned) {
  const bound = new Set();
  for (const record of records.filter(row => row.expectedKind === 'reconstruction-manifest')) {
    const file = planned.get(record.path);
    const document = JSON.parse(fs.readFileSync(file.source || file.destination, 'utf8'));
    const original = record.reconstructionOf;
    if (!original || !/^[a-f0-9]{64}$/.test(original.sha256 || '') || !Number.isSafeInteger(original.size) || original.size <= 0 || typeof original.name !== 'string' || !Array.isArray(document.parts) || document.parts.length < 2) throw new Error('Reconstruction manifest lacks a bounded original/part list.');
    const bodyOriginal = document.original || document.reconstructionOf || document;
    if (bodyOriginal.sha256 !== original.sha256 || bodyOriginal.size !== original.size || (bodyOriginal.name && bodyOriginal.name !== original.name)) throw new Error('Reconstruction manifest original differs from index evidence.');
    const fullHash = crypto.createHash('sha256'); let total = 0;
    for (const part of document.parts) {
      const relative = part.targetRelativePath || part.path;
      if (!/^[a-f0-9]{64}$/.test(part.sha256 || '') || !Number.isSafeInteger(part.size) || part.size <= 0 || part.size > MAX_PART_BYTES || relative !== `${NAMESPACES[0]}/${part.sha256.slice(0, 20)}.part`) throw new Error('Invalid reconstruction part metadata/path.');
      const candidate = planned.get(relative);
      if (!candidate || candidate.expectedKind !== 'split-part' || candidate.actual.sha256 !== part.sha256 || candidate.actual.size !== part.size || candidate.reconstructionOf?.sha256 !== original.sha256 || candidate.reconstructionOf?.size !== original.size) throw new Error('Reconstruction part is missing or bound to different original bytes.');
      if (part.offset !== undefined && part.offset !== total) throw new Error('Reconstruction offsets are not contiguous.');
      const bytes = verifyBody(candidate.source || candidate.destination, candidate);
      fullHash.update(bytes); total += bytes.length; bound.add(relative);
    }
    if (total !== original.size || fullHash.digest('hex') !== original.sha256) throw new Error('Reconstructed original SHA-256/size does not match source evidence.');
  }
  for (const file of planned.values()) if (file.expectedKind === 'split-part' && !bound.has(file.relative)) throw new Error('Split part has no verified reconstruction manifest.');
}

function createPublicationPlan(options = {}) {
  const workspace = path.resolve(options.workspace || ROOT);
  const target = path.resolve(options.target || TARGET), expectedTarget = path.resolve(options.expectedTarget || TARGET);
  if (target.toLowerCase() !== expectedTarget.toLowerCase()) throw new Error('Publishing target must be the exact authorized cool-repo checkout.');
  noLinks(workspace); noLinks(target);
  if (!fs.statSync(target).isDirectory()) throw new Error('Publishing checkout does not exist.');
  const catalogFile = child(target, CATALOG);
  let previous = null;
  if (fs.existsSync(catalogFile)) {
    previous = JSON.parse(fs.readFileSync(catalogFile, 'utf8'));
    if (previous.schema !== SCHEMA || previous.sourceMenu !== 'Cherax' || !Array.isArray(previous.assets)) throw new Error('The dedicated catalog already exists with a different owner/schema; it will not be overwritten.');
  }
  const auditFile = child(workspace, `${SOURCES_REL}/cherax-lua-audit.json`);
  const excludedHashes = new Map((fs.existsSync(auditFile) ? JSON.parse(fs.readFileSync(auditFile)).exclusions || [] : []).filter(row => /^[a-f0-9]{64}$/.test(row.sha256 || '')).map(row => [row.sha256, row.reason]));
  const planned = new Map(), recordMap = new Map(), gapMap = new Map((previous?.acquisitionGaps || []).map(gap => [gap.assetKey, gap]));
  const indexes = [], sourceChecks = new Set();
  const desktopEvidence = new Map();
  const provenanceFields = ['resourceId', 'sourceId', 'sourceCatalog', 'sourceURL', 'originalName', 'sourceType', 'sourceChannelId', 'sourceChannel', 'sourceMessageId', 'sourceGuildId', 'sourceMessageDate', 'sourceAttachmentId', 'attachmentId', 'author', 'sharedBy', 'collection', 'collectionStatus'];
  const provenance = asset => ({
    ...Object.fromEntries(provenanceFields.filter(key => asset[key] !== undefined).map(key => [key, asset[key]])),
    ...(!Array.isArray(asset.provenance) && asset.provenance && typeof asset.provenance === 'object' ? {
      export: Object.fromEntries(['guildId', 'sourceKind', 'sourceLocalPath', 'sourceChannel', 'collection', 'exportFile', 'exportSha256', 'desktopDump'].filter(key => asset.provenance[key] !== undefined).map(key => [key, asset.provenance[key]])),
    } : {}),
  });
  function verifiedDesktopAttachment(row, original, existingRecord) {
    const dump = original.desktopDump;
    const directory = `${SOURCES_REL}/cherax-exports/desktop-dump`;
    const expectedExport = `${directory}/${row.sourceChannelId}.json`;
    const media = `${row.sourceChannelId}-media/`;
    const relative = String(original.sourceLocalPath || '').slice(directory.length + 1);
    if (original.sourceKind !== 'desktop-html-attachment' || original.collection !== 'archival' ||
        original.exportFile !== expectedExport || !/^[a-f0-9]{64}$/.test(original.exportSha256 || '') ||
        dump?.sourceFormat !== 'DiscordChatExporter HTML' || !/^[a-f0-9]{64}$/.test(dump.sha256 || '') ||
        !String(dump.name).endsWith(` [${row.sourceChannelId}].html`) || !String(original.sourceLocalPath).startsWith(`${directory}/${media}`) ||
        !/^[a-f0-9]{24}\.[a-z0-9]+$/.test(relative.slice(media.length))) return false;
    if (existingRecord) return true;
    if (!desktopEvidence.has(expectedExport)) {
      const bytes = fs.readFileSync(child(workspace, expectedExport));
      const document = JSON.parse(bytes);
      if (hash(bytes) !== original.exportSha256 || document.guild.id !== row.sourceGuildId || document.channel.id !== row.sourceChannelId ||
          document.desktopDump?.sha256 !== dump.sha256 || document.messageCount !== dump.declaredMessages || document.messages.length !== document.messageCount) return false;
      desktopEvidence.set(expectedExport, new Map(document.messages.map(message => [message.id, message.attachments])));
    }
    return Boolean(desktopEvidence.get(expectedExport).get(row.sourceMessageId)?.some(asset => asset.url === relative));
  }
  function add(asset, source, existingRecord = false) {
    if (!asset.assetKey || !['payload', 'thumbnail', 'media'].includes(asset.role) || typeof asset.category !== 'string' || !/^[a-z0-9_-]+$/.test(asset.category) || !asset.actual || !/^[a-f0-9]{64}$/.test(asset.actual.sha256) || !Number.isSafeInteger(asset.actual.size) || asset.actual.size <= 0 || asset.actual.size >= 100 * 1024 * 1024 || !/^\.(?:json|jpg|png|gif|webp|bmp|avif|tiff?|ico|xcf|psd|zip|rar|7z|rpf|xml|ini|txt|lua|luac|ttf|otf|woff2?|mp3|wav|ogg|flac|m4a|mp4|mov|webm|avi|jxr|handling|part)$/.test(asset.actual.extension)) throw new Error(`Invalid downloaded asset metadata: ${asset.assetKey}`);
    const rejected = excludedHashes.get(asset.actual.sha256) || (DIRECTLY_BLOCKED.test(asset.originalName || '') ? 'Direct executable, shell/browser script, shortcut or active SVG is retained locally and unpublished.' : null);
    if (rejected) {
      if (existingRecord) throw new Error(`Previously published asset is now excluded by audit: ${asset.assetKey}`);
      gapMap.set(asset.assetKey, { assetKey: asset.assetKey, resourceId: asset.resourceId, sourceURL: asset.sourceURL, originalName: asset.originalName, status: 'excluded', error: rejected }); return;
    }
    if (asset.sourceURL) {
      const url = new URL(asset.sourceURL);
      if (url.protocol !== 'https:' || url.username || url.password) throw new Error('Source provenance URL must be public HTTPS without credentials.');
    } else {
      const history = Array.isArray(asset.provenance) ? asset.provenance : [asset];
      const exactExport = history.some(row => {
        const original = row.export || row.provenance || {};
        return [row.sourceGuildId || original.guildId, row.sourceChannelId, row.sourceMessageId].every(value => /^\d{17,20}$/.test(String(value || ''))) &&
          (/^\d{17,20}$/.test(String(row.sourceAttachmentId || '')) || original.sourceKind === 'embed-image' || verifiedDesktopAttachment(row, original, existingRecord));
      });
      if (!exactExport) throw new Error(`Absent source URL requires exact exported message/attachment provenance: ${asset.assetKey}`);
    }
    if (typeof asset.originalName !== 'string' || !asset.originalName || /[\0\r\n]/.test(asset.originalName)) throw new Error('Missing/invalid original source filename.');
    const namespace = NAMESPACES[asset.role === 'thumbnail' ? 1 : 0];
    const relative = `${namespace}/${asset.actual.sha256.slice(0, 20)}${asset.actual.extension}`;
    if ((asset.targetRelativePath || asset.path) !== relative) throw new Error(`Target mapping is not canonical: ${asset.assetKey}`);
    const destination = child(target, relative);
    const prior = planned.get(relative);
    if (prior && (prior.actual.sha256 !== asset.actual.sha256 || prior.actual.size !== asset.actual.size)) throw new Error(`Truncated-hash destination collision: ${relative}`);
    const checkKey = source + '|' + JSON.stringify(asset.actual);
    if (source && !sourceChecks.has(checkKey)) { verifyBody(source, asset); sourceChecks.add(checkKey); }
    if (!prior) {
      const exists = fs.existsSync(destination);
      if (exists) verifyBody(destination, asset);
      if (!exists && !source) throw new Error(`Previously published body is missing: ${relative}`);
      planned.set(relative, { ...asset, relative, source, destination, exists });
    }
    const priorRecord = recordMap.get(asset.assetKey);
    if (priorRecord && (priorRecord.actual.sha256 !== asset.actual.sha256 || priorRecord.path !== relative)) throw new Error(`Acquisition identity changed bytes or path: ${asset.assetKey}`);
    const history = [...(priorRecord?.provenance || []), ...(Array.isArray(asset.provenance) ? asset.provenance : []), ...(asset.additionalSources || []).map(provenance), provenance(asset)];
    recordMap.set(asset.assetKey, {
      ...priorRecord,
      assetKey: asset.assetKey, resourceId: asset.resourceId, sourceId: asset.sourceId,
      category: asset.category, role: asset.role, name: asset.name, sourceMenu: 'Cherax',
      sourceCatalog: asset.sourceCatalog, sourceURL: asset.sourceURL, originalName: asset.originalName,
      path: relative, actual: { ...asset.actual },
      expectedKind: asset.expectedKind,
      ...(asset.reconstructionOf ? { reconstructionOf: asset.reconstructionOf } : {}),
      provenance: [...new Map(history.map(row => [JSON.stringify(row), row])).values()],
      publisherSha256: asset.publisherSha256 || null, publisherSize: asset.publisherSize ?? null,
      publisherChecksumMatches: asset.publisherChecksumMatches ?? null, publisherSizeMatches: asset.publisherSizeMatches ?? null,
      publisherThumbnailKind: asset.publisherThumbnailKind || null,
      previewEligible: asset.role === 'thumbnail' && asset.previewEligible === true,
      visualReview: asset.visualReview || null,
    });
    gapMap.delete(asset.assetKey);
  }
  for (const asset of previous?.assets || []) add(asset, null, true);
  let inputRecords = 0;
  for (const requested of options.indexes?.length ? options.indexes : [`${STAGE_REL}/asset-index.json`]) {
    const relativeIndex = path.isAbsolute(requested) ? path.relative(workspace, requested).replace(/\\/g, '/') : requested;
    if (!safeRelative(relativeIndex).startsWith(SOURCES_REL + '/') || path.posix.basename(relativeIndex) !== 'asset-index.json') throw new Error('Acquisition indexes must be asset-index.json files inside community-menu-sources.');
    const indexFile = child(workspace, relativeIndex), indexBytes = fs.readFileSync(indexFile), index = JSON.parse(indexBytes);
    if (index.schemaVersion !== 1 || String(index.sourceMenu).toLowerCase() !== 'cherax' || !Array.isArray(index.assets) || !safeRelative(index.stageDirectory).startsWith(SOURCES_REL + '/') || index.stageDirectory !== path.posix.dirname(relativeIndex)) throw new Error('Unexpected Cherax acquisition index schema or staging directory.');
    const stage = child(workspace, index.stageDirectory), seen = new Set();
    indexes.push({ path: relativeIndex, file: indexFile, sha256: hash(indexBytes), snapshot: index.snapshot || null });
    inputRecords += index.assets.length;
    for (const asset of index.assets) {
      if (!asset.assetKey || seen.has(asset.assetKey)) throw new Error('Missing/duplicate acquisition assetKey.');
      seen.add(asset.assetKey);
      if (asset.status !== 'downloaded') { if (!recordMap.has(asset.assetKey)) gapMap.set(asset.assetKey, { assetKey: asset.assetKey, resourceId: asset.resourceId, status: asset.status, error: asset.error || null }); continue; }
      if (asset.localPath !== `${index.stageDirectory}/assets/${asset.targetRelativePath}` || (asset.stagedRelativePath && asset.stagedRelativePath !== `assets/${asset.targetRelativePath}`)) throw new Error(`Staged mapping is not canonical: ${asset.assetKey}`);
      add(asset, child(stage, `assets/${safeRelative(asset.targetRelativePath)}`));
    }
  }
  validateReconstructions([...recordMap.values()], planned);
  const attributes = NAMESPACES.map(namespace => {
    const relative = namespace + '/.gitattributes', file = child(target, relative);
    const body = attributeBody(file), previous = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null;
    return { relative, file, body, changed: previous !== body };
  });
  for (const index of indexes) if (hash(fs.readFileSync(index.file)) !== index.sha256) throw new Error('Acquisition index changed while checking; rerun after the downloader settles.');
  const records = [...recordMap.values()], gaps = [...gapMap.values()];
  const sourceIndexes = [...new Map([...(previous?.sourceIndexes || []), ...indexes.map(({ file, ...row }) => row)].map(row => [`${row.path}:${row.sha256}`, row])).values()];
  return {
    workspace, target, indexes, sourceIndexes,
    files: [...planned.values()], records, gaps, attributes, catalogFile,
    summary: {
      inputRecords, retainedPriorRecords: previous?.assets.length || 0, downloadedRecords: records.length, pendingOrFailedRecords: gaps.length,
      uniqueFiles: planned.size, duplicateReferences: records.length - planned.size,
      uniqueBytes: [...planned.values()].reduce((sum, file) => sum + file.actual.size, 0),
      filesToCopy: [...planned.values()].filter(file => !file.exists).length,
      existingIdenticalFiles: [...planned.values()].filter(file => file.exists).length,
      attributesToWrite: attributes.filter(entry => entry.changed).length,
      target, dedicatedCatalog: CATALOG, sharedCatalogsModified: false,
    },
  };
}

function publish(plan) {
  for (const index of plan.indexes) if (hash(fs.readFileSync(index.file)) !== index.sha256) throw new Error('Acquisition index changed after validation; re-check before publishing.');
  for (const item of plan.attributes) {
    noLinks(item.file); fs.mkdirSync(path.dirname(item.file), { recursive: true });
    if (attributeBody(item.file) !== item.body) throw new Error('Namespace attributes changed after validation.');
    if (item.changed) fs.writeFileSync(item.file, item.body);
  }
  let copied = 0, reused = 0;
  for (const file of plan.files) {
    noLinks(file.destination);
    if (fs.existsSync(file.destination)) { verifyBody(file.destination, file); reused++; continue; }
    verifyBody(file.source, file);
    fs.mkdirSync(path.dirname(file.destination), { recursive: true }); noLinks(path.dirname(file.destination));
    fs.copyFileSync(file.source, file.destination, fs.constants.COPYFILE_EXCL);
    verifyBody(file.destination, file); copied++;
  }
  for (const index of plan.indexes) if (hash(fs.readFileSync(index.file)) !== index.sha256) throw new Error('Acquisition index changed during copying. Copied bodies are intact; catalog update withheld until re-check.');
  const catalog = {
    schema: SCHEMA, schemaVersion: 1, sourceMenu: 'Cherax', generatedAt: new Date().toISOString(),
    sourceIndexes: plan.sourceIndexes,
    policy: {
      bodies: 'Exact downloaded bytes copied without extraction or execution.',
      previews: 'Associated covers remain assets; previewEligible preserves the source classification and is not a visual verification.',
      lua: 'Stored Lua attachments are source assets only. Website Lua cards remain pending with files:[] and no visible Discord link. Known rejected hashes are excluded.',
      sharedCatalog: 'This dedicated acquisition catalog does not modify catalog/menu-resources.json or catalog/library.json.',
    },
    summary: { ...plan.summary, copied, reused }, assets: plan.records, acquisitionGaps: plan.gaps,
  };
  noLinks(plan.catalogFile); fs.mkdirSync(path.dirname(plan.catalogFile), { recursive: true });
  // A dedicated task-owned catalog may be replaced as DLC retries complete.
  fs.writeFileSync(plan.catalogFile, JSON.stringify(catalog, null, 2) + '\n');
  return { ...plan.summary, copied, reused, published: true };
}

function parseArgs(args) {
  const options = { publish: false, indexes: [] };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--publish') options.publish = true;
    else if (args[i] === '--check') options.check = true;
    else if (args[i] === '--target') { options.target = args[++i]; if (!options.target || options.target.startsWith('--')) throw new Error('Missing --target value.'); }
    else if (args[i] === '--index') { const value = args[++i]; if (!value || value.startsWith('--')) throw new Error('Missing --index value.'); options.indexes.push(value); }
    else if (args[i] === '--help') options.help = true;
    else throw new Error(`Unknown argument: ${args[i]}`);
  }
  if (options.publish && options.check) throw new Error('Choose --check or --publish.');
  if (options.publish && !options.target) throw new Error('--publish requires explicit --target pointing to the authorized cool-repo.');
  return options;
}
if (require.main === module) {
  try {
    const options = parseArgs(process.argv.slice(2));
    if (options.help) console.log('Read-only default: --check [--index <bounded asset-index.json> ...]\nWrite validated assets only: --publish --target "C:\\Users\\whatw\\Documents\\GitHub\\cool-repo" [--index <asset-index.json> ...]\nExisting dedicated-catalog provenance is retained when adding indexes.');
    else {
      const plan = createPublicationPlan(options);
      console.log(JSON.stringify(options.publish ? publish(plan) : { ...plan.summary, published: false, writes: 0 }, null, 2));
    }
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
module.exports = { createPublicationPlan, publish, parseArgs, inspect, noLinks };
