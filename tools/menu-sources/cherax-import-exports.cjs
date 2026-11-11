'use strict';

// Offline evidence parser. It never contacts Discord, downloads assets, executes
// scripts, extracts archives, or edits the final Cherax/site manifest.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const ROOT = path.resolve(__dirname, '../..');
const SOURCE_ROOT = path.join(ROOT, 'project/community-menu-sources');
const EXPORT_ROOT = path.join(SOURCE_ROOT, 'cherax-exports');
const OUTPUT = path.join(SOURCE_ROOT, 'cherax-export-audit.json');
const SCHEMA_SOURCE = 'https://github.com/Tyrrrz/DiscordChatExporter/blob/prime/DiscordChatExporter.Core/Exporting/JsonMessageWriter.cs';
const CATEGORY_NAMES = {
  'lua-scripts': 'lua',
  'outfit-shares': 'outfits',
  'dlc-shares': 'dlc',
  'theme-shares': 'themes',
  'json-vehicles': 'vehicles',
  'translation-shares': 'languages',
  'cherax-wallpaper': 'wallpapers',
};
// These four IDs have publisher-catalog provenance. The export's exact channel
// name or parent name must also match; dates never determine old/current status.
const DEFAULT_CHANNELS = [
  ['1240968464739602454', 'outfit-shares'],
  ['1240968657191047198', 'dlc-shares'],
  ['1007005077904568360', 'theme-shares'],
  ['1256941518036406273', 'json-vehicles'],
].map(([id, name]) => ({ id, name, collection: 'unknown', evidence: 'project/community-marketplace/modverse.json source_channel_id; current/old identity requires exact export metadata.' }));
const THREAD_TYPES = new Set(['GuildPublicThread', 'GuildPrivateThread', 'GuildNewsThread']);
const IMAGE_EXTENSIONS = new Set(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp']);
const ARCHIVE_EXTENSIONS = new Set(['.zip', '.rar', '.7z']);
const RELEVANT_EXTENSIONS = {
  lua: new Set(['.lua', ...ARCHIVE_EXTENSIONS]),
  outfits: new Set(['.json', '.xml', '.ini', ...ARCHIVE_EXTENSIONS]),
  vehicles: new Set(['.json', '.xml', '.ini', ...ARCHIVE_EXTENSIONS]),
  dlc: new Set(['.rpf', ...ARCHIVE_EXTENSIONS]),
  themes: new Set(['.json', '.ini', '.lua', ...ARCHIVE_EXTENSIONS]),
  languages: new Set(['.json', '.txt', '.ini', ...ARCHIVE_EXTENSIONS]),
  wallpapers: IMAGE_EXTENSIONS,
};

function relative(file) { return path.relative(ROOT, file).split(path.sep).join('/'); }
function within(base, target) {
  const rel = path.relative(base, target);
  return rel === '' || (!rel.startsWith('..' + path.sep) && rel !== '..' && !path.isAbsolute(rel));
}
function boundedPath(value, base = EXPORT_ROOT, mustExist = true) {
  const full = path.resolve(ROOT, value);
  if (!within(base, full)) throw Error(`Path must stay within ${relative(base)}.`);
  if (mustExist) {
    if (!fs.existsSync(full)) throw Error(`Path does not exist: ${relative(full)}`);
    if (!within(fs.realpathSync(base), fs.realpathSync(full))) throw Error('Symbolic link/reparse target escapes the allowed directory.');
  }
  return full;
}
function hash(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function clean(value, limit = 180) {
  return String(value || '').replace(/[\x00-\x1f\x7f]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, limit);
}
function id(value) { return typeof value === 'string' && /^\d{15,22}$/.test(value); }
function label(value) { return clean(value).toLowerCase(); }
function baseChannel(value) { return label(value).replace(/-old$/, ''); }
function safeUrl(value) {
  if (typeof value !== 'string' || value.length > 4096) return null;
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) return null;
    if (/^(?:localhost|127\.|10\.|192\.168\.|169\.254\.|172\.(?:1[6-9]|2\d|3[01])\.)/i.test(url.hostname)) return null;
    return url.href;
  } catch { return null; }
}
function discordUrl(value) { try { return /(?:^|\.)discord(?:app)?\.(?:com|net)$|(?:^|\.)discord\.gg$/i.test(new URL(value).hostname); } catch { return false; } }
function messageDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T/.test(value) || !/(?:Z|[+-]\d{2}:\d{2})$/.test(value)) return null;
  return Number.isFinite(Date.parse(value)) ? value.slice(0, 10) : null;
}
function registryFrom(data) {
  const records = Array.isArray(data) ? data : data.channels;
  if (!Array.isArray(records) || records.length > 100) throw Error('Channel registry requires a bounded channels array.');
  const known = new Map();
  for (const entry of records) {
    if (!id(entry.id) || !CATEGORY_NAMES[baseChannel(entry.name)] || !clean(entry.evidence)) throw Error('Registry entries need an exact channel ID, recognized share-channel name and evidence.');
    if (known.has(entry.id)) throw Error('Duplicate channel ID in registry.');
    if (entry.guildId && !id(entry.guildId)) throw Error('Invalid registry guild ID.');
    const collection = entry.collection || (label(entry.name).endsWith('-old') ? 'archival' : 'current');
    if (!['current', 'archival', 'unknown'].includes(collection)) throw Error('Unsupported collection flag.');
    if (entry.exportName && !clean(entry.exportName)) throw Error('exportName must be an exact nonempty exported display name.');
    known.set(entry.id, { ...entry, name: label(entry.name), collection });
  }
  return known;
}
function classifyChannel(document, known) {
  const channel = document.channel || {};
  const isThread = THREAD_TYPES.has(channel.type);
  const entry = known.get(isThread ? channel.categoryId : channel.id);
  if (!id(document.guild?.id) || !id(channel.id)) return { accepted: false, reason: 'Invalid guild or channel metadata.' };
  if (!entry) return { accepted: false, reason: 'Channel or thread parent ID is outside the approved share-channel registry.' };
  if (entry.guildId && document.guild.id !== entry.guildId) return { accepted: false, reason: 'Guild ID does not match the registry.' };
  const actual = label(isThread ? channel.category : channel.name);
  const allowed = entry.exportName ? [label(entry.exportName)] : entry.collection === 'unknown' ? [baseChannel(entry.name), baseChannel(entry.name) + '-old'] : [entry.name];
  if (!allowed.includes(actual)) return { accepted: false, reason: 'Exact exported share-channel/parent name does not match its approved ID.' };
  const canonicalName = entry.exportName ? entry.name : actual;
  const collection = entry.collection === 'unknown' ? (canonicalName.endsWith('-old') ? 'archival' : 'current') : entry.collection;
  return {
    accepted: true, category: CATEGORY_NAMES[baseChannel(canonicalName)], sourceChannel: canonicalName,
    collection, isThread, parentId: isThread ? channel.categoryId : null,
    evidence: entry.evidence, collectionBasis: 'Exact approved ID and export channel/parent name; no date-based classification.',
  };
}
function listFiles(input, maxFiles = 50000) {
  const files = [], issues = [];
  function walk(file, depth) {
    if (files.length >= maxFiles) throw Error(`File inventory exceeds the ${maxFiles} file bound.`);
    const info = fs.lstatSync(file);
    if (info.isSymbolicLink()) { issues.push({ path: relative(file), reason: 'Symbolic link skipped.' }); return; }
    if (info.isDirectory()) {
      if (depth > 8) { issues.push({ path: relative(file), reason: 'Directory depth exceeds 8; skipped.' }); return; }
      for (const item of fs.readdirSync(file).sort()) walk(path.join(file, item), depth + 1);
    } else if (info.isFile()) files.push({ absolutePath: file, path: relative(file), bytes: info.size, extension: path.extname(file).toLowerCase() });
  }
  walk(input, 0);
  return { files, issues };
}
function prefix(file, count = 4096) {
  const fd = fs.openSync(file, 'r');
  try { const bytes = Buffer.alloc(count); const length = fs.readSync(fd, bytes, 0, count, 0); return bytes.subarray(0, length); }
  finally { fs.closeSync(fd); }
}
function imageKind(bytes) {
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return 'png';
  if (bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255) return 'jpeg';
  if (/^GIF8[79]a/.test(bytes.subarray(0, 6).toString('ascii'))) return 'gif';
  if (bytes.subarray(0, 4).toString('ascii') === 'RIFF' && bytes.subarray(8, 12).toString('ascii') === 'WEBP') return 'webp';
  if (bytes.subarray(0, 2).toString('ascii') === 'BM') return 'bmp';
  return null;
}
function archiveKind(bytes) {
  if (bytes[0] === 80 && bytes[1] === 75 && [[3, 4], [5, 6], [7, 8]].some(pair => bytes[2] === pair[0] && bytes[3] === pair[1])) return 'zip';
  if (bytes.subarray(0, 6).equals(Buffer.from([82, 97, 114, 33, 26, 7]))) return 'rar';
  if (bytes.subarray(0, 6).equals(Buffer.from([55, 122, 188, 175, 39, 28]))) return '7z';
  return null;
}
function validateJson(value, category) {
  if (!value || Array.isArray(value) || typeof value !== 'object') return { status: 'unrecognized_json_structure', formatChecked: false };
  const keys = Object.keys(value).slice(0, 60);
  if (category === 'vehicles' && value.format === 'Cherax Entity' && value.type === 1 && Number.isInteger(value.model) && value.model !== 0 && value.mods && typeof value.mods === 'object' && !Array.isArray(value.mods)) {
    return { status: 'cherax_vehicle_structure_recognized', formatChecked: true, model: value.model, topLevelKeys: keys, limitations: 'Structural recognition only; field completeness, import behavior and in-game behavior require review.' };
  }
  if (category === 'outfits' && value.format === 'Cherax Entity' && value.type === 2 && Number.isInteger(value.model) && value.model !== 0 && value.components && !Array.isArray(value.components) && typeof value.components === 'object' && value.props && !Array.isArray(value.props) && typeof value.props === 'object') {
    return { status: 'cherax_outfit_structure_recognized', formatChecked: true, model: value.model, topLevelKeys: keys, limitations: 'Structural recognition only; component availability, target ped and host importer support require review.' };
  }
  return { status: 'valid_json_only', formatChecked: false, topLevelKeys: keys, limitations: 'Native theme/translation/other resource schema is not established by JSON syntax.' };
}
function localAsset(value, exportFile) {
  if (typeof value !== 'string' || !value || safeUrl(value)) return null;
  if (/^[a-z][a-z0-9+.-]*:/i.test(value) || path.isAbsolute(value)) throw Error('Absolute paths and non-HTTPS schemes are not accepted as export-relative assets.');
  const full = path.resolve(path.dirname(exportFile), value.replace(/\\/g, '/'));
  if (!within(EXPORT_ROOT, full)) throw Error('Attachment path escapes cherax-exports.');
  if (!fs.existsSync(full)) return { path: relative(full), exists: false };
  const resolved = fs.realpathSync(full);
  if (!within(fs.realpathSync(EXPORT_ROOT), resolved) || !fs.statSync(resolved).isFile()) throw Error('Attachment real path escapes the export boundary or is not a file.');
  return { path: relative(full), full, exists: true, bytes: fs.statSync(full).size };
}
function inspectAsset(asset, exportFile, category, maxAssetBytes) {
  const name = clean(asset.fileName || asset.name || path.posix.basename(String(asset.url || '').split('?')[0]), 240);
  const extension = path.extname(name).toLowerCase();
  const result = { name, extension, sourceAttachmentId: id(asset.id) ? asset.id : null, sourceUrl: safeUrl(asset.url), sourceCanonicalUrl: safeUrl(asset.canonicalUrl), declaredBytes: Number.isSafeInteger(asset.fileSizeBytes) ? asset.fileSizeBytes : null };
  try {
    const local = localAsset(asset.url, exportFile);
    result.localPath = local?.path || null;
    result.localExists = Boolean(local?.exists);
    if (!local?.exists) { result.format = { status: result.sourceUrl ? 'remote_metadata_only' : 'local_bytes_missing', formatChecked: false }; return result; }
    result.actualBytes = local.bytes;
    const start = prefix(local.full, 32);
    if (IMAGE_EXTENSIONS.has(extension)) {
      const kind = imageKind(start);
      result.format = { status: kind ? 'image_signature_recognized' : 'image_signature_mismatch', formatChecked: Boolean(kind), kind, limitations: 'Image signature only; image content has not been visually inspected.' };
    } else if (ARCHIVE_EXTENSIONS.has(extension)) {
      const kind = archiveKind(start);
      result.format = { status: kind ? 'archive_signature_recognized' : 'archive_signature_mismatch', formatChecked: false, kind, limitations: 'Archive container only; no extraction and no payload-format or compatibility claim.' };
    } else if (extension === '.rpf') {
      const kind = start.subarray(0, 4).toString('ascii');
      result.format = { status: ['RPF7', '7FPR'].includes(kind) ? 'rpf7_magic_recognized' : 'rpf7_magic_mismatch', formatChecked: false, limitations: 'Magic bytes only; encryption, archive structure and runtime compatibility require review.' };
    } else if (extension === '.lua') {
      result.format = { status: 'lua_source_not_executed', formatChecked: false, limitations: 'Lua remains a pending download and has no cross-menu compatibility claim.' };
    } else if (extension === '.json' && local.bytes <= maxAssetBytes) {
      try { result.format = validateJson(JSON.parse(fs.readFileSync(local.full, 'utf8').replace(/^\uFEFF/, '')), category); }
      catch { result.format = { status: 'invalid_json', formatChecked: false }; }
    } else result.format = { status: local.bytes > maxAssetBytes ? 'content_size_bound_exceeded' : 'format_not_checked', formatChecked: false };
    if (local.bytes <= maxAssetBytes) result.sha256 = hash(fs.readFileSync(local.full));
    else result.hashStatus = 'Not hashed: exceeds the configured local asset content bound.';
  } catch (error) { result.format = { status: 'asset_path_rejected', formatChecked: false }; result.issue = error.message; }
  return result;
}
function metadataText(content) { return String(content).replace(/```[\s\S]*?```/g, '').replace(/\*\*|__/g, ''); }
function versions(content, fileName = '') {
  const explicit = metadataText(content).match(/(?:^|\n)\s*(?:#{1,4}\s*)?(?:version|release|update)\s*[:=\-]?\s*v?(\d+\.\d+(?:\.\d+){0,2}(?:[-+][\w.-]+)?)/i);
  const fromName = String(fileName).match(/(?:^|[ _\-.(])v(\d+\.\d+(?:\.\d+){0,2}(?:[-+][\w.-]+)?)(?=$|[ _\-.)])/i);
  return explicit ? { version: explicit[1], basis: 'Explicit version/release/update label in the same source message.' } : fromName ? { version: fromName[1], basis: 'Version explicitly encoded with v prefix in the attachment filename.' } : { version: null, basis: 'No unmistakable package version.' };
}
function changelog(content, timestamp, version) {
  content = metadataText(content);
  const date = messageDate(timestamp);
  if (!date || !version || !/(?:^|\n)\s*(?:#{1,4}\s*)?(?:changelog|change\s*log|changes)\s*[:\-]?\s*(?:\n|$)/i.test(content)) return [];
  const changes = [];
  for (const line of String(content).split(/\r?\n/)) {
    const match = line.match(/^\s*[-*•]\s+(added|fixed|removed|improved|updated)\s+(.{3,220})$/i);
    if (!match || /https?:\/\/|<@|```/.test(match[2])) continue;
    const wording = { added: 'Introduced', fixed: 'Corrected', removed: 'Eliminated', improved: 'Refined', updated: 'Revised' }[match[1].toLowerCase()];
    changes.push(`${wording} ${clean(match[2], 220).replace(/[.!]+$/, '')}.`);
    if (changes.length === 16) break;
  }
  return changes.length ? [{ version, date, changes, evidenceBasis: 'Conservative action paraphrases from the same explicitly versioned source-message changelog; date is its exported timestamp.' }] : [];
}
function resourceName(message, asset, channel, classification) {
  const declared = String(message.content || '').match(/(?:^|\n)\s*(?:name|title|script name|theme name|outfit name|vehicle name)\s*:\s*([^\n]{2,160})/i);
  if (declared && !/https?:\/\/|<@/.test(declared[1])) return { value: clean(declared[1]), basis: 'Explicit resource name/title in source message.' };
  if (asset?.name) return { value: asset.name.replace(/\.(?:lua|json|xml|ini|rpf|zip|rar|7z|png|jpe?g|gif|webp|bmp)$/i, ''), basis: 'Original attachment basename; no inferred model or package title.' };
  if (classification.isThread) return { value: clean(channel.name), basis: 'Exported source forum/thread title; a later reply may still refer to a different resource.' };
  return null;
}
function linksIn(content) {
  return [...new Set((String(content).match(/https:\/\/[^\s<>"`]+/g) || []).map(value => safeUrl(value.replace(/[),;.!]+$/, ''))).filter(Boolean))].slice(0, 24);
}
function candidate(document, classification, message, asset, previews, externalLinks, exportPath) {
  const name = resourceName(message, asset, document.channel, classification);
  if (!name?.value) return null;
  const sourceVersion = versions(message.content, asset?.name);
  const isLua = classification.category === 'lua' || asset?.extension === '.lua';
  const category = classification.category;
  const author = message.author || {};
  const claimedAuthor = String(message.content || '').match(/(?:^|\n)\s*(?:author|creator|created by)\s*:\s*([^\n]{2,100})/i);
  const date = messageDate(message.timestamp);
  return {
    id: `cherax-export-${document.channel.id}-${message.id}-${asset ? asset.sourceAttachmentId || hash(asset.name).slice(0, 10) : 'linked'}`,
    game: 'gta5', sourceMenu: 'cherax', supportedMenus: ['cherax'], category,
    name: name.value, nameBasis: name.basis, collection: classification.collection,
    sourceChannel: classification.sourceChannel, sourceChannelId: document.channel.id,
    sourceParentId: classification.parentId, sourceMessageId: message.id,
    creator: claimedAuthor ? clean(claimedAuthor[1], 100) : 'Original developer unverified',
    creatorBasis: claimedAuthor ? 'Author claim in source-message text; identity and authorship not independently verified.' : 'Source sender is credited separately from original creator.',
    sharedBy: clean(author.nickname || author.name || 'Unknown uploader', 100),
    sourceAuthorId: id(author.id) ? author.id : null,
    date, timestamp: message.timestamp, timestampEdited: message.timestampEdited || null,
    version: sourceVersion.version, versionBasis: sourceVersion.basis,
    changelog: changelog(message.content || '', message.timestamp, sourceVersion.version),
    changelogReviewRequired: true,
    downloadStatus: 'pending', files: [], luaPayload: isLua,
    preview: previews.find(preview => preview.localExists && preview.format.formatChecked)?.localPath || previews.find(preview => preview.sourceUrl)?.sourceUrl || null,
    previewVerified: false,
    previewBasis: previews.length ? 'Image associated with the same source message. Signature checks do not verify visual content or that it depicts this resource.' : 'No source preview identified.',
    images: previews,
    assets: asset ? [asset] : [],
    externalSourceLinks: externalLinks.filter(url => !isLua || !discordUrl(url)),
    showSourceLink: !isLua,
    ...(isLua ? {} : { sourceUrl: `https://discord.com/channels/${document.guild.id}/${document.channel.id}/${message.id}` }),
    provenance: { exportFile: relative(exportPath), guildId: document.guild.id, channelName: clean(document.channel.name), channelType: document.channel.type, approvedChannelBasis: classification.evidence, collectionBasis: classification.collectionBasis, ...(document.desktopDump ? { desktopDump: document.desktopDump } : {}) },
    tags: ['Cherax', classification.sourceChannel, classification.collection, asset?.extension?.slice(1)].filter(Boolean),
    compatibility: category === 'lua' ? 'Requires the original Cherax Lua API; Scooby/Nenyoo compatibility is unverified.' : ['vehicles', 'outfits'].includes(category) ? 'Original Cherax data format. A recognized local structure is a candidate for matching Scooby/Nenyoo importers; this audit does not establish runtime compatibility.' : 'Original-menu resource. Host, format and game-edition compatibility require review.',
    acquisitionStatus: asset?.localExists ? 'local_attachment_available_for_review' : 'source_metadata_only',
    reviewRequired: true,
  };
}

