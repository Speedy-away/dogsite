#!/usr/bin/env node
'use strict';

// Offline DiscordChatExporter evidence ingestion. No network, tokens,
// downloads, archive extraction, payload execution, or final manifest writes.
// Schema pattern follows the repository's cherax-import-exports.cjs reader.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const os = require('node:os');
const { readHtmlExport } = require('./redm-export-html.cjs');
const ROOT = path.resolve(__dirname, '../..');
const OUTPUT = path.join(ROOT, 'project/community-menu-sources/redm/evidence/export-observations');
const GUILD_ID = '1251145526792028272';
const SCHEMA = 'redm-offline-export-observation-v1';
const GROUPS = Object.freeze({
  'REDM FEATURES': ['ui-boost', 'colorsxml-presets', 'tracer-presets', 'bloodfx', 'weapon-soundpack', 'weaponskins', 'clean-scope', 'more-blood'],
  'REDM GRAPHIC PACKS': ['pvp-packs', 'rp-packs', 'gotham-city-pack', 'cinematic-pack', 'stranger-things-pvp-gpack', 'no-fog', 'sakura-pvp-gpack', 'brazil-pvp-gpack', 'neutral-grey-pvp-gpack', 'purple-aura-sky-pack', 'custom'],
  'REDM SETTINGS': ['no-wind-speed', 'no-vignette', 'no-grass', 'no-tracer', 'no-heathaze', 'no-bushes', 'no-cactus', 'no-explosion', 'weaponbinds', 'potato-graphics', 'stretched', 'lowsettings'],
});
const CHANNELS = new Set(Object.values(GROUPS).flat());
// Accessible FILES channels supply the original downloadable dependencies for
// these requested graphic-pack channels. They share canonical coverage names
// while retaining their exact exported channel IDs/names in each observation.
const CHANNEL_ALIASES = Object.freeze({
  'no-fog-file': 'no-fog', 'brazil-pack': 'brazil-pvp-gpack',
  'neutral-grey-pack': 'neutral-grey-pvp-gpack', 'custom-packs': 'custom',
});
const canonicalChannel = value => CHANNEL_ALIASES[value] || value;
// Observed through the RedM Hub channel-list accessibility UI. The remaining
// two requested settings channels are accepted by normalized exported name.
const CHANNEL_IDS = Object.freeze({
  '1301225316353577082': 'ui-boost', '1315313159656964200': 'colorsxml-presets',
  '1557028931578765432': 'tracer-presets', '1557029255874084864': 'bloodfx',
  '1557559982726062100': 'weapon-soundpack', '1558288432948580412': 'weaponskins',
  '1561855386892378112': 'clean-scope', '1326684182788837396': 'more-blood',
  '1380554874155962428': 'pvp-packs', '1544079665696608487': 'rp-packs',
  '1522224436709818388': 'gotham-city-pack', '1412078604019564704': 'cinematic-pack',
  '1456120398897872896': 'stranger-things-pvp-gpack', '1266491432882016308': 'no-fog',
  '1540732346310066226': 'sakura-pvp-gpack', '1380554539400429658': 'brazil-pvp-gpack',
  '1457527569808363541': 'neutral-grey-pvp-gpack', '1473510273653411993': 'purple-aura-sky-pack',
  '1267839915073474560': 'custom', '1364456423127519314': 'no-wind-speed',
  '1399597857857867959': 'no-vignette', '1251161159546044458': 'no-grass',
  '1557027938027835392': 'no-tracer', '1557028069737496667': 'no-heathaze',
  '1557028190801764363': 'no-bushes', '1557028363066015774': 'no-cactus',
  '1565781102616903750': 'no-explosion', '1278037406146232382': 'weaponbinds',
  '1362810152671248585': 'potato-graphics',
});
const EXCLUDED_IDS = new Set(['1326153842987110442', '1522215597549682759']);
const SETTINGS_GUIDES = new Set(['1274525250117308426', '1278038185590653062', '1362811947791417364', '1400255496291745874']);
const SMALL_CAPS = Object.freeze(Object.fromEntries(Array.from('ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘꞯʀꜱᴛᴜᴠᴡxʏᴢ').map((letter, index) => [letter, 'abcdefghijklmnopqrstuvwxyz'[index]])));
const SCRIPT_EXT = /\.(?:lua|luac|pluto|js|mjs|cjs|py|ps1|psm1|bat|cmd|vbs|vbe|wsf|exe|dll|asi|msi|com|scr)$/i;
const IMAGE_EXT = /\.(?:png|jpe?g|webp|gif|bmp|avif)$/i;
const VIDEO_EXT = /\.(?:mp4|webm|mov|mkv|m4v|avi)$/i;
const MEDIA_HOST = /(?:^|\.)(?:youtube\.com|youtu\.be|youtube-nocookie\.com|vimeo\.com|medal\.tv|streamable\.com|twitch\.tv)$/i;
const UNSAFE_WORDS = /(?:^|[^a-z0-9])(?:lua|luac|pluto|bypass|pm-?bypass|fast-?scope|faster-?scope|scripts?)(?:$|[^a-z0-9])/i;
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const relative = file => path.relative(ROOT, file).split(path.sep).join('/');
const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
const validId = value => typeof value === 'string' && /^\d{15,22}$/.test(value);
const text = value => typeof value === 'string' ? value : '';

