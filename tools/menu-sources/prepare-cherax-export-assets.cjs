'use strict';

// Offline preparation only. Exported payloads are read/copied as bytes, never
// loaded, executed or extracted. No networking, account access or final-catalog
// writes. Default mode reads directory metadata only.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const parser = require('./cherax-import-exports.cjs');
const ROOT = path.resolve(__dirname, '../..');
const SOURCE = path.join(ROOT, 'project/community-menu-sources');
const EXPORTS = path.join(SOURCE, 'cherax-exports');
const STAGE = path.join(SOURCE, 'cherax-export-downloads');
const OUTPUT = path.join(SOURCE, 'cherax-export-items.json');
const PREVIEW_REVIEW = path.join(SOURCE, 'cherax-preview-review.json');
const PART_BYTES = 95000000;
const LARGE_BYTES = 100 * 1024 * 1024;
const TEXT_LIMIT = 64 * 1024 * 1024;
const IMAGE_EXT = new Set(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.avif', '.tif', '.tiff', '.ico']);
const VIDEO_EXT = new Set(['.mp4', '.mov', '.webm', '.avi']);
const ARCHIVE_EXT = new Set(['.zip', '.rar', '.7z']);
const ALLOWED = new Set([...IMAGE_EXT, ...VIDEO_EXT, ...ARCHIVE_EXT, '.json', '.tp', '.xml', '.ini', '.txt', '.lua', '.luac', '.rpf', '.ttf', '.otf', '.woff', '.woff2', '.mp3', '.wav', '.ogg', '.flac', '.m4a', '.xcf', '.psd', '.jxr', '.handling']);
function relative(file) { return path.relative(ROOT, file).split(path.sep).join('/'); }
function inside(base, file) { const rel = path.relative(base, file); return rel === '' || (!path.isAbsolute(rel) && rel !== '..' && !rel.startsWith('..' + path.sep)); }
function bounded(value, base, exists = true) {
  const file = path.resolve(ROOT, value);
  if (!inside(base, file)) throw Error(`Path escapes ${relative(base)}.`);
  if (exists && (!fs.existsSync(file) || !inside(fs.realpathSync(base), fs.realpathSync(file)))) throw Error(`Missing or escaping path: ${relative(file)}`);
  return file;
}
function clean(value, limit = 240) { return String(value || '').replace(/[\x00-\x1f\x7f]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, limit); }
function digest(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function json(file) { return JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '')); }
function sameStat(a, b) { return a.size === b.size && a.mtimeMs === b.mtimeMs && a.ino === b.ino; }
function head(file, size = 4096) {
  const fd = fs.openSync(file, 'r'), bytes = Buffer.alloc(size);
  try { return bytes.subarray(0, fs.readSync(fd, bytes, 0, bytes.length, 0)); } finally { fs.closeSync(fd); }
}
function hashFile(file) {
  const before = fs.statSync(file), hash = crypto.createHash('sha256'), bytes = Buffer.alloc(1024 * 1024), fd = fs.openSync(file, 'r');
  let size = 0;
  try { for (let count; (count = fs.readSync(fd, bytes, 0, bytes.length, null));) { hash.update(bytes.subarray(0, count)); size += count; } } finally { fs.closeSync(fd); }
  if (!sameStat(before, fs.statSync(file)) || before.size !== size) throw Error('Source changed while hashing. Retry after export completion.');
  return { sha256: hash.digest('hex'), size };
}
function inventory(input) {
  if (!fs.existsSync(input)) return [];
  const info = fs.lstatSync(input);
  if (info.isSymbolicLink()) throw Error('Symlink/reparse input rejected.');
  if (info.isFile()) return [{ path: relative(input), bytes: info.size, modifiedAt: info.mtime.toISOString() }];
  // Channel JSONs are at the root; media folders are deliberately not scanned.
  return fs.readdirSync(input).sort().flatMap(name => { const file = path.join(input, name), stat = fs.lstatSync(file); return stat.isFile() && !stat.isSymbolicLink() ? [{ path: relative(file), bytes: stat.size, modifiedAt: stat.mtime.toISOString() }] : []; });
}
function localAttachment(asset, exportFile) {
  if (asset.localPath) return bounded(asset.localPath, EXPORTS);
  const value = asset.url;
  if (typeof value !== 'string' || !value || /^[a-z][a-z0-9+.-]*:/i.test(value) || path.isAbsolute(value)) return null;
  let file = path.resolve(path.dirname(exportFile), value.replace(/\\/g, '/'));
  if (!fs.existsSync(file)) { try { file = path.resolve(path.dirname(exportFile), decodeURIComponent(value).replace(/\\/g, '/')); } catch {} }
  if (!inside(EXPORTS, file)) throw Error('Attachment escapes cherax-exports.');
  if (!fs.existsSync(file)) return null;
  const result = bounded(file, EXPORTS);
  if (!fs.statSync(result).isFile()) throw Error('Attachment is not a regular file.');
  return result;
}
function sourceAsset(asset, exportFile) {
  const name = clean(asset.fileName || asset.name || path.posix.basename(String(asset.canonicalUrl || asset.url || '').split('?')[0]));
  let local = null, issue = null;
  try { local = localAttachment(asset, exportFile); } catch (error) { issue = error.message; }
  return { ...asset, name, extension: path.extname(name).toLowerCase(), sourceAttachmentId: asset.sourceAttachmentId || asset.id || null, sourceUrl: /^https:\/\//i.test(asset.canonicalUrl || '') ? asset.canonicalUrl : /^https:\/\//i.test(asset.url || '') ? asset.url : asset.sourceUrl || null, sourceKind: asset.sourceKind || 'attachment', localPath: local ? relative(local) : null, localExists: Boolean(local), issue, format: asset.format || { formatChecked: false } };
}
function validateBytes(file, extension, category) {
  const bytes = head(file), ascii = bytes.toString('latin1'), size = fs.statSync(file).size;
  if (!size) return { valid: false, reason: 'Empty file.' };
  if (/^MZ|^\x7fELF|^#!/.test(ascii) && extension !== '.lua') return { valid: false, reason: 'Executable/script signature does not match an allowed resource format.' };
  if (extension === '.handling') {
    if (size < 32 || size > 1024 * 1024 || !ascii.startsWith('\x37\x13\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00')) return { valid: false, reason: 'Unrecognized Cherax handling data header.' };
    return { valid: true, extension, magic: 'Cherax-handling', contentType: 'application/octet-stream', catalogOnly: true,
      format: { status: 'observed_handling_header_only', runtimeVerified: false } };
  }
  if (extension === '.jxr') {
    const firstDirectory = bytes.length >= 8 ? bytes.readUInt32LE(4) : 0;
    if (!ascii.startsWith('II\xBC\x01') || firstDirectory < 8 || firstDirectory > size - 2 || firstDirectory % 2 !== 0) return { valid: false, reason: 'Unrecognized JPEG XR header or directory offset.' };
    return { valid: true, extension, magic: 'JPEG-XR', contentType: 'image/jxr', catalogOnly: true,
      format: { status: 'signature_verified_only', runtimeVerified: false } };
  }
  const signatures = {
    '.png': [bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])), 'PNG', 'image/png'],
    '.jpg': [bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255, 'JPEG', 'image/jpeg'],
    '.jpeg': [bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255, 'JPEG', 'image/jpeg'],
    '.gif': [/^GIF8[79]a/.test(ascii), 'GIF', 'image/gif'],
    '.webp': [ascii.startsWith('RIFF') && ascii.slice(8, 12) === 'WEBP', 'WEBP', 'image/webp'],
    '.bmp': [ascii.startsWith('BM'), 'BMP', 'image/bmp'],
    '.avif': [ascii.slice(4, 8) === 'ftyp' && /avif|avis/.test(ascii.slice(8, 40)), 'AVIF', 'image/avif'],
    '.tif': [/^(?:II\x2a\x00|MM\x00\x2a)/.test(ascii), 'TIFF', 'image/tiff'],
    '.tiff': [/^(?:II\x2a\x00|MM\x00\x2a)/.test(ascii), 'TIFF', 'image/tiff'],
    '.ico': [bytes.subarray(0, 4).equals(Buffer.from([0,0,1,0])), 'ICO', 'image/x-icon'],
    '.zip': [/^PK(?:\x03\x04|\x05\x06|\x07\x08)/.test(ascii), 'ZIP', 'application/zip'],
    '.rar': [ascii.startsWith('Rar!\x1a\x07'), 'RAR', 'application/vnd.rar'],
    '.7z': [bytes.subarray(0, 6).equals(Buffer.from([55,122,188,175,39,28])), '7Z', 'application/x-7z-compressed'],
    '.rpf': [/^(?:RPF7|7FPR)/.test(ascii), 'RPF7', 'application/octet-stream'],
    '.ttf': [bytes.subarray(0, 4).equals(Buffer.from([0,1,0,0])) || ascii.startsWith('true'), 'TTF', 'font/ttf'],
    '.otf': [ascii.startsWith('OTTO'), 'OTF', 'font/otf'],
    '.woff': [ascii.startsWith('wOFF'), 'WOFF', 'font/woff'],
    '.woff2': [ascii.startsWith('wOF2'), 'WOFF2', 'font/woff2'],
    '.mp3': [ascii.startsWith('ID3') || (bytes[0] === 255 && (bytes[1] & 0xe0) === 0xe0), 'MP3', 'audio/mpeg'],
    '.wav': [ascii.startsWith('RIFF') && ascii.slice(8, 12) === 'WAVE', 'WAV', 'audio/wav'],
    '.ogg': [ascii.startsWith('OggS'), 'OGG', 'audio/ogg'],
    '.flac': [ascii.startsWith('fLaC'), 'FLAC', 'audio/flac'],
    '.m4a': [ascii.slice(4, 8) === 'ftyp' && /M4A |isom|mp42/.test(ascii.slice(8, 40)), 'M4A', 'audio/mp4'],
    '.mp4': [ascii.slice(4, 8) === 'ftyp' && /isom|iso[2-9]|mp4[12]|avc1|M4V |dash/.test(ascii.slice(8, 64)), 'MP4', 'video/mp4'],
    '.mov': [ascii.slice(4, 8) === 'ftyp' && /qt  /.test(ascii.slice(8, 64)), 'MOV', 'video/quicktime'],
    '.webm': [bytes.subarray(0, 4).equals(Buffer.from([26,69,223,163])) && ascii.toLowerCase().includes('webm'), 'WEBM', 'video/webm'],
    '.avi': [ascii.startsWith('RIFF') && ascii.slice(8, 12) === 'AVI ', 'AVI', 'video/x-msvideo'],
    '.xcf': [ascii.startsWith('gimp xcf '), 'XCF', 'application/octet-stream'],
    '.psd': [ascii.startsWith('8BPS') && bytes[4] === 0 && [1, 2].includes(bytes[5]), 'PSD', 'application/octet-stream'],
  };
  if (signatures[extension]) {
    const family = [IMAGE_EXT, VIDEO_EXT, ARCHIVE_EXT].find(types => types.has(extension));
    const detected = signatures[extension][0] ? extension : family && [...family].find(type => signatures[type][0]);
    if (!detected) return { valid: false, reason: `Signature mismatch for ${extension}.` };
    const [, magic, contentType] = signatures[detected];
    const canonical = { '.jpeg': '.jpg', '.tiff': '.tif' }[detected] || detected;
    return { valid: true, magic, contentType, extension: canonical,
      format: { status: 'signature_verified_only', runtimeVerified: false, ...(detected !== extension ? { declaredExtension: extension } : {}) } };
  }
  if (['.lua', '.luac'].includes(extension) && (ascii.startsWith('\x1bLua') || ascii.startsWith('\x1bLJ'))) return { valid: true, magic: 'Lua-bytecode', extension, contentType: 'application/octet-stream', format: { status: 'lua_bytecode_header_only_not_executed', runtimeVerified: false } };
  if (!['.json', '.tp', '.xml', '.ini', '.txt', '.lua'].includes(extension)) return { valid: false, reason: `Unsupported resource format ${extension || '(no extension)'}.` };
  if (size > TEXT_LIMIT) return { valid: false, reason: 'Text/JSON exceeds the 64 MiB review bound; original bytes retained locally.' };
  let text;
  try { text = new TextDecoder('utf-8', { fatal: true }).decode(fs.readFileSync(file)).replace(/^\uFEFF/, ''); } catch { return { valid: false, reason: 'Text is not valid UTF-8.' }; }
  if (/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(text)) return { valid: false, reason: 'Binary control bytes in text resource.' };
  let format = { status: extension === '.lua' ? 'utf8_lua_source_not_executed' : 'utf8_text_only', runtimeVerified: false };
  if (extension === '.json' || extension === '.tp') {
    let value;
    try { value = JSON.parse(text); } catch {
      const fencedJson = text.match(/^\s*```json\s*(\{[\s\S]*\})\s*(?:```)?\s*$/i)?.[1];
      let validFencedJson = false;
      if (fencedJson) try { validFencedJson = Boolean(JSON.parse(fencedJson)); } catch {}
      if (extension === '.json' && ((category === 'languages' && /^\s*\{/.test(text)) || validFencedJson)) {
        return { valid: true, magic: 'UTF8-text', extension: '.txt', contentType: 'text/plain', catalogOnly: true,
          format: { status: 'json_source_archived_as_text', runtimeVerified: false, declaredExtension: extension } };
      }
      return { valid: false, reason: 'Invalid JSON syntax.' };
    }
    if (extension === '.tp') {
      if (!value || Object.keys(value).length !== 4 || !['X', 'Y', 'Z', 'Heading'].every(key => Number.isFinite(value[key]))) return { valid: false, reason: 'Unrecognized teleport point JSON.' };
      return { valid: true, magic: 'JSON', extension: '.json', contentType: 'application/json', catalogOnly: true,
        format: { status: 'teleport_point_json', runtimeVerified: false, declaredExtension: extension } };
    }
    if (!value || typeof value !== 'object') return { valid: false, reason: 'JSON resource requires an object or array.' };
    format = parser.validateJson(value, category);
    if (format.status === 'valid_json_only' && category === 'outfits' && Number.isInteger(value.model) && ['components', 'props', 'blend_data'].every(key => value[key] && typeof value[key] === 'object' && !Array.isArray(value[key]))) format = { ...format, status: 'legacy_outfit_json' };
  }
  if (extension === '.xml' && (!/^\s*(?:<\?xml[^>]*\?>\s*)?(?:<!--[\s\S]*?-->\s*)*<[A-Za-z_][\w:.-]*(?:\s|>|\/)/.test(text) || /<!DOCTYPE|<!ENTITY/i.test(text))) return { valid: false, reason: 'XML root missing or DTD/entity declaration rejected; no XML engine invoked.' };
  return { valid: true, magic: extension === '.json' ? 'JSON' : extension === '.lua' ? 'UTF8-source-only' : extension === '.xml' ? 'XML' : 'UTF8-text', extension, contentType: extension === '.json' ? 'application/json' : extension === '.xml' ? 'application/xml' : 'text/plain', format };
}
function normalizeCollection(item) {
  const original = item.sourceCollection || item.collection;
  if (['old', 'archival'].includes(original) || item.collectionStatus === 'archival') { item.sourceCollection ||= original; item.collection = 'old'; item.collectionStatus = 'archival'; item.discordCollection = 'old'; }
  else if (original === 'current') { item.sourceCollection ||= original; item.collection = 'current'; item.collectionStatus = 'current'; item.discordCollection = 'current'; }
  return item;
}
function normalizeReview(data, known = null) {
  const media = new Map((data.mediaOnlyPostsForReview || []).map(item => [item.id, normalizeCollection(item)])), items = [];
  for (const original of data.items || []) {
    const item = normalizeCollection(original);
    item.files = (item.files || []).map(file => { const { url, ...rest } = file; return { ...rest, path: file.path || url }; });
    if (item.luaPayload || item.category === 'lua') { item.files = []; item.downloadStatus = 'pending'; item.status = 'pending'; item.showSourceLink = false; delete item.sourceUrl; }
    const videoFiles = item.files.filter(file => VIDEO_EXT.has(path.extname(file.reconstructionOf?.name || file.name || file.path || '').toLowerCase()));
    if (videoFiles.length && item.mediaIntent !== 'animated-wallpaper-candidate') {
      media.set(item.id, { ...item, resourceCard: false, mediaOnly: true, mediaType: 'video', mediaFiles: item.files, files: [], downloadStatus: 'pending', status: 'review', reason: 'Source video/showcase acquired intact. Its intended role as an installable resource or animated wallpaper is not established by the share channel or filename.' });
      continue;
    }
    if (videoFiles.length) { item.format = `${path.extname(videoFiles[0].reconstructionOf?.name || videoFiles[0].name).slice(1).toUpperCase()} animated wallpaper candidate`; item.formatExtension = path.extname(videoFiles[0].reconstructionOf?.name || videoFiles[0].name).slice(1).toLowerCase(); item.videoIntentReviewRequired = true; }
    item.publicationStatus = 'staged';
    if (!item.luaPayload && item.category !== 'lua') { item.status = 'review'; item.downloadStatus = item.files.length ? 'staged' : 'pending'; }
    items.push(item);
  }
  data.items = items;
  data.mediaOnlyPostsForReview = [...media.values()];
  for (const item of data.imageOnlyPostsForReview || []) normalizeCollection(item);
  for (const item of data.existingResourceAssociations || []) { const record = known?.get(item.sourceParentId || item.sourceChannelId); if (record && !item.collection) item.collection = record.collection; normalizeCollection(item); }
  data.policy.video = 'Showcase/ambiguous videos remain acquired media-only review records. Only explicitly labelled animated-wallpaper video sources remain format-labelled resource candidates; no video is an image preview.';
  data.summary.newReviewableItems = items.length;
  data.summary.mediaOnlyPostsForReview = data.mediaOnlyPostsForReview.length;
  data.summary.luaCardsPending = items.filter(item => item.luaPayload || item.category === 'lua').length;
  return data;
}
function applyPreviewReview(data, index, review, verifySource = null) {
  const actual = new Map((index.assets || []).map(asset => [asset.assetKey, asset])), decisions = new Map((review.itemDecisions || []).map(item => [item.id, item]));
  const entries = new Map(), unmatched = [];
  for (const entry of review.entries || []) {
    const asset = actual.get(entry.assetKey);
    if (!asset || entry.sourceSHA256 !== asset.actual?.sha256 || !IMAGE_EXT.has(asset.actual.extension) || asset.role !== 'thumbnail' || entry.targetRelativePath !== asset.targetRelativePath || entry.localPath !== asset.localPath || (entry.sourceBytes != null && entry.sourceBytes !== asset.actual.size)) { unmatched.push({ assetKey: entry.assetKey, sourceSHA256: entry.sourceSHA256, reason: 'Exact acquired image key/hash/path/format did not match; decision not applied.' }); continue; }
    if (verifySource) verifySource(asset);
    const key = `${entry.assetKey}:${entry.sourceSHA256}`;
    if (entries.has(key)) throw Error('Duplicate visual QA key/hash decision.');
    entries.set(key, { entry, asset });
  }
  const byTargetHash = new Map([...entries.values()].map(value => [`${value.asset.targetRelativePath}:${value.asset.actual.sha256}`, value]));
  let verifiedItems = 0, verifiedAssociations = 0, withheldItems = 0;
  const apply = (item, association = false, canPromote = true) => {
    const id = item.id || item.sourceCandidateId, decision = decisions.get(id);
    const candidates = [...(item.previewCandidates || []), ...(item.files || []).filter(file => IMAGE_EXT.has(path.extname(file.path || '').toLowerCase())).map(file => ({ path: file.path, sha256: file.sha256 }))];
    const matching = new Map();
    for (const candidate of candidates) { const value = byTargetHash.get(`${candidate.path}:${candidate.sha256}`); if (value) matching.set(value.asset.assetKey, value); }
    item.preview = null; item.previewPath = null; item.localPreview = null; item.previewVerified = false; item.previewEligible = false; item.previewStatus = 'withheld';
    item.publicationStatus = 'staged';
    item.previewReviews = [];
    for (const { entry, asset } of matching.values()) {
      const itemMatch = Boolean(decision && decision.sourceChannelId === item.sourceChannelId && decision.sourceMessageId === item.sourceMessageId && decision.reviewedImageAssets?.some(image => image.assetKey === asset.assetKey && image.sourceSHA256 === asset.actual.sha256 && image.previewEligible === true));
      const associationMatch = association && entry.sourceChannelId === item.sourceChannelId && entry.sourceMessageId === item.sourceMessageId && (entry.existingResourceIds || []).some(existingId => (item.existingResources || []).some(resource => resource.id === existingId));
      const eligible = canPromote && entry.previewEligible === true && entry.visualPreviewEligible !== false && (association ? associationMatch : itemMatch && decision.previewEligible === true);
      item.previewReviews.push({ assetKey: asset.assetKey, sourceSHA256: asset.actual.sha256, path: asset.targetRelativePath, localPath: asset.localPath, previewEligible: eligible, visualPreviewEligible: entry.visualPreviewEligible, classification: entry.classification, observation: entry.observation, reviewConfidence: entry.reviewConfidence, associationStatus: entry.associationStatus, eligibilityBasis: entry.eligibilityBasis, reviewEvidence: entry.reviewEvidence, sourceImageProvenance: { sourceGuildId: asset.sourceGuildId || asset.provenance?.guildId, sourceChannelId: asset.sourceChannelId, sourceMessageId: asset.sourceMessageId, sourceAttachmentId: asset.sourceAttachmentId, ...asset.provenance }, reviewFile: relative(PREVIEW_REVIEW), reviewedAt: review.reviewedAt, width: entry.width, height: entry.height, runtimeVerified: false });
    }
    for (const candidate of item.previewCandidates || []) { const reviewed = item.previewReviews.find(entry => entry.path === candidate.path && entry.sourceSHA256 === candidate.sha256); candidate.previewVerified = Boolean(reviewed?.previewEligible); candidate.previewEligible = Boolean(reviewed?.previewEligible); if (reviewed) candidate.assetKey = reviewed.assetKey; }
    const selected = item.previewReviews.find(entry => entry.previewEligible);
    if (selected) { item.preview = selected.path; item.previewPath = selected.path; item.localPreview = selected.localPath; item.previewVerified = true; item.previewEligible = true; item.previewStatus = 'staged'; item.previewBasis = selected.eligibilityBasis; item.previewClassification = selected.classification; item.previewReviewConfidence = selected.reviewConfidence; item.previewObservation = selected.observation; if (association) verifiedAssociations++; else verifiedItems++; }
    else if (item.previewReviews.length) withheldItems++;
  };
  for (const item of data.items || []) apply(item);
  for (const item of data.existingResourceAssociations || []) apply(item, true);
  for (const item of [...(data.imageOnlyPostsForReview || []), ...(data.mediaOnlyPostsForReview || [])]) apply(item, false, false);
  data.previewReview = { path: relative(PREVIEW_REVIEW), reviewedAt: review.reviewedAt, method: review.method, matchedImageAssets: entries.size, unmatchedImageAssets: unmatched.length, verifiedItems, verifiedExistingAssociations: verifiedAssociations, withheldItems, unmatched, publicationStatus: 'staged', runtimeVerified: false };
  data.policy.previews = 'Only exact acquired-image assetKey/SHA256 matches with eligible visual QA and explicit item/source-post association receive staged source preview paths. Videos, source projects and ineligible images are never previews. Files remain retained.';
  data.summary.visuallyVerifiedPreviews = verifiedItems;
  data.summary.visuallyVerifiedExistingPreviews = verifiedAssociations;
  return data;
}
function consumePreviewReview(data, index) {
  if (!fs.existsSync(PREVIEW_REVIEW)) return data;
  const review = json(PREVIEW_REVIEW), checked = new Set();
  return applyPreviewReview(data, index, review, asset => {
    if (checked.has(asset.assetKey)) return;
    const file = bounded(asset.localPath, STAGE), actual = hashFile(file);
    if (actual.sha256 !== asset.actual.sha256 || actual.size !== asset.actual.size || asset.targetRelativePath !== targetPath(actual.sha256, asset.actual.extension, true) || !validateBytes(file, asset.actual.extension, asset.category).valid) throw Error('Visual QA source image bytes/signature/path no longer match acquisition evidence.');
    checked.add(asset.assetKey);
  });
}
function readExports(input, known, skipped) {
  const items = [], orphanImages = [];
  for (const entry of inventory(input).filter(entry => /\.json$/i.test(entry.path))) {
    const file = bounded(entry.path, EXPORTS), before = fs.statSync(file);
    if (!before.size || Date.now() - before.mtimeMs < 30000) { skipped.push({ path: entry.path, reason: 'Empty or modified within 30 seconds; not inspected.' }); continue; }
    if (before.size > 512 * 1024 * 1024) { skipped.push({ path: entry.path, reason: 'Export exceeds 512 MiB JSON bound.' }); continue; }
    // Asset JSONs and unrelated files are never interpreted as chat envelopes.
    let beginning;
    try { beginning = head(file).toString('utf8').replace(/^\uFEFF/, ''); }
    catch (error) {
      if (error.code !== 'EBUSY' && error.code !== 'ENOENT') throw error;
      skipped.push({ path: entry.path, reason: 'Export is still being written or was replaced.' });
      continue;
    }
    if (!/^\s*\{\s*"guild"\s*:/.test(beginning)) continue;
    const metadataEnd = beginning.indexOf('"messages"');
    let metadata;
    try { metadata = JSON.parse(beginning.slice(0, metadataEnd > 0 ? metadataEnd : beginning.length).replace(/,\s*$/, '') + '}'); } catch { skipped.push({ path: entry.path, reason: 'Channel metadata prefix could not be verified before message inspection.' }); continue; }
    const initialClassification = parser.classifyChannel(metadata, known);
    if (!initialClassification.accepted) { skipped.push({ path: entry.path, reason: initialClassification.reason }); continue; }
    let document, exportBytes;
    try { exportBytes = fs.readFileSync(file); document = JSON.parse(exportBytes.toString('utf8').replace(/^\uFEFF/, '')); } catch (error) { skipped.push({ path: entry.path, reason: `Incomplete/invalid export JSON: ${error.message}` }); continue; }
    if (!sameStat(before, fs.statSync(file)) || !Array.isArray(document.messages) || !document.dateRange || !document.exportedAt || document.messageCount !== document.messages.length) { skipped.push({ path: entry.path, reason: 'Changing or incomplete export envelope/message count.' }); continue; }
    const classification = parser.classifyChannel(document, known);
    if (!classification.accepted) { skipped.push({ path: entry.path, reason: classification.reason }); continue; }
    const exportSha256 = digest(exportBytes);
    const luaThread = classification.category === 'lua' && classification.isThread;
    const starter = luaThread ? document.messages.find(message => message.id === document.channel.id) || document.messages[0] : null;
    for (const message of document.messages) {
      if (!/^\d{15,22}$/.test(message.id || '') || typeof message.content !== 'string' || !Number.isFinite(Date.parse(message.timestamp))) continue;
      const attachments = (message.attachments || []).map(asset => sourceAsset(asset, file));
      const images = attachments.filter(asset => IMAGE_EXT.has(asset.extension));
      for (const embed of message.embeds || []) for (const image of [embed.image, ...(Array.isArray(embed.images) ? embed.images : [])].filter(Boolean)) {
        const asset = sourceAsset({ ...image, sourceKind: 'embed-image', fileName: path.posix.basename(String(image.canonicalUrl || image.url || '').split('?')[0]) }, file);
        if (IMAGE_EXT.has(asset.extension)) images.push(asset);
      }
      const resources = attachments.filter(asset => !IMAGE_EXT.has(asset.extension) || classification.category === 'wallpapers');
      for (const asset of resources) { const item = parser.candidate(document, classification, message, asset, images, [], file); if (item) { item.provenance.exportSha256 = exportSha256; if (VIDEO_EXT.has(asset.extension)) { item.formatExtension = asset.extension.slice(1); item.mediaIntent = classification.category === 'wallpapers' && /\b(?:animated|live|video)[\s_-]+wallpaper\b|\bwallpaper[\s_-]*engine\b/i.test(`${message.content}\n${asset.name}\n${classification.isThread ? document.channel.name : ''}`) ? 'animated-wallpaper-candidate' : 'unverified-video-role'; if (item.mediaIntent === 'animated-wallpaper-candidate') item.mediaIntentBasis = 'Explicit animated/live/video-wallpaper or Wallpaper Engine wording in the same source message, filename or thread title; visual intent and usage still require review.'; } items.push(item); } }
      const luaRelease = luaThread && (message === starter ||
        (starter?.author?.id && message.author?.id === starter.author.id && parser.versions(message.content).version));
      if (!resources.length && luaRelease) {
        const item = parser.candidate(document, classification, message, null, images, [], file);
        if (item) {
          item.provenance.exportSha256 = exportSha256;
          items.push(item);
          continue;
        }
      }
      if (!resources.length && images.length) orphanImages.push({ id: `cherax-export-images-${document.channel.id}-${message.id}`, category: classification.category, sourceChannelId: document.channel.id, sourceMessageId: message.id, sourceParentId: classification.parentId, sourceChannel: classification.sourceChannel, collection: classification.collection, name: clean(document.channel.name), provenance: { exportFile: entry.path, exportSha256, guildId: document.guild.id, ...(document.desktopDump ? { desktopDump: document.desktopDump } : {}) }, assets: [], images, luaPayload: classification.category === 'lua' });
      if (!resources.length && !images.length && /https:\/\//.test(message.content)) { const item = parser.candidate(document, classification, message, null, [], [], file); if (item) { item.provenance.exportSha256 = exportSha256; items.push(item); } }
    }
  }
  return { items, orphanImages };
}
function existingResources() {
  const byHash = new Map(), bySourceHash = new Map(), snapshot = json(path.join(ROOT, 'project/community-marketplace/modverse.json'));
  for (const catalog of snapshot.catalogs || []) for (const item of catalog.data?.items || []) for (const hash of new Set([item.sha256, item.source_sha256].filter(value => /^[a-f0-9]{64}$/i.test(value || '')))) {
    const kind = catalog.data.category, record = { id: `gta5-modverse-${kind}-${item.id}`, sourceId: item.id, sourceCatalog: catalog.path };
    const key = `${item.source_channel_id}:${item.source_message_id}:${hash}`;
    for (const [map, mapKey] of [[byHash, hash], [bySourceHash, key]]) { if (!map.has(mapKey)) map.set(mapKey, []); if (!map.get(mapKey).some(entry => entry.id === record.id)) map.get(mapKey).push(record); }
  }
  return { byHash, bySourceHash };
}
function writeJson(file, value) { if (!inside(SOURCE, path.resolve(file))) throw Error('Output escaped source workspace.'); fs.mkdirSync(path.dirname(file), { recursive: true }); if (!inside(fs.realpathSync(SOURCE), fs.realpathSync(path.dirname(file))) || (fs.existsSync(file) && fs.lstatSync(file).isSymbolicLink())) throw Error('Output symlink/reparse escape rejected.'); fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n'); }
function targetPath(hash, extension, image) { return `${image ? 'previews' : 'downloads'}/gta5/menus/cherax/${hash.slice(0, 20)}${extension}`; }
function safeStageFile(target) {
  const file = path.resolve(STAGE, 'assets', target);
  if (!inside(path.join(STAGE, 'assets'), file)) throw Error('Staging target escaped assets directory.');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (!inside(fs.realpathSync(STAGE), fs.realpathSync(path.dirname(file)))) throw Error('Staging directory symlink/reparse escape.');
  if (fs.existsSync(file) && fs.lstatSync(file).isSymbolicLink()) throw Error('Staging target symlink rejected.');
  return file;
}
function splitFile(file, original, base, limit = PART_BYTES) {
  const fd = fs.openSync(file, 'r'), parts = [], buffer = Buffer.alloc(Math.min(1024 * 1024, limit));
  try {
    let position = 0;
    while (position < original.size) {
      const temp = path.join(STAGE, `part-${process.pid}-${parts.length}.tmp`), out = fs.openSync(temp, 'wx'), hash = crypto.createHash('sha256');
      let size = 0;
      try { while (size < limit && position < original.size) { const count = fs.readSync(fd, buffer, 0, Math.min(buffer.length, limit - size, original.size - position), position); if (!count) throw Error('Source ended during splitting.'); fs.writeSync(out, buffer, 0, count); hash.update(buffer.subarray(0, count)); size += count; position += count; } } finally { fs.closeSync(out); }
      const sha256 = hash.digest('hex'), targetRelativePath = targetPath(sha256, '.part', false), localPath = safeStageFile(targetRelativePath);
      if (fs.existsSync(localPath)) { const existing = hashFile(localPath); if (existing.sha256 !== sha256) throw Error('Part target hash collision or changed bytes.'); fs.unlinkSync(temp); } else fs.renameSync(temp, localPath);
      parts.push({ ...base, assetKey: `${base.assetKey}:part:${parts.length + 1}`, originalName: `${original.name}.part${String(parts.length + 1).padStart(3, '0')}`, expectedKind: 'split-part', targetRelativePath, stagedRelativePath: `assets/${targetRelativePath}`, localPath: relative(localPath), actual: { size, sha256, extension: '.part', magic: 'split-part', contentType: 'application/octet-stream' }, reconstructionOf: { sha256: original.sha256, size: original.size, name: original.name }, partNumber: parts.length + 1 });
    }
  } finally { fs.closeSync(fd); }
  const manifest = { schemaVersion: 1, type: 'binary-concatenation', original, partBytes: limit, instructions: 'Concatenate parts as binary in the listed order, then verify the full SHA-256 and byte size before use. These files are source assets; no payload is executed by this collection.', parts: parts.map(({ partNumber, targetRelativePath, actual }) => ({ partNumber, targetRelativePath, size: actual.size, sha256: actual.sha256 })) };
  const bytes = Buffer.from(JSON.stringify(manifest, null, 2) + '\n'), sha256 = digest(bytes), targetRelativePath = targetPath(sha256, '.json', false), filePath = safeStageFile(targetRelativePath);
  fs.writeFileSync(filePath, bytes);
  return [...parts, { ...base, assetKey: `${base.assetKey}:reconstruction`, originalName: `${original.name}.reconstruction.json`, expectedKind: 'reconstruction-manifest', targetRelativePath, stagedRelativePath: `assets/${targetRelativePath}`, localPath: relative(filePath), actual: { size: bytes.length, sha256, extension: '.json', magic: 'JSON', contentType: 'application/json' }, reconstructionOf: { sha256: original.sha256, size: original.size, name: original.name }, reconstructionManifest: true }];
}
function prepare(options) {
  fs.mkdirSync(STAGE, { recursive: true });
  if (!inside(fs.realpathSync(SOURCE), fs.realpathSync(STAGE))) throw Error('Staging root escapes source workspace.');
  if (fs.existsSync(path.join(STAGE, '.gitignore')) && fs.lstatSync(path.join(STAGE, '.gitignore')).isSymbolicLink()) throw Error('Staging ignore symlink rejected.');
  fs.writeFileSync(path.join(STAGE, '.gitignore'), '*\n!.gitignore\n');
  const known = parser.registryFrom(json(path.join(SOURCE, 'cherax-export-channels.json'))), skipped = [];
  const run = fs.existsSync(path.join(SOURCE, 'cherax-export-status.json')) ? json(path.join(SOURCE, 'cherax-export-status.json')) : null;
  if (run && !run.complete && !options.allowPartial) throw Error('Export run is incomplete. Wait for completion, or explicitly use --allow-partial for a bounded preparation.');
  let source;
  if (options.audit) {
    const audit = json(bounded(options.audit, SOURCE)); if (!Array.isArray(audit.items) || !Array.isArray(audit.exports)) throw Error('Reviewed export audit requires items[] and exports[].');
    const accepted = new Map();
    for (const record of audit.exports.filter(record => record.classification?.accepted)) {
      const file = bounded(record.path, EXPORTS), stat = fs.statSync(file);
      if (Date.now() - stat.mtimeMs < 30000 || stat.size !== record.bytes || hashFile(file).sha256 !== record.sha256) throw Error('Reviewed audit source changed or is still being written; regenerate audit after export completion.');
      if (!parser.classifyChannel({ guild: { id: record.guildId }, channel: record.channel }, known).accepted) throw Error('Reviewed audit source metadata no longer matches the approved channel registry.');
      accepted.set(record.path, record.sha256);
    }
    source = { items: audit.items.filter(item => accepted.has(item.provenance?.exportFile)).map(item => ({ ...item, provenance: { ...item.provenance, exportSha256: accepted.get(item.provenance.exportFile) } })), orphanImages: [] };
  }
  else source = readExports(bounded(options.input || EXPORTS, EXPORTS), known, skipped);
  if (!source.items.length && !source.orphanImages.length) throw Error('No approved stable resource candidates found; existing prepared outputs were retained.');
  const excludedHashes = new Map(json(path.join(SOURCE, 'cherax-lua-audit.json')).exclusions.map(entry => [entry.sha256, entry.reason]));
  const existing = existingResources(), assets = [], gaps = [...skipped], excluded = [], associations = [], items = [], imageOnly = [];
  const staged = new Map(), seenItems = new Map();
  const acquisition = (item, asset, image) => {
    image ||= IMAGE_EXT.has(asset.extension);
    const context = { resourceId: item.id, sourceId: `${item.sourceChannelId}-${item.sourceMessageId}`, category: item.category, name: item.name, sourceMenu: 'Cherax', sourceCatalog: 'authorized-discord-export', sourceURL: asset.sourceUrl || asset.sourceCanonicalUrl || null, originalName: asset.name, role: image ? 'thumbnail' : VIDEO_EXT.has(asset.extension) ? 'media' : 'payload', status: 'downloaded', attempts: 0, previewEligible: false, visualReview: image ? 'Original post attachment/embed image; visual content and resource association require review.' : null, luaPayload: Boolean(item.luaPayload || /\.luac?$/.test(asset.extension)), sourceGuildId: item.provenance?.guildId || null, sourceChannelId: item.sourceChannelId, sourceParentId: item.sourceParentId || null, sourceMessageId: item.sourceMessageId, sourceAttachmentId: asset.sourceAttachmentId || null, provenance: { ...item.provenance, approvedParentId: item.sourceParentId || null, sourceKind: asset.sourceKind, sourceLocalPath: asset.localPath, sourceChannel: item.sourceChannel, collection: item.collection } };
    if (!asset.localPath || !asset.localExists) { gaps.push({ resourceId: item.id, name: asset.name, reason: asset.issue || 'Attachment/post image bytes absent from local export.' }); return null; }
    const file = bounded(asset.localPath, EXPORTS), unnamedJson = ['vehicles', 'outfits'].includes(item.category) && /^json$/i.test(asset.name);
    const declared = path.extname(asset.name).toLowerCase();
    const unnamedJxr = !declared && !unnamedJson && head(file, 4).equals(Buffer.from([0x49, 0x49, 0xbc, 0x01]));
    const extension = unnamedJson ? '.json' : unnamedJxr ? '.jxr' : declared;
    if (!ALLOWED.has(extension)) { gaps.push({ resourceId: item.id, name: asset.name, localPath: relative(file), reason: 'Unsupported attachment retained only in the local export; no executable/active payload publication.' }); return null; }
    let actual;
    try { actual = hashFile(file); } catch (error) { gaps.push({ resourceId: item.id, name: asset.name, reason: error.message }); return null; }
    if (excludedHashes.has(actual.sha256)) { excluded.push({ resourceId: item.id, name: asset.name, sha256: actual.sha256, reason: excludedHashes.get(actual.sha256) }); return null; }
    const format = validateBytes(file, extension, item.category);
    if (!format.valid) { gaps.push({ resourceId: item.id, name: asset.name, sha256: actual.sha256, localPath: relative(file), reason: format.reason }); return null; }
    if (unnamedJson && !/^(?:cherax_(?:outfit|vehicle)_structure_recognized|legacy_outfit_json)$/.test(format.format.status)) { gaps.push({ resourceId: item.id, name: asset.name, sha256: actual.sha256, localPath: relative(file), reason: 'Extensionless JSON did not match a recognized vehicle or outfit structure.' }); return null; }
    const catalogOnly = format.catalogOnly || (unnamedJson && format.format.status === 'legacy_outfit_json');
    actual = { ...actual, extension: format.extension, magic: format.magic, contentType: format.contentType };
    const key = actual.sha256;
    if (staged.has(key)) { const prior = staged.get(key); for (const record of prior.records) { record.additionalSources ||= []; if (!record.additionalSources.some(entry => entry.resourceId === context.resourceId && entry.sourceAttachmentId === context.sourceAttachmentId)) record.additionalSources.push(context); } return { ...prior, duplicateBytes: true, catalogOnly }; }
    const base = { ...context, expectedKind: image ? 'image' : format.extension.slice(1), assetKey: `export:${context.sourceId}:${image ? 'image' : 'payload'}:${actual.sha256}` };
    const downloadName = unnamedJson || unnamedJxr ? asset.name + format.extension : format.format.declaredExtension
      ? asset.name.slice(0, -extension.length) + format.extension : asset.name;
    let records;
    if (actual.size >= LARGE_BYTES) {
      const full = path.join(STAGE, 'full', actual.sha256 + format.extension); fs.mkdirSync(path.dirname(full), { recursive: true });
      if (!inside(fs.realpathSync(STAGE), fs.realpathSync(path.dirname(full))) || (fs.existsSync(full) && fs.lstatSync(full).isSymbolicLink())) throw Error('Full-acquisition staging symlink/reparse rejected.');
      if (fs.existsSync(full)) { if (hashFile(full).sha256 !== actual.sha256) throw Error('Full acquisition checksum mismatch.'); } else fs.copyFileSync(file, full, fs.constants.COPYFILE_EXCL);
      if (hashFile(full).sha256 !== actual.sha256) throw Error('Full acquisition changed during copying.');
      records = splitFile(full, { name: downloadName, size: actual.size, sha256: actual.sha256, extension: format.extension }, { ...base, role: 'payload' });
    } else {
      const targetRelativePath = targetPath(actual.sha256, format.extension, IMAGE_EXT.has(extension)), local = safeStageFile(targetRelativePath);
      if (fs.existsSync(local)) { if (hashFile(local).sha256 !== actual.sha256) throw Error('Staged target checksum mismatch.'); } else fs.copyFileSync(file, local, fs.constants.COPYFILE_EXCL);
      if (hashFile(local).sha256 !== actual.sha256) throw Error('Staged copy checksum mismatch.');
      records = [{ ...base, targetRelativePath, stagedRelativePath: `assets/${targetRelativePath}`, localPath: relative(local), actual, format: format.format, downloadName }];
    }
    assets.push(...records); const result = { actual, format: format.format, records, catalogOnly }; staged.set(key, result); return result;
  };
  for (const sourceItem of [...source.items, ...source.orphanImages]) {
    const item = normalizeCollection({ ...sourceItem, sourceMenu: 'Cherax', supportedMenus: ['Cherax'], creator: 'Original developer unverified', creatorClaim: sourceItem.creator !== 'Original developer unverified' ? sourceItem.creator : null, creatorBasis: 'Source sender and any unverified author claim are kept separate.', runtimeVerified: false, files: [], downloadStatus: 'pending', status: 'pending', preview: null, previewVerified: false, images: [], assets: undefined, externalSourceLinks: undefined, reviewRequired: true });
    const exportFile = bounded(item.provenance?.exportFile, EXPORTS);
    const record = known.get(item.sourceParentId || item.sourceChannelId);
    if (!record || (item.provenance?.guildId && item.provenance.guildId !== record.guildId)) { gaps.push({ resourceId: item.id, reason: 'Candidate source ID/guild is outside the reviewed channel registry.' }); continue; }
    const acquisitions = (sourceItem.assets || []).map(asset => acquisition(item, sourceAsset(asset, exportFile), false)).filter(entry => entry && !entry.catalogOnly);
    const previews = (sourceItem.images || []).map(asset => acquisition(item, sourceAsset(asset, exportFile), true)).filter(Boolean);
    item.luaPayload = Boolean(item.luaPayload || (sourceItem.assets || []).some(asset => /\.luac?$/i.test(asset.name || '')));
    item.showSourceLink = !item.luaPayload;
    if (item.luaPayload) delete item.sourceUrl;
    item.sourceProvenance = [{ ...item.provenance, sourceChannelId: item.sourceChannelId, sourceParentId: item.sourceParentId || null, sourceMessageId: item.sourceMessageId, sourceCollection: sourceItem.collection, sourceAttachmentIds: (sourceItem.assets || []).map(asset => asset.sourceAttachmentId).filter(Boolean), sharedBy: item.sharedBy || null, timestamp: item.timestamp || null }];
    item.acquiredAssets = acquisitions.map(entry => ({ sha256: entry.actual.sha256, size: entry.actual.size, targets: entry.records.map(record => record.targetRelativePath) }));
    item.previewCandidates = previews.flatMap(entry => entry.records.filter(record => IMAGE_EXT.has(record.actual.extension)).map(record => ({ path: record.targetRelativePath, sha256: record.actual.sha256, originalPostImage: true, previewVerified: false })));
    const recognized = acquisitions.some(entry => /cherax_(?:vehicle|outfit)_structure_recognized/.test(entry.format.status));
    if (recognized && ['vehicles', 'outfits'].includes(item.category)) { item.supportedMenus = ['Scooby', 'Nenyoo', 'Cherax']; item.compatibilityLevel = 'source_importer_support'; item.compatibility = 'Recognized Cherax vehicle/outfit JSON structure matches the reviewed Scooby/Nenyoo importers. Runtime and complete field fidelity remain unverified.'; }
    else item.compatibilityLevel = item.category === 'dlc' ? 'conditional-original-host-package' : 'original-host-requirement-only';
    if (!item.luaPayload && acquisitions.length) { item.downloadStatus = 'available'; item.status = 'download'; item.files = acquisitions.flatMap(entry => entry.records.map(record => ({ path: record.targetRelativePath, name: record.downloadName || record.originalName, size: record.actual.size, sha256: record.actual.sha256, ...(record.reconstructionOf ? { reconstructionOf: record.reconstructionOf, partNumber: record.partNumber || null, reconstructionManifest: Boolean(record.reconstructionManifest) } : {}) }))); }
    const matches = new Map();
    for (const entry of acquisitions) { const exact = existing.bySourceHash.get(`${item.sourceChannelId}:${item.sourceMessageId}:${entry.actual.sha256}`); for (const match of exact || existing.byHash.get(entry.actual.sha256) || []) matches.set(match.id, { ...match, matchBasis: exact ? 'same-source-message-and-payload-sha256' : 'identical-source-or-payload-sha256', sha256: entry.actual.sha256 }); }
    if (matches.size) { associations.push({ sourceCandidateId: item.id, sourceChannelId: item.sourceChannelId, sourceParentId: item.sourceParentId || null, sourceMessageId: item.sourceMessageId, name: item.name, collection: item.collection, collectionStatus: item.collectionStatus, sourceCollection: item.sourceCollection, existingResources: [...matches.values()], acquiredAssets: item.acquiredAssets, previewCandidates: item.previewCandidates, sourceProvenance: item.sourceProvenance }); continue; }
    if (source.orphanImages.includes(sourceItem)) { imageOnly.push({ id: item.id, category: item.category, sourceChannelId: item.sourceChannelId, sourceMessageId: item.sourceMessageId, collection: item.collection, previewCandidates: item.previewCandidates, reason: 'Image-only post; resource identity/association requires review.' }); continue; }
    if ((sourceItem.assets || []).length && !acquisitions.length) continue;
    const dedupKey = acquisitions[0] ? `${item.category}:${acquisitions[0].actual.sha256}` : item.id;
    if (seenItems.has(dedupKey)) { const previous = seenItems.get(dedupKey); previous.sourceProvenance.push(...item.sourceProvenance); previous.previewCandidates.push(...item.previewCandidates.filter(candidate => !previous.previewCandidates.some(preview => preview.sha256 === candidate.sha256))); if (previous.name !== item.name) { previous.alternateSourceNames ||= []; previous.alternateSourceNames.push(item.name); } }
    else { seenItems.set(dedupKey, item); items.push(item); }
  }
  const summary = { sourceCandidates: source.items.length, newReviewableItems: items.length, existingResourceAssociations: associations.length, uniquePublicationAssets: assets.length, publicationBytes: assets.reduce((sum, asset) => sum + asset.actual.size, 0), splitParts: assets.filter(asset => asset.expectedKind === 'split-part').length, luaCardsPending: items.filter(item => item.luaPayload).length, imageOnlyPostsForReview: imageOnly.length, excludedKnownHashes: excluded.length, gaps: gaps.length };
  const policy = { noPayloadExecution: true, noArchiveExtraction: true, publicRawChats: false, avatarsIncluded: false, lua: 'Source attachments may be acquired; every Lua card stays pending/files[] and has no visible Discord link.', previews: 'Original message attachments/embed images only; signature checks do not establish visual content or association. Embed author icons, avatars, and thumbnails are not collected.', signatures: 'Container/header or text syntax only. Resource compatibility and payload safety are not established by signatures.', hashes: 'Target names use SHA-256 of actual saved bytes; publisher hashes are not reused.', largeFiles: `Full original retained locally. Files at least ${LARGE_BYTES} bytes publish ${PART_BYTES}-byte binary parts and a reconstruction/checksum manifest.` };
  const review = consumePreviewReview(normalizeReview({ schemaVersion: 1, menu: 'Cherax', sourceMenu: 'Cherax', preparedAt: new Date().toISOString(), purpose: 'Reviewable offline export candidates, exact-byte acquisition references and associations; final Cherax catalog is not modified.', completeness: run?.complete ? 'Selected exporter run completed; only accepted stable valid local envelopes were inspected. Missing/restricted/deleted history is not proven complete.' : 'Partial stable local export inspection while the selected exporter run remains incomplete.', acquisitionIndex: relative(path.join(STAGE, 'asset-index.json')), policy, summary, items, existingResourceAssociations: associations, imageOnlyPostsForReview: imageOnly, exclusions: excluded, gaps }, known), { assets });
  writeJson(path.join(STAGE, 'asset-index.json'), { schemaVersion: 1, sourceMenu: 'Cherax', preparedAt: new Date().toISOString(), stageDirectory: relative(STAGE), policy, summary, exportRun: { complete: Boolean(run?.complete), status: run?.status || 'unknown', expectedExports: run?.counts?.plannedChannels || null }, assets, gaps, exclusions: excluded });
  writeJson(OUTPUT, review);
  console.log(JSON.stringify({ output: relative(OUTPUT), assetIndex: relative(path.join(STAGE, 'asset-index.json')), ...summary }, null, 2));
}
function optionsFor(argv) { const options = {}; for (let i = 0; i < argv.length; i++) { const arg = argv[i]; if (arg === '--prepare') options.prepare = true; else if (arg === '--review-only') options.reviewOnly = true; else if (arg === '--allow-partial') options.allowPartial = true; else if (arg === '--self-test') options.selfTest = true; else if (arg === '--help' || arg === '-h') options.help = true; else if (arg === '--input' || arg === '--audit') { const value = argv[++i]; if (!value) throw Error(`Missing value for ${arg}.`); options[arg.slice(2)] = value; } else throw Error(`Unknown option: ${arg}`); } if (options.input && options.audit) throw Error('Choose --input or --audit.'); if (options.reviewOnly && (options.prepare || options.input || options.audit)) throw Error('--review-only operates on the existing review output only.'); return options; }
function selfTest() {
  fs.mkdirSync(STAGE, { recursive: true }); fs.writeFileSync(path.join(STAGE, '.gitignore'), '*\n!.gitignore\n');
  const dir = fs.mkdtempSync(path.join(STAGE, 'self-test-'));
  try {
    const file = path.join(dir, 'source.bin'), bytes = Buffer.from('Cherax split-byte verification'); fs.writeFileSync(file, bytes);
    const original = { name: 'source.bin', size: bytes.length, sha256: digest(bytes), extension: '.bin' }, records = splitFile(file, original, { assetKey: 'self-test', status: 'downloaded' }, 7);
    const parts = records.filter(record => record.expectedKind === 'split-part'); assert.equal(Buffer.concat(parts.map(record => fs.readFileSync(path.resolve(ROOT, record.localPath)))).equals(bytes), true); assert.equal(parts.every(record => record.actual.size <= 7), true); for (const record of records) { assert.equal(hashFile(path.resolve(ROOT, record.localPath)).sha256, record.actual.sha256); fs.unlinkSync(path.resolve(ROOT, record.localPath)); }
    const vehicle = path.join(dir, 'vehicle.json'); fs.writeFileSync(vehicle, JSON.stringify({ format: 'Cherax Entity', type: 1, model: 1, mods: {} })); assert.equal(validateBytes(vehicle, '.json', 'vehicles').format.status, 'cherax_vehicle_structure_recognized');
    fs.writeFileSync(vehicle, 'MZwrong format'); assert.equal(validateBytes(vehicle, '.json', 'vehicles').valid, false); assert.throws(() => bounded('../outside', EXPORTS, false));
    console.log('Offline preparation self-checks passed: byte splitting/reassembly, actual hashes, format recognition and path boundaries.');
  } finally { if (!inside(STAGE, path.resolve(dir)) || path.resolve(dir) === path.resolve(STAGE)) throw Error('Self-test cleanup escaped its staging directory.'); fs.rmSync(dir, { recursive: true, force: true }); }
}
function main(argv = process.argv.slice(2)) {
  const options = optionsFor(argv);
  if (options.help) { console.log('Offline Cherax export asset preparation\nDefault: directory/file metadata only, no content read and no writes.\n  node tools/menu-sources/prepare-cherax-export-assets.cjs\n  node tools/menu-sources/prepare-cherax-export-assets.cjs --prepare --input project/community-menu-sources/cherax-exports\n  node tools/menu-sources/prepare-cherax-export-assets.cjs --prepare --audit project/community-menu-sources/cherax-export-audit.json\n  node tools/menu-sources/prepare-cherax-export-assets.cjs --review-only\n  node tools/menu-sources/prepare-cherax-export-assets.cjs --self-test\n--review-only corrects the existing review output without changing acquisitions/index or reading chats. --allow-partial explicitly permits preparation of stable valid envelopes during an incomplete exporter run. No completeness claim is made. --prepare writes only cherax-export-downloads (ignored) and cherax-export-items.json (reviewable).'); return; }
  if (options.selfTest) return selfTest();
  if (options.reviewOnly) { const data = consumePreviewReview(normalizeReview(json(OUTPUT), parser.registryFrom(json(path.join(SOURCE, 'cherax-export-channels.json')))), json(path.join(STAGE, 'asset-index.json'))); data.reviewedAt = new Date().toISOString(); writeJson(OUTPUT, data); console.log(JSON.stringify({ output: relative(OUTPUT), acquisitionIndexUnchanged: true, ...data.summary }, null, 2)); return; }
  if (options.prepare) return prepare(options);
  const files = inventory(options.input ? bounded(options.input, EXPORTS) : EXPORTS); console.log(JSON.stringify({ mode: 'inventory-only', messageContentRead: false, outputWritten: false, files: files.length, bytes: files.reduce((sum, file) => sum + file.bytes, 0), sample: files.slice(0, 30) }, null, 2));
}
module.exports = { validateBytes, hashFile, splitFile, normalizeReview, applyPreviewReview, optionsFor, main };
if (require.main === module) { try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; } }