function inspectExport(file, options, known) {
  const data = JSON.parse(fs.readFileSync(file.absolutePath, 'utf8').replace(/^\uFEFF/, ''));
  if (!data.guild || !data.channel || !Array.isArray(data.messages) || !data.dateRange || !data.exportedAt) throw Error('Not a complete DiscordChatExporter JSON envelope.');
  const classification = classifyChannel(data, known);
  const channel = data.channel;
  const record = { path: file.path, bytes: file.bytes, sha256: hash(fs.readFileSync(file.absolutePath)), guildId: data.guild.id, channel: { id: channel.id, name: channel.name, type: channel.type, categoryId: channel.categoryId ?? null, category: channel.category ?? null }, exportedAt: data.exportedAt, dateRange: data.dateRange, declaredMessageCount: data.messageCount ?? null, actualMessageCount: data.messages.length, classification, candidates: 0, sourceMessagesWithResourceEvidence: 0, sourceMessagesWithVersionEvidence: 0, issues: [] };
  if (!classification.accepted) return { record, items: [], reviewMessages: [] };
  if (data.messageCount !== data.messages.length) record.issues.push('Declared messageCount is absent or differs from the exported messages array.');
  const items = [], reviewMessages = [];
  for (const message of data.messages) {
    if (!id(message.id) || typeof message.content !== 'string' || !messageDate(message.timestamp)) { record.issues.push('Skipped malformed source message (invalid ID, content or timestamp).'); continue; }
    const attachments = (Array.isArray(message.attachments) ? message.attachments : []).map(asset => inspectAsset(asset, file.absolutePath, classification.category, options.maxAssetBytes));
    const previews = attachments.filter(asset => IMAGE_EXTENSIONS.has(asset.extension));
    for (const embed of (Array.isArray(message.embeds) ? message.embeds : [])) {
      const images = [embed.image, embed.thumbnail, ...(Array.isArray(embed.images) ? embed.images : [])].filter(Boolean);
      for (const image of images) {
        const url = image.url || image.canonicalUrl;
        if (!url) continue;
        const asset = inspectAsset({ ...image, url, fileName: path.posix.basename(String(url).split('?')[0]) }, file.absolutePath, classification.category, options.maxAssetBytes);
        if (IMAGE_EXTENSIONS.has(asset.extension) || asset.sourceCanonicalUrl) previews.push(asset);
      }
    }
    const resources = attachments.filter(asset => RELEVANT_EXTENSIONS[classification.category]?.has(asset.extension));
    const links = linksIn(message.content).filter(url => !discordUrl(url));
    const relevantLinks = links.filter(url => /\.(?:lua|json|xml|ini|rpf|zip|rar|7z|png|jpe?g|gif|webp)(?:[?#]|$)/i.test(url) || /(?:^|\.)github\.com$/.test(new URL(url).hostname));
    let added = false;
    for (const asset of resources) {
      const item = candidate(data, classification, message, asset, previews, links, file.absolutePath);
      if (item) { items.push(item); added = true; }
    }
    if (!resources.length && relevantLinks.length && (classification.isThread || /(?:^|\n)\s*(?:name|title|script name|theme name)\s*:/i.test(message.content))) {
      const item = candidate(data, classification, message, null, previews, relevantLinks, file.absolutePath);
      if (item) { items.push(item); added = true; }
    }
    if (added) record.sourceMessagesWithResourceEvidence++;
    const version = versions(message.content);
    if (version.version) {
      record.sourceMessagesWithVersionEvidence++;
      if (!added) reviewMessages.push({ exportFile: file.path, sourceChannelId: data.channel.id, sourceMessageId: message.id, sharedBy: clean(message.author?.nickname || message.author?.name, 100), timestamp: message.timestamp, version: version.version, changelog: changelog(message.content, message.timestamp, version.version), reviewReason: 'Version/update message without a distinct attachment candidate. Associate with the correct resource manually; do not infer identity from nearby messages.' });
    }
  }
  record.candidates = items.length;
  return { record, items, reviewMessages };
}

function selfTest() {
  const known = registryFrom(DEFAULT_CHANNELS);
  const doc = { guild: { id: '123456789012345678' }, channel: { id: '234567890123456789', type: 'GuildPublicThread', categoryId: '1007005077904568360', category: 'theme-shares-old', name: 'Actual thread title' } };
  assert.equal(classifyChannel(doc, known).collection, 'archival');
  assert.equal(classifyChannel({ ...doc, channel: { ...doc.channel, category: 'off-topic' } }, known).accepted, false);
  assert.equal(classifyChannel({ ...doc, channel: { ...doc.channel, categoryId: '999999999999999999' } }, known).accepted, false);
  assert.equal(validateJson({ format: 'Cherax Entity', type: 1, model: 1, mods: {} }, 'vehicles').formatChecked, true);
  assert.equal(validateJson({ format: 'Cherax Entity', type: 2, model: 1, components: {}, props: {} }, 'outfits').formatChecked, true);
  assert.equal(validateJson({ arbitrary: true }, 'vehicles').formatChecked, false);
  assert.equal(validateJson({ strings: { A: 'a' } }, 'languages').formatChecked, false);
  assert.equal(safeUrl('https://127.0.0.1/private'), null);
  assert.throws(() => localAsset('../../../../outside.lua', path.join(EXPORT_ROOT, 'sample.json')));
  assert.equal(changelog('Version 1.2\nChangelog\n- Fixed a crash', '2026-11-11T00:00:00+00:00', '1.2')[0].changes[0], 'Corrected a crash.');
  assert.deepEqual(changelog('Version 1.2\n- Fixed a crash', '2026-11-11T00:00:00+00:00', '1.2'), []);
  const lua = candidate(doc, { category: 'lua', collection: 'current', sourceChannel: 'lua-scripts', isThread: true }, { id: '345678901234567890', content: 'Version 1.2', timestamp: '2026-11-11T00:00:00+00:00', author: { name: 'Uploader' } }, { name: 'NamedScript_v1.2.lua', extension: '.lua' }, [], ['https://discord.com/channels/123/456', 'https://github.com/author/script'], path.join(EXPORT_ROOT, 'sample.json'));
  assert.equal(lua.downloadStatus, 'pending'); assert.deepEqual(lua.files, []); assert.equal(lua.showSourceLink, false); assert.equal(lua.sourceUrl, undefined); assert.equal(lua.externalSourceLinks.length, 1);
  console.log('Cherax export parser self-checks passed (synthetic in-memory cases only).');
}
function argumentsFor(argv) {
  const options = { input: null, registry: null, maxJsonBytes: 128 * 1024 * 1024, maxAssetBytes: 16 * 1024 * 1024 };
  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--self-test') options.selfTest = true;
    else if (['--input', '--channels', '--channel-map', '--max-json-mb', '--max-asset-mb'].includes(arg)) {
      const value = argv[++index]; if (!value) throw Error(`Missing value for ${arg}.`);
      if (arg === '--input') options.input = value;
      else if (arg === '--channels' || arg === '--channel-map') options.registry = value;
      else { const mb = Number(value); if (!Number.isInteger(mb) || mb < 1 || mb > 512) throw Error('Content bounds must be integer MiB values between 1 and 512.'); options[arg === '--max-json-mb' ? 'maxJsonBytes' : 'maxAssetBytes'] = mb * 1024 * 1024; }
    } else throw Error(`Unknown option: ${arg}`);
  }
  return options;
}
function main(argv = process.argv.slice(2)) {
  const options = argumentsFor(argv);
  if (options.help) {
    console.log('Offline Cherax DiscordChatExporter evidence parser\n\nDefault: file inventory only; no message/asset content is read and no files are written.\n\n  node tools/menu-sources/cherax-import-exports.cjs\n  node tools/menu-sources/cherax-import-exports.cjs --input project/community-menu-sources/cherax-exports\n  node tools/menu-sources/cherax-import-exports.cjs --input <path-inside-cherax-exports> --channel-map <registry-json-inside-community-menu-sources>\n  node tools/menu-sources/cherax-import-exports.cjs --self-test\n\nOptional content bounds: --max-json-mb 128 --max-asset-mb 16 (maximum 512 each).\nChannel registry format: {"channels":[{"id":"exact-channel-id","name":"lua-scripts","exportName":"optional exact display name including emojis","collection":"current","guildId":"optional-exact-guild-id","evidence":"visible/export evidence reference"}]}. --channels is an alias for --channel-map.\nUnknown channel IDs and their metadata are reported and excluded from candidates until reviewed. Explicit --input writes cherax-export-audit.json; source exports and final manifests are never modified.');
    return;
  }
  if (options.selfTest) { selfTest(); return; }
  if (!fs.existsSync(EXPORT_ROOT)) {
    if (options.input) throw Error('cherax-exports does not exist yet. Export the selected share channels there before inspection.');
    console.log(JSON.stringify({ mode: 'inventory-only', root: relative(EXPORT_ROOT), exists: false, files: 0, messageContentRead: false, outputWritten: false })); return;
  }
  const input = options.input ? boundedPath(options.input) : EXPORT_ROOT;
  const inventory = listFiles(input);
  if (!options.input) {
    console.log(JSON.stringify({ mode: 'inventory-only', root: relative(EXPORT_ROOT), files: inventory.files.length, bytes: inventory.files.reduce((sum, file) => sum + file.bytes, 0), jsonFiles: inventory.files.filter(file => file.extension === '.json').length, sample: inventory.files.slice(0, 60).map(({ path: file, bytes }) => ({ path: file, bytes })), issues: inventory.issues, messageContentRead: false, outputWritten: false }, null, 2)); return;
  }
  const registry = options.registry ? JSON.parse(fs.readFileSync(boundedPath(options.registry, SOURCE_ROOT), 'utf8')) : DEFAULT_CHANNELS;
  const known = registryFrom(registry);
  const audit = { schemaVersion: 1, auditedAt: new Date().toISOString(), menu: 'cherax', mode: 'offline-export-evidence-review', schemaSource: SCHEMA_SOURCE, inputPath: relative(input), sourceBounds: { root: relative(EXPORT_ROOT), maxJsonBytes: options.maxJsonBytes, maxAssetBytes: options.maxAssetBytes }, channelRegistry: [...known.values()], summary: {}, inventoryIssues: inventory.issues, exports: [], skipped: [], items: [], versionMessagesForReview: [], gaps: ['This audit covers only the local export files inspected, not every server share or absent/deleted/restricted post.', 'Export completion and all-threads/all-time selection must be verified against the export UI separately.', 'Source senders are not automatically original developers. Package and preview redistribution permissions are not established by an export.', 'All Lua downloads remain pending with empty files. Original-menu API requirements remain separate from vehicle/outfit data-format candidates.', 'Assets are not downloaded, executed or extracted; remote URLs may expire and require fresh acquisition.', 'Generated changelog paraphrases and source image associations require human review before catalog integration.', 'Vehicle/outfit structural recognition is not a live host/game compatibility test. Themes, translations and DLCs receive no blanket cross-menu compatibility label.'] };
  const seen = new Map();
  for (const file of inventory.files.filter(file => file.extension === '.json')) {
    const beginning = prefix(file.absolutePath).toString('utf8').replace(/^\uFEFF/, '');
    if (!/^\s*\{\s*"guild"\s*:/.test(beginning)) continue; // Asset JSONs are not channel exports.
    if (file.bytes > options.maxJsonBytes) { audit.skipped.push({ path: file.path, reason: 'Export JSON exceeds the explicit content bound.', bytes: file.bytes }); continue; }
    try {
      const result = inspectExport(file, options, known);
      audit.exports.push(result.record);
      for (const item of result.items) {
        const duplicate = seen.get(item.id);
        if (duplicate) { duplicate.additionalExportFiles ||= []; duplicate.additionalExportFiles.push(file.path); }
        else { seen.set(item.id, item); audit.items.push(item); }
      }
      audit.versionMessagesForReview.push(...result.reviewMessages);
    } catch (error) { audit.skipped.push({ path: file.path, reason: `Export parse/validation failed: ${error.message}` }); }
  }
  const countBy = (items, key) => items.reduce((result, item) => (result[item[key]] = (result[item[key]] || 0) + 1, result), {});
  const discovered = new Map();
  for (const source of audit.exports) {
    const key = `${source.guildId}/${source.channel.id}`;
    const record = discovered.get(key) || { guildId: source.guildId, ...source.channel, accepted: source.classification.accepted, exportFiles: 0, sourceMessages: 0 };
    record.exportFiles++; record.sourceMessages += source.actualMessageCount; discovered.set(key, record);
  }
  audit.discoveredChannels = [...discovered.values()];
  audit.shareChannelCoverage = [...Object.keys(CATEGORY_NAMES), ...Object.keys(CATEGORY_NAMES).filter(name => name !== 'lua-scripts').map(name => name + '-old')].map(name => {
    const exports = audit.exports.filter(source => source.classification.accepted && source.classification.sourceChannel === name);
    return { name, inspectedExportFiles: exports.length, sourceMessageRows: exports.reduce((sum, source) => sum + source.actualMessageCount, 0), candidates: audit.items.filter(item => item.sourceChannel === name).length, status: exports.length ? 'Only the listed export files inspected; completeness against Discord not established.' : 'No approved export inspected.' };
  });
  audit.summary = { inventoriedFiles: inventory.files.length, inspectedExportFiles: audit.exports.length, acceptedExportFiles: audit.exports.filter(item => item.classification.accepted).length, rejectedChannelExports: audit.exports.filter(item => !item.classification.accepted).length, skippedExportFiles: audit.skipped.length, sourceMessagesInAcceptedExports: audit.exports.filter(item => item.classification.accepted).reduce((sum, item) => sum + item.actualMessageCount, 0), uniqueResourceCandidates: audit.items.length, candidatesByCategory: countBy(audit.items, 'category'), candidatesByCollection: countBy(audit.items, 'collection'), localAssetsAvailable: audit.items.flatMap(item => item.assets).filter(asset => asset.localExists).length, recognizedVehicleOutfitStructures: audit.items.flatMap(item => item.assets).filter(asset => /cherax_(?:vehicle|outfit)_structure_recognized/.test(asset.format.status)).length, luaPendingCandidates: audit.items.filter(item => item.category === 'lua').length, luaPayloadPendingCandidates: audit.items.filter(item => item.luaPayload).length, versionMessagesForReview: audit.versionMessagesForReview.length };
  fs.writeFileSync(OUTPUT, JSON.stringify(audit, null, 2) + '\n');
  console.log(JSON.stringify({ output: relative(OUTPUT), ...audit.summary }, null, 2));
}

module.exports = { classifyChannel, registryFrom, validateJson, candidate, changelog, versions, argumentsFor, main };
if (require.main === module) { try { main(); } catch (error) { console.error(error.message); process.exitCode = 1; } }