function normalizeChannel(value) {
  return Array.from(text(value).normalize('NFKC').toLowerCase()).map(letter => SMALL_CAPS[letter] || letter).join('')
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}
function cleanName(value) {
  return text(value).replace(/[ _-]*\(?RedM[ _-]+Hub\)?[ _-]+by[ _-]+Dadash\b/gi, '').replace(/[\x00-\x1f\x7f]/g, ' ').trim();
}
function category(channel) {
  if (channel === 'weaponskins') return 'weapon-models';
  if (channel === 'weapon-soundpack') return 'sound-packs';
  if (channel === 'clean-scope') return 'scopes';
  if (['ui-boost', 'colorsxml-presets'].includes(channel)) return 'ui-presets';
  if (['tracer-presets', 'bloodfx', 'more-blood'].includes(channel)) return 'visual-effects';
  return GROUPS['REDM GRAPHIC PACKS'].includes(channel) ? 'graphics-packs' : 'settings';
}
function classifyChannel(document) {
  const channel = document.channel || {}, normalizedName = normalizeChannel(channel.name), name = canonicalChannel(normalizedName);
  if (EXCLUDED_IDS.has(String(channel.id)) || /(?:^|-)(?:pm-?bypass|fast-?scope|faster-?scope)(?:-|$)/.test(normalizedName)) return { accepted: false, reason: 'Explicitly excluded channel.' };
  if (String(document.guild?.id) !== GUILD_ID) return { accepted: false, reason: 'Export guild ID is not the observed RedM Hub server.' };
  if (!validId(channel.id)) return { accepted: false, reason: 'Missing or invalid exact channel ID.' };
  const known = CHANNEL_IDS[channel.id];
  if (known && CHANNELS.has(name) && name !== known) return { accepted: false, reason: 'Known channel ID conflicts with the exported allowlisted channel name.' };
  if (known) return { accepted: true, sourceChannel: known, category: category(known), basis: 'Observed exact RedM Hub channel ID.', nameMatches: name === known };
  if (CHANNELS.has(name)) return { accepted: true, sourceChannel: name, category: category(name), ...(normalizedName !== name ? { sourceChannelAlias: normalizedName } : {}), basis: 'Normalized exported channel name or authorized FILES dependency alias in the 31-channel allowlist and exact observed RedM Hub guild ID.' };
  return { accepted: false, reason: 'Channel is outside the 31-channel allowlist; thread-parent identity is not inferred.' };
}
function within(base, full) {
  const rel = path.relative(base, full);
  return rel === '' || (rel !== '..' && !rel.startsWith('..' + path.sep) && !path.isAbsolute(rel));
}
function assertNoSymlink(file) {
  for (let at = path.resolve(file); ; at = path.dirname(at)) {
    if (fs.existsSync(at) && fs.lstatSync(at).isSymbolicLink()) throw Error(`Symbolic link/reparse path is not accepted: ${at}`);
    if (path.dirname(at) === at) return;
  }
}
function writeJson(file, value, outputRoot = OUTPUT) {
  if (!within(outputRoot, file) || path.resolve(file) === path.resolve(outputRoot)) throw Error('Output escapes the importer evidence directory.');
  assertNoSymlink(file);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n', 'utf8');
}
function safeUrl(value) {
  if (typeof value !== 'string' || value.length > 8192) return null;
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) return null;
    const host = url.hostname.toLowerCase();
    if (host === 'localhost' || host.endsWith('.localhost') || host.includes(':') || /^\d+(?:\.\d+){3}$/.test(host) || host.endsWith('.local')) return null;
    return url.href;
  } catch { return null; }
}
function filenameOf(asset) {
  const explicit = asset.fileName || asset.name;
  if (typeof explicit === 'string' && explicit) return explicit;
  try { return decodeURIComponent(new URL(asset.canonicalUrl || asset.url).pathname.split('/').pop() || ''); }
  catch { return path.basename(text(asset.url).replace(/\\/g, '/')); }
}
function hashFile(file) {
  const hash = crypto.createHash('sha256'), fd = fs.openSync(file, 'r'), buffer = Buffer.alloc(1024 * 1024);
  const before = fs.fstatSync(fd);
  try {
    let length, read = 0;
    while ((length = fs.readSync(fd, buffer, 0, buffer.length, null)) > 0) { hash.update(buffer.subarray(0, length)); read += length; }
    const after = fs.fstatSync(fd);
    if (read !== before.size || after.size !== before.size || after.mtimeMs !== before.mtimeMs) throw Error('Local file changed during hashing; retry after the export finishes.');
  }
  finally { fs.closeSync(fd); }
  return hash.digest('hex');
}
function inspectLocalAsset(value, exportFile, inputRoot, maxAssetBytes) {
  if (typeof value !== 'string' || !value) return null;
  if (/^https?:\/\//i.test(value)) return null;
  if (/^[a-z][a-z0-9+.-]*:/i.test(value) || path.isAbsolute(value) || /^[\\/]/.test(value)) throw Error('Local media must use an export-relative path, not an absolute path or URI.');
  const local = path.resolve(path.dirname(exportFile), value.replace(/\\/g, '/'));
  if (!within(inputRoot, local)) throw Error('Export media path escapes the explicit input directory.');
  assertNoSymlink(local);
  if (!fs.existsSync(local)) return { path: relative(local), exists: false };
  if (!within(fs.realpathSync(inputRoot), fs.realpathSync(local))) throw Error('Export media real path escapes the explicit input directory.');
  const stat = fs.statSync(local);
  if (!stat.isFile()) throw Error('Export media path does not refer to a regular file.');
  return { path: relative(local), exists: true, size: stat.size, ...(stat.size <= maxAssetBytes ? { sha256: hashFile(local) } : { hashStatus: 'Not hashed because the configured asset size bound was exceeded.' }) };
}
function inspectAsset(asset, role, exportFile, options) {
  if (!asset || typeof asset !== 'object' || Array.isArray(asset)) return { role, rejected: true, reason: 'Malformed attachment/media object.' };
  const originalFileName = filenameOf(asset), normalized = normalizeChannel(originalFileName);
  if (SCRIPT_EXT.test(originalFileName) || UNSAFE_WORDS.test(normalized)) return { role: 'excluded-payload', rejected: true, originalFileName, reason: 'Script, executable, bypass, or explicitly excluded resource filename; no local payload read.' };
  const kind = IMAGE_EXT.test(originalFileName) ? 'source-image' : VIDEO_EXT.test(originalFileName) ? 'private-showcase-video' : role;
  const result = {
    role: kind, sourceAttachmentId: validId(asset.id) ? asset.id : null,
    originalFileName, suggestedDownloadName: cleanName(originalFileName),
    declaredBytes: Number.isSafeInteger(asset.fileSizeBytes) && asset.fileSizeBytes >= 0 ? asset.fileSizeBytes : null,
    sourceUrl: safeUrl(asset.url), canonicalSourceUrl: safeUrl(asset.canonicalUrl),
    local: null, downloadedByImporter: false, archiveContentsInspected: false,
  };
  try { result.local = inspectLocalAsset(asset.url, exportFile, options.inputRoot, options.maxAssetBytes); }
  catch (error) { result.localPathRejected = error.message; }
  result.declaredSizeMatches = result.local?.exists && result.declaredBytes !== null ? result.local.size === result.declaredBytes : null;
  if (result.declaredSizeMatches === false) result.localBytesStatus = 'Incomplete local export asset or declared size mismatch; do not stage until reviewed.';
  return result;
}
function urlsIn(content) {
  return [...new Set((text(content).match(/https:\/\/[^\s<>"`]+/g) || []).map(value => safeUrl(value.replace(/[),;.!]+$/, ''))).filter(Boolean))];
}
function isVideoUrl(value) {
  try { const url = new URL(value); return MEDIA_HOST.test(url.hostname) || VIDEO_EXT.test(url.pathname); }
  catch { return false; }
}
function messageScope(content) {
  return /```\s*(?:lua|luau|javascript|js|python|powershell|bat|cmd)\b/i.test(content) ||
    /(?:^|\n)\s*(?:#{1,6}\s*)?(?:[^\n:]{0,25}:\s*)?(?:lua\s+scripts?|pm[- ]bypass|fast(?:er)?[- ]scope)\b/i.test(content);
}
function resourceName(message, assets, channel) {
  const title = text(message.content).split(/\r?\n/).map(line => line.trim()).find(line =>
    (/^#{1,6}\s+\S/.test(line) || /^\*\*[^*\n]{3,160}\*\*:?$/.test(line)) &&
    !/(?:->|→|\\|\/)|\b(?:filepath|install(?:ation)?|tutorial|citizen|requirements?|credits?)\b/i.test(line) &&
    !/^(?:#{1,6}\s+|\*\*)?(?:important|note|warning|attention)[:\s*]*$/i.test(line));
  if (title) return { name: cleanName(title.replace(/^#{1,6}\s+/, '').replace(/^\*\*|\*\*:?$/g, '')).replace(/:\s*$/, ''), basis: 'Explicit heading in the same exported message.' };
  if (assets[0]?.originalFileName) return { name: cleanName(assets[0].originalFileName).replace(/\.[^.]+$/, ''), basis: 'Cleaned original attachment basename; multiple attachments remain grouped for dependency review.' };
  return { name: channel, basis: 'Channel label only; a specific resource title requires review.' };
}
function explicitVersion(content, assets) {
  const declared = text(content).match(/(?:^|\n)\s*(?:#{1,6}\s*)?(?:version|release|update)\s*[:=\-]?\s*v?(\d+\.\d+(?:\.\d+){0,2}(?:[-+][\w.-]+)?)/i);
  const fromFile = assets.map(asset => asset.originalFileName.match(/(?:^|[ _\-.(])v(\d+\.\d+(?:\.\d+){0,2})(?=$|[ _\-.)])/i)).find(Boolean);
  return declared ? { value: declared[1], basis: 'Explicit same-message version/release/update label.' } : fromFile ? { value: fromFile[1], basis: 'Explicit v-prefixed original attachment filename version.' } : { value: null, basis: 'No explicit resource version established.' };
}
function inspectMessage(message, document, classification, file, options) {
  if (!message || !validId(message.id) || typeof message.content !== 'string') return { rejected: true, reason: 'Malformed message ID or content.' };
  if (messageScope(message.content)) return { sourceMessageId: message.id, rejected: true, reason: 'Out-of-scope script/bypass/fast-scope message; content and local payloads were not imported.' };
  const attachments = (Array.isArray(message.attachments) ? message.attachments : []).map(asset => inspectAsset(asset, 'resource-file', file, options));
  const sourceImages = attachments.filter(asset => asset.role === 'source-image' && !asset.rejected);
  const privateShowcases = attachments.filter(asset => asset.role === 'private-showcase-video' && !asset.rejected);
  const embedEvidence = [];
  for (const embed of Array.isArray(message.embeds) ? message.embeds : []) {
    if (!embed || typeof embed !== 'object') continue;
    const url = safeUrl(embed.url), showcase = Boolean(url && isVideoUrl(url));
    const media = [];
    for (const [role, value] of [['embed-image', embed.image], ['embed-thumbnail', embed.thumbnail], ['private-showcase-video', embed.video], ...((Array.isArray(embed.images) ? embed.images : []).map(value => ['embed-image', value]))]) {
      if (!value) continue;
      const asset = inspectAsset(value, role, file, options);
      asset.previewVerified = false;
      asset.previewReviewReason = role === 'embed-thumbnail' || showcase ? 'Embed/video thumbnail is not an extracted frame and must not be used as one.' : 'Original media and its resource association require visual inspection.';
      media.push(asset);
      if (showcase || role === 'private-showcase-video') privateShowcases.push({ ...asset, role: 'private-showcase-source' });
      else if (role !== 'embed-thumbnail' && !asset.rejected) sourceImages.push(asset);
    }
    embedEvidence.push({ title: text(embed.title), description: text(embed.description), author: embed.author || null, url, media, privateEvidenceOnly: true });
  }
  const links = urlsIn(message.content);
  for (const url of links.filter(isVideoUrl)) privateShowcases.push({ role: 'private-showcase-link', sourceUrl: url, previewVerified: false });
  const externalDownloadCandidates = links.filter(url => !isVideoUrl(url) && !/(?:^|\.)discord(?:app)?\.(?:com|net)$/.test(new URL(url).hostname)).filter(url => {
    const decodedPath = (() => { try { return decodeURIComponent(new URL(url).pathname); } catch { return new URL(url).pathname; } })();
    return !SCRIPT_EXT.test(decodedPath) && !UNSAFE_WORDS.test(normalizeChannel(decodedPath));
  });
  const resourceAssets = attachments.filter(asset => asset.role === 'resource-file' && !asset.rejected);
  const record = {
    sourceMessageId: message.id, timestamp: message.timestamp || null, timestampEdited: message.timestampEdited || null,
    author: message.author || null, sourceContent: message.content, attachments, embedEvidence,
    sourceImages, privateShowcases, externalDownloadCandidates, sourceMessageUrl: `https://discord.com/channels/${GUILD_ID}/${document.channel.id}/${message.id}`,
  };
  if (!resourceAssets.length && !externalDownloadCandidates.length && !SETTINGS_GUIDES.has(message.id)) return { record, candidate: null };
  const named = resourceName(message, resourceAssets, classification.sourceChannel);
  if (UNSAFE_WORDS.test(normalizeChannel(named.name))) return { record, candidate: null, reason: 'Resource name is outside scope.' };
  const namedCredits = /\bby[ _-]+Dadash\b/i.test(resourceAssets.map(asset => asset.originalFileName).join('\n')) ? ['Dadash (original attachment filename credit)'] : [];
  return { record, candidate: {
    id: `redm-export-${document.channel.id}-${message.id}`, game: 'redm', category: classification.category,
    name: named.name, nameBasis: named.basis, sourceChannel: classification.sourceChannel, sourceChannelId: document.channel.id,
    sourceMessageId: message.id, sharedBy: text(message.author?.nickname || message.author?.name), credits: namedCredits,
    version: explicitVersion(message.content, resourceAssets), acquisitionStatus: resourceAssets.some(asset => asset.local?.exists && asset.declaredSizeMatches !== false) ? 'local-export-assets-awaiting-review-and-staging' : 'source-metadata-only-or-local-assets-incomplete',
    sourceAssets: resourceAssets, sourceImages, privateShowcases, externalDownloadCandidates,
    files: [], preview: null, previewVerified: false,
    requirements: [], requirementsReviewRequired: true,
    reviewRequired: true, dependenciesGroupedByMessage: true,
    limitations: ['Not a publishable catalog entry. Review source instructions, package contents, dependencies and versions before staging.', 'Source images require visual verification; video thumbnails are not frames.', 'Source uploader is not automatically the original author; preserve package credits and license notices.'],
  } };
}
function inspectExport(file, options) {
  const bytes = fs.readFileSync(file);
  const source = bytes.toString('utf8').replace(/^\uFEFF/, '');
  const document = /\.html$/i.test(file) ? readHtmlExport(source, file, GUILD_ID) : JSON.parse(source);
  if (!document || !document.guild || !document.channel || !Array.isArray(document.messages)) throw Error('Not a DiscordChatExporter JSON envelope with guild, channel and messages.');
  const classification = classifyChannel(document);
  const record = {
    schema: SCHEMA, privateEvidenceOnly: true, observedAt: new Date().toISOString(),
    exportFile: path.resolve(file), exportSha256: sha(bytes), exportBytes: bytes.length,
    exportedAt: document.exportedAt || null, dateRange: document.dateRange || null,
    guild: { id: document.guild.id, name: document.guild.name || null }, channel: document.channel,
    classification, declaredMessageCount: document.messageCount ?? null,
    exportedMessageRows: document.messages.length, completeHistoryInspected: false,
    coverageCaution: 'Only this saved export was inspected. Export date filters, exporter completion, deleted/absent messages and live channel history completeness were not verified.',
    messages: [], candidates: [], issues: [],
  };
  if (!classification.accepted) return record;
  if (document.messageCount !== document.messages.length) record.issues.push('Declared messageCount is absent or differs from the messages array length.');
  for (const message of document.messages) {
    const result = inspectMessage(message, document, classification, file, options);
    if (result.record) record.messages.push(result.record);
    else record.issues.push({ sourceMessageId: result.sourceMessageId || null, reason: result.reason });
    if (result.candidate) record.candidates.push(result.candidate);
    else if (result.reason && result.record) record.issues.push({ sourceMessageId: result.record.sourceMessageId, reason: result.reason });
  }
  return record;
}
function inventory(input) {
  assertNoSymlink(input);
  const rootStat = fs.statSync(input), files = [], issues = [];
  const inputRoot = rootStat.isDirectory() ? input : path.dirname(input);
  function walk(file, depth) {
    if (files.length >= 10000) throw Error('Input inventory exceeds 10,000 files. Choose a smaller explicit batch.');
    const stat = fs.lstatSync(file);
    if (stat.isSymbolicLink()) { issues.push({ path: file, reason: 'Symbolic link/reparse entry skipped.' }); return; }
    if (stat.isDirectory()) {
      if (depth > 8) { issues.push({ path: file, reason: 'Directory depth exceeds eight levels.' }); return; }
      for (const name of fs.readdirSync(file).sort()) walk(path.join(file, name), depth + 1);
    } else if (stat.isFile()) files.push({ file, bytes: stat.size });
  }
  walk(input, 0);
  return { inputRoot, files, issues };
}
function exportPathRejection(file, allowGeneric = false) {
  const normalized = normalizeChannel(file);
  if (/(?:^|-)(?:pm-?bypass|fast-?scope|faster-?scope)(?:-|$)/.test(normalized) || [...EXCLUDED_IDS].some(id => file.includes(id))) return 'Excluded channel filename/path; file content was not read.';
  if (path.dirname(file).split(/[\\/]/).some(segment => /\.(?:json|html)_files$/i.test(segment))) return 'Exported media sidecar, not a channel export; content was not read.';
  const basename = path.basename(file, path.extname(file));
  if (/(?:^|-)back-?up(?:-|$)/.test(normalizeChannel(basename))) return 'Mixed back-up channel is outside the requested resource scope; content was not read.';
  const bracketId = basename.match(/\[(\d{15,22})\]/)?.[1];
  if (bracketId && CHANNEL_IDS[bracketId]) return null;
  const name = basename.split(' - ').pop().replace(/\s*\[\d{15,22}\].*$/, '');
  if (CHANNELS.has(canonicalChannel(normalizeChannel(name)))) return null;
  if (!allowGeneric || bracketId) return 'Filename does not identify an allowlisted channel or dependency alias; content was not read. For a generically named export, provide that one file explicitly.';
  return null;
}
function aggregate(outputRoot = OUTPUT) {
  const observations = fs.readdirSync(outputRoot).filter(name => /^channel-\d+-[a-f0-9]{16}\.json$/.test(name)).map(name => {
    const full = path.join(outputRoot, name); assertNoSymlink(full); const data = readJson(full);
    return data.schema === SCHEMA ? { ...data, evidenceFile: relative(full) } : null;
  }).filter(Boolean);
  const candidates = new Map();
  for (const observation of observations.filter(item => item.classification.accepted)) {
    for (const item of observation.candidates) {
      const source = { evidenceFile: observation.evidenceFile, exportFile: observation.exportFile, exportSha256: observation.exportSha256, exportedAt: observation.exportedAt };
      const previous = candidates.get(item.id);
      if (!previous) candidates.set(item.id, { ...item, observations: [source] });
      else {
        const changed = sha(JSON.stringify(previous.sourceAssets)) !== sha(JSON.stringify(item.sourceAssets));
        const newer = (Date.parse(observation.exportedAt) || 0) > (Date.parse(previous.observations[0].exportedAt) || 0);
        const merged = newer ? [source, ...previous.observations] : [...previous.observations, source];
        candidates.set(item.id, { ...(newer ? item : previous), observations: merged, overlappingExportReviewRequired: true, differingAssetEvidence: Boolean(changed || previous.differingAssetEvidence) });
      }
    }
  }
  const coverage = Object.entries(GROUPS).flatMap(([group, names]) => names.map(name => {
    const records = observations.filter(item => item.classification.accepted && item.classification.sourceChannel === name);
    const messages = new Set(records.flatMap(item => item.messages.map(message => message.sourceMessageId)));
    return { sourceChannel: name, group, inspectedExports: records.length, uniqueInspectedMessages: messages.size,
      candidates: [...candidates.values()].filter(item => item.sourceChannel === name).length,
      completeHistoryInspected: false, status: records.length ? 'Saved export batch inspected; full channel history is unverified.' : 'No accepted export inspected.',
      exports: records.map(item => ({ evidenceFile: item.evidenceFile, exportFile: item.exportFile, sourceChannelId: item.channel.id, exportedChannelName: item.channel.name, sourceChannelAlias: item.classification.sourceChannelAlias || null, exportedAt: item.exportedAt, dateRange: item.dateRange, exportedMessageRows: item.exportedMessageRows, issues: item.issues.length })),
    };
  }));
  writeJson(path.join(outputRoot, 'source-candidates.json'), { schema: 'redm-offline-source-candidates-v1', privateEvidenceOnly: true, builtAt: new Date().toISOString(), filesStagedByImporter: 0, manifestEdited: false, items: [...candidates.values()] }, outputRoot);
  writeJson(path.join(outputRoot, 'coverage.json'), { schema: 'redm-offline-export-coverage-v1', builtAt: new Date().toISOString(), completeHistoryInspected: false, excludedChannels: ['pm-bypass', 'fast-scope', 'faster-scope'], coverage, rejectedExports: observations.filter(item => !item.classification.accepted).map(item => ({ evidenceFile: item.evidenceFile, channel: item.channel, reason: item.classification.reason })) }, outputRoot);
  return { observations: observations.length, acceptedExports: observations.filter(item => item.classification.accepted).length, candidates: candidates.size, channelsWithExports: coverage.filter(item => item.inspectedExports).length };
}
function parseArgs(argv) {
  const options = { maxJsonBytes: 128 * 1024 * 1024, maxAssetBytes: 2048 * 1024 * 1024 };
  for (let index = 0; index < argv.length; index++) {
    const key = argv[index];
    if (key === '--help' || key === '-h') options.help = true;
    else if (key === '--self-test') options.selfTest = true;
    else if (['--input', '--max-json-mb', '--max-asset-mb'].includes(key)) {
      const value = argv[++index]; if (!value) throw Error(`Missing value for ${key}.`);
      if (key === '--input') options.input = path.resolve(value);
      else { const mb = Number(value); if (!Number.isSafeInteger(mb) || mb < 1 || mb > 4096) throw Error('MiB bounds must be integers from 1 through 4096.'); options[key === '--max-json-mb' ? 'maxJsonBytes' : 'maxAssetBytes'] = mb * 1024 * 1024; }
    } else throw Error(`Unknown option: ${key}`);
  }
  return options;
}
function run(options, outputRoot = OUTPUT) {
  if (!options.input) throw Error('Provide --input <saved-export-or-batch-folder>.');
  if (within(options.input, outputRoot)) throw Error('Choose an input batch directory separate from the generated output evidence directory.');
  const listed = inventory(options.input), summary = { input: options.input, imported: [], skipped: [], inventoryIssues: listed.issues };
  options = { ...options, inputRoot: listed.inputRoot };
  for (const entry of listed.files.filter(item => /\.(json|html)$/i.test(item.file))) {
    const rejectedPath = exportPathRejection(entry.file, path.resolve(entry.file) === path.resolve(options.input));
    if (rejectedPath) { summary.skipped.push({ file: entry.file, reason: rejectedPath }); continue; }
    if (entry.bytes > options.maxJsonBytes) { summary.skipped.push({ file: entry.file, reason: 'Export exceeds the configured content size bound.', size: entry.bytes }); continue; }
    try {
      const observation = inspectExport(entry.file, options);
      const output = path.join(outputRoot, `channel-${String(observation.channel.id).replace(/\D/g, '').slice(0, 22) || '0'}-${observation.exportSha256.slice(0, 16)}.json`);
      writeJson(output, observation, outputRoot);
      summary.imported.push({ evidenceFile: relative(output), channel: observation.classification.sourceChannel || null, accepted: observation.classification.accepted, messageRows: observation.exportedMessageRows, candidates: observation.candidates.length });
    } catch (error) { summary.skipped.push({ file: entry.file, reason: error.message }); }
  }
  assertNoSymlink(outputRoot); fs.mkdirSync(outputRoot, { recursive: true });
  const totals = aggregate(outputRoot);
  writeJson(path.join(outputRoot, 'last-import.json'), { schema: 'redm-offline-import-run-v1', importedAt: new Date().toISOString(), ...summary, totals, networkUsed: false, manifestEdited: false }, outputRoot);
  return { output: relative(outputRoot), ...totals, importedThisRun: summary.imported.length, skippedThisRun: summary.skipped.length };
}
function selfTest() {
  assert.equal(normalizeChannel('🆓・ᴄᴏʟᴏʀꜱxᴍʟ-ᴘʀᴇꜱᴇᴛꜱ'), 'colorsxml-presets');
  assert.equal(normalizeChannel('❌・ɴᴏ-ʜᴇᴀᴛʜᴀᴢᴇ'), 'no-heathaze');
  assert.equal(CHANNELS.size, 31);
  assert.equal(classifyChannel({ guild: { id: GUILD_ID }, channel: { id: '1326153842987110442', name: 'clean-scope' } }).accepted, false);
  assert.equal(classifyChannel({ guild: { id: GUILD_ID }, channel: { id: '999999999999999999', name: '🤑・ᴘᴍ-ʙʏᴘᴀꜱꜱ' } }).accepted, false);
  assert.equal(safeUrl('https://127.0.0.1/private'), null);
  assert.equal(cleanName('Star Wars Weapon Skins (RedM Hub) by Dadash.rar'), 'Star Wars Weapon Skins.rar');
  assert.equal(exportPathRejection('RedM Hub - 🤑・ᴘᴍ-ʙʏᴘᴀꜱꜱ [1522215597549682759].json'), 'Excluded channel filename/path; file content was not read.');
  assert.equal(exportPathRejection('RedM Hub - FILES - fastscope-file [999999999999999999].json'), 'Excluded channel filename/path; file content was not read.');
  assert.equal(exportPathRejection('RedM Hub - FILES - no-fog-file [999999999999999999].json'), null);
  assert.equal(classifyChannel({ guild: { id: GUILD_ID }, channel: { id: '999999999999999999', name: '🤑・ɴᴏ-ꜰᴏɢ-ꜰɪʟᴇ' } }).sourceChannel, 'no-fog');
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'redm-export-import-test-'));
  const media = path.join(temp, 'preset.xml'), sample = path.join(temp, 'export.json');
  const output = path.join(temp, 'observations');
  try {
    fs.writeFileSync(media, '<preset author="Original author"/>');
    const document = { guild: { id: GUILD_ID, name: 'RedM Hub' }, channel: { id: '1315313159656964200', name: '🆓・ᴄᴏʟᴏʀꜱxᴍʟ-ᴘʀᴇꜱᴇᴛꜱ', type: 'GuildTextChat' }, exportedAt: '2026-11-11T01:00:00Z', dateRange: { after: null, before: null }, messageCount: 2, messages: [
      { id: '1450000000000000001', timestamp: '2026-11-10T00:00:00Z', content: '**Green Preset**\nVersion 1.2\nInstall in citizen/common/data/ui.\nhttps://youtu.be/example', author: { id: '1450000000000000002', name: 'Uploader' }, attachments: [{ id: '1450000000000000003', fileName: 'preset.xml', fileSizeBytes: 34, url: 'preset.xml' }, { fileName: 'excluded.lua', url: 'excluded.lua' }], embeds: [{ url: 'https://youtu.be/example', thumbnail: { url: 'https://i.ytimg.com/vi/example/hqdefault.jpg' } }] },
      { id: '1450000000000000004', timestamp: '2026-11-10T00:00:00Z', content: '```lua\nprint("outside scope")\n```', attachments: [] },
    ] };
    fs.writeFileSync(sample, JSON.stringify(document));
    const result = inspectExport(sample, { inputRoot: temp, maxAssetBytes: 1024 });
    assert.equal(result.classification.accepted, true); assert.equal(result.candidates.length, 1);
    assert.equal(result.candidates[0].sourceAssets.length, 1); assert.equal(result.candidates[0].sourceAssets[0].local.sha256, hashFile(media));
    assert.equal(result.candidates[0].previewVerified, false); assert.equal(result.candidates[0].sourceImages.length, 0);
    assert.equal(result.candidates[0].privateShowcases.length, 2); assert.deepEqual(result.candidates[0].externalDownloadCandidates, []);
    assert.deepEqual(result.candidates[0].files, []); assert.equal(result.messages.length, 1);
    assert.equal(result.completeHistoryInspected, false); assert.equal(result.issues.length, 1);
    assert.throws(() => inspectLocalAsset('../outside.xml', sample, temp, 1024));
    assert.throws(() => inspectLocalAsset('C:\\outside.xml', sample, temp, 1024));
    assert.equal(classifyChannel({ ...document, guild: { id: '999999999999999999' } }).accepted, false);
    const runOptions = { input: sample, maxJsonBytes: 1024 * 1024, maxAssetBytes: 1024 };
    const first = run(runOptions, output), repeated = run(runOptions, output);
    assert.equal(first.candidates, 1); assert.equal(repeated.observations, 1);
    const coverage = readJson(path.join(output, 'coverage.json'));
    assert.equal(coverage.coverage.length, 31); assert.equal(coverage.completeHistoryInspected, false);
    const candidates = readJson(path.join(output, 'source-candidates.json'));
    assert.equal(candidates.items.length, 1); assert.equal(candidates.manifestEdited, false);
    fs.writeFileSync(sample, JSON.stringify({ ...document, channel: { id: '1522215597549682759', name: 'pm-bypass' } }));
    assert.equal(run(runOptions, output).candidates, 1);
    const rejected = fs.readdirSync(output).filter(name => /^channel-1522215597549682759-/.test(name));
    assert.equal(rejected.length, 1); assert.deepEqual(readJson(path.join(output, rejected[0])).messages, []);
  } finally {
    // Only this unique temporary directory and its known synthetic output
    // folder are enumerated. Every target is containment-checked, and deletion
    // is nonrecursive; no user input path is deleted.
    assert.equal(within(os.tmpdir(), temp), true);
    if (fs.existsSync(output)) {
      for (const name of fs.readdirSync(output)) {
        const file = path.join(output, name);
        assert.equal(within(temp, file), true); assert.equal(fs.lstatSync(file).isFile(), true);
        fs.unlinkSync(file);
      }
      fs.rmdirSync(output);
    }
    for (const file of [sample, media]) if (within(temp, file) && fs.existsSync(file)) fs.unlinkSync(file);
    fs.rmdirSync(temp);
  }
  console.log('RedM importer self-checks passed: Unicode scope, exclusions, local hashes, path traversal, private videos, and no completeness/preview claims.');
}
function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.help) {
    console.log('Offline RedM DiscordChatExporter JSON importer\n\n  node tools/menu-sources/redm-import-exports.cjs --input <saved-export.json-or-batch-folder>\n  node tools/menu-sources/redm-import-exports.cjs --self-test\n\nOptional bounds: --max-json-mb 128 --max-asset-mb 2048 (maximum 4096 each).\n\nOutput: project/community-menu-sources/redm/evidence/export-observations/\nEach distinct export receives a private channel observation. source-candidates.json and coverage.json combine saved batches.\nKeep exported media inside the explicit input folder; single-file inputs use that file\'s parent as the media boundary.\nOnly the 31 allowlisted RedM Hub channels and explicit graphic dependency aliases are accepted.\nAliases: no-fog-file, brazil-pack, neutral-grey-pack, custom-packs.\npm-bypass, fast/faster-scope, fastscope-file, back-up, scripts and executable payloads are excluded.\nBatch filenames are filtered before content is read; provide a generically named JSON file individually.\nAttachments are inspected locally when present and are never downloaded, copied, executed or extracted.\nVideo links and embed thumbnails remain private evidence; previews are never marked verified by this importer.\nNo redm.json or shared UI files are edited. Full channel-history coverage is never inferred from an export.');
    return;
  }
  if (options.selfTest) return selfTest();
  console.log(JSON.stringify(run(options), null, 2));
}
module.exports = { normalizeChannel, classifyChannel, inspectLocalAsset, inspectAsset, inspectExport, aggregate, parseArgs, run, selfTest, main };
if (require.main === module) { try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; } }
