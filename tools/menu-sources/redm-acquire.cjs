#!/usr/bin/env node
'use strict';

// Offline acquisition only: copies selected local files without executing them.
// Writes stay under project/community-menu-sources/redm; never edits the manifest.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const ROOT = path.resolve(__dirname, '../..');
const ASSETS = path.join(ROOT, 'project/community-menu-sources/redm');
const MANIFEST = path.join(ROOT, 'project/community-menu-sources/redm.json');
const GROUPS = Object.freeze({
  'REDM FEATURES': ['ui-boost', 'colorsxml-presets', 'tracer-presets', 'bloodfx', 'weapon-soundpack', 'weaponskins', 'clean-scope', 'more-blood'],
  'REDM GRAPHIC PACKS': ['pvp-packs', 'rp-packs', 'gotham-city-pack', 'cinematic-pack', 'stranger-things-pvp-gpack', 'no-fog', 'sakura-pvp-gpack', 'brazil-pvp-gpack', 'neutral-grey-pvp-gpack', 'purple-aura-sky-pack', 'custom'],
  'REDM SETTINGS': ['no-wind-speed', 'no-vignette', 'no-grass', 'no-tracer', 'no-heathaze', 'no-bushes', 'no-cactus', 'no-explosion', 'weaponbinds', 'potato-graphics', 'stretched', 'lowsettings'],
});
const CHANNELS = new Set(Object.values(GROUPS).flat());
const EXCLUDED = /(?:^|[^a-z0-9])(?:pm-bypass|faster-scope|fast-scope)(?:$|[^a-z0-9])/i;
const CATEGORIES = new Set(['weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings', 'addons']);
const UNSUPPORTED = /\.(?:lua|luac|pluto|js|mjs|cjs|py|ps1|psm1|bat|cmd|vbs|vbe|wsf|exe|dll|asi|msi|com|scr|lnk)$/i;
const VIDEO = /\.(mp4|webm|mkv|mov|m4v)$/i;
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const posix = value => value.split(path.sep).join('/');
const slug = value => value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 110) || 'resource';
const relative = file => posix(path.relative(ROOT, file));
const parse = file => JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));

function displayName(value) {
  return String(value).replace(/\s*\(RedM\s+Hub\)\s*by\s+Dadash\b/gi, '').trim();
}
function cleanName(value) {
  return displayName(value).replace(/\s+(\.[a-z0-9]{1,10})$/i, '$1').replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').trim();
}
function inspectFile(file) {
  const stat = fs.statSync(file);
  if (!stat.isFile()) throw Error('Expected a regular file');
  const hash = crypto.createHash('sha256'), fd = fs.openSync(file, 'r'), buffer = Buffer.alloc(1024 * 1024);
  let length, size = 0, header;
  try {
    while ((length = fs.readSync(fd, buffer, 0, buffer.length, null)) > 0) {
      header ||= Buffer.from(buffer.subarray(0, Math.min(length, 16)));
      hash.update(buffer.subarray(0, length)); size += length;
    }
  } finally { fs.closeSync(fd); }
  if (size !== stat.size) throw Error('Source file changed while being inspected');
  return { size, sha256: hash.digest('hex'), header: header || Buffer.alloc(0) };
}
function ownPath(value) {
  if (typeof value !== 'string' || !value || path.isAbsolute(value) || value.includes('\\')) throw Error(`Expected staged relative path: ${value}`);
  const full = path.resolve(ROOT, value);
  const rel = path.relative(ASSETS, full);
  if (!rel || rel === '..' || rel.startsWith(`..${path.sep}`) || path.isAbsolute(rel)) throw Error(`Path outside RedM assets: ${value}`);
  // Reject symbolic-link escapes through any already-existing parent.
  for (let at = full; at !== ASSETS; at = path.dirname(at)) {
    if (fs.existsSync(at) && fs.lstatSync(at).isSymbolicLink()) throw Error(`Symbolic link in staged path: ${value}`);
  }
  if (fs.existsSync(ASSETS) && fs.lstatSync(ASSETS).isSymbolicLink()) throw Error('RedM assets must not be a symbolic link');
  return full;
}
function copySource(input, file, metadata) {
  ownPath(relative(file));
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (!fs.existsSync(file)) fs.copyFileSync(input, file, fs.constants.COPYFILE_EXCL);
  const actual = inspectFile(file);
  if (actual.sha256 !== metadata.sha256 || actual.size !== metadata.size) throw Error(`Staged file bytes differ: ${file}`);
}
function imageKind(bytes) {
  if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return 'png';
  if (bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255) return 'jpg';
  if (bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP') return 'webp';
  if (['GIF87a', 'GIF89a'].includes(bytes.subarray(0, 6).toString())) return 'gif';
  return null;
}
function required(options, key) {
  if (typeof options[key] !== 'string' || !options[key].trim()) throw Error(`--${key} is required`);
  return options[key];
}
function channelOf(options) {
  const value = required(options, 'channel').replace(/^#/, '');
  if (!CHANNELS.has(value) || EXCLUDED.test(value)) throw Error(`Channel outside the allowed scope: ${value}`);
  return value;
}
function evidence(record) {
  const file = path.join(ASSETS, 'evidence', `${record.id}.json`);
  const observation = { sourceReference: record.sourceReference, observedAtUtc: new Date().toISOString() };
  if (fs.existsSync(file)) {
    const previous = parse(file);
    if (previous.sha256 !== record.sha256 || previous.kind !== record.kind || previous.localPath !== record.localPath) throw Error(`Conflicting evidence: ${file}`);
    record.observations = previous.observations || [];
  }
  record.observations ||= [];
  if (!record.observations.some(value => value.sourceReference === observation.sourceReference)) record.observations.push(observation);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  ownPath(relative(file));
  fs.writeFileSync(file, JSON.stringify(record, null, 2) + '\n');
  return relative(file);
}
function stage(options) {
  const channel = channelOf(options), input = path.resolve(required(options, 'file'));
  const sourceReference = required(options, 'source-reference');
  const role = options.role || 'download';
  if (!['download', 'source-image', 'video'].includes(role)) throw Error('--role must be download, source-image, or video');
  const sourceInputName = path.basename(input), originalFileName = options['original-name'] || sourceInputName;
  if (path.basename(originalFileName) !== originalFileName || path.extname(originalFileName).toLowerCase() !== path.extname(sourceInputName).toLowerCase()) throw Error('Original name must be a filename with the source file extension');
  if (UNSUPPORTED.test(originalFileName) || UNSUPPORTED.test(sourceInputName) || EXCLUDED.test(originalFileName)) throw Error('Scripts, executable software, and excluded resources are outside this acquisition');
  const metadata = inspectFile(input), hash = metadata.sha256;
  const name = cleanName(options.name || originalFileName);
  if (!name || name === '.' || name === '..' || UNSUPPORTED.test(name) || EXCLUDED.test(name)) throw Error('Invalid or excluded suggested filename');
  if (path.extname(name).toLowerCase() !== path.extname(originalFileName).toLowerCase()) throw Error('Suggested filename must retain the original file extension');
  if (role === 'source-image' && !imageKind(metadata.header)) throw Error('Source preview must be an original PNG, JPEG, WebP, or GIF image');
  if (role === 'video' && !VIDEO.test(name)) throw Error('Unsupported video container');
  if (role === 'download' && VIDEO.test(name)) throw Error('Showcase videos are private preview sources; use --role video');
  const id = `${channel}-${slug(path.parse(name).name)}-${hash.slice(0, 12)}`;
  if (options.folder && options.folder !== 'files') throw Error('--folder only accepts files for reviewed export staging');
  const folder = role === 'source-image' ? 'previews' : role === 'video' ? 'showcases' : options.folder || 'downloads';
  const localPath = relative(path.join(ASSETS, folder, channel, `${slug(path.parse(name).name)}--${hash.slice(0, 12)}${path.extname(name).toLowerCase()}`));
  copySource(input, ownPath(localPath), metadata);
  const credits = options.credits || (/\(RedM\s+Hub\)\s*by\s+Dadash/i.test(originalFileName) ? 'Dadash (original source filename credit)' : null);
  const evidencePath = evidence({ id, kind: role, localPath, size: metadata.size, sha256: hash, originalFileName, sourceInputName, sourceInputPath: input, sourceChannel: channel, sourceReference, credits, archiveContentsInspected: false });
  if (role === 'source-image') return { preview: localPath, previewKind: 'source-image', previewVerified: true, previewEvidence: evidencePath, previewCaption: options.caption || 'Original image supplied with the resource.', credits };
  return { file: { localPath, name, size: metadata.size, sha256: hash }, ...(role === 'video' ? { role: 'private-showcase-source' } : {}), credits, sourceEvidence: evidencePath, note: 'Original file bytes retained. Archive dependencies and installation instructions need separate inspection.' };
}
function frame(options) {
  const channel = channelOf(options), input = path.resolve(required(options, 'video'));
  const sourceReference = required(options, 'source-reference');
  const timestamp = Number(required(options, 'time'));
  if (!Number.isFinite(timestamp) || timestamp <= 0 || timestamp > 86400) throw Error('--time must be seconds greater than zero and at most 86400');
  if (!VIDEO.test(input) || EXCLUDED.test(path.basename(input))) throw Error('Expected a permitted local showcase video');
  const videoHash = inspectFile(input).sha256;
  const id = `${channel}-${slug(options.id || path.parse(input).name)}-${videoHash.slice(0, 12)}-${String(timestamp).replace('.', '-')}`;
  const output = path.join(ASSETS, 'previews', channel, `${id}.png`);
  ownPath(relative(output));
  fs.mkdirSync(path.dirname(output), { recursive: true });
  const preview = relative(output);
  const proof = path.join(ASSETS, 'evidence', `${id}.json`);
  const caption = options.caption || `Frame extracted from the original showcase video at ${timestamp} seconds.`;
  if (fs.existsSync(output) && fs.existsSync(proof)) {
    const record = parse(proof), bytes = fs.readFileSync(output);
    if (record.kind !== 'extracted-frame' || record.localPath !== preview || record.sourceVideoSha256 !== videoHash ||
        record.timestampSeconds !== timestamp || record.sha256 !== sha(bytes) || imageKind(bytes) !== 'png') {
      throw Error('Existing extracted frame differs from its source evidence');
    }
    return { preview, previewKind: 'extracted-frame', previewVerified: true, previewEvidence: relative(proof), previewCaption: caption };
  }
  // No shell: only an installed ffmpeg reads the video. No resource code runs.
  const argv = ['-nostdin', '-hide_banner', '-loglevel', 'error', '-n', '-i', input, '-ss', String(timestamp), '-frames:v', '1', '-an', output];
  const result = spawnSync(options.ffmpeg || 'ffmpeg', argv, { encoding: 'utf8', windowsHide: true, timeout: 120000, maxBuffer: 1024 * 1024 });
  if (result.error) throw Error(`Could not run installed ffmpeg: ${result.error.message}`);
  if (result.status !== 0 || !fs.existsSync(output)) throw Error(`Frame extraction failed: ${(result.stderr || '').trim()}`);
  const bytes = fs.readFileSync(output);
  if (imageKind(bytes) !== 'png') throw Error('Extracted output is not a PNG');
  const previewEvidence = evidence({ id, kind: 'extracted-frame', localPath: relative(output), size: bytes.length, sha256: sha(bytes), sourceInputPath: input, originalFileName: path.basename(input), sourceVideoSha256: videoHash, timestampSeconds: timestamp, sourceChannel: channel, sourceReference, method: 'ffmpeg decoded video frame', commandArguments: argv });
  return { preview, previewKind: 'extracted-frame', previewVerified: true, previewEvidence, previewCaption: caption };
}
function coverage() {
  return Object.entries(GROUPS).flatMap(([group, channels]) => channels.map(channel => ({ channel, group, status: 'not-inspected', inspectedPosts: 0, acquiredFiles: 0, historyComplete: false, evidence: [], gaps: ['Channel history has not been inspected.'] })));
}
function validate(manifestPath = MANIFEST) {
  const manifest = parse(manifestPath), errors = [], warnings = [], items = manifest.items, ids = new Set();
  const fail = (id, message) => errors.push(`${id}: ${message}`);
  const checkFile = (localPath, expected, label) => {
    let metadata;
    try { metadata = inspectFile(ownPath(localPath)); } catch (error) { errors.push(`${label}: ${error.message}`); return null; }
    if (expected?.size !== undefined && expected.size !== metadata.size) errors.push(`${label}: byte count differs`);
    if (expected?.sha256 && expected.sha256.toLowerCase() !== metadata.sha256) errors.push(`${label}: SHA-256 differs`);
    return metadata;
  };
  if (!Array.isArray(items)) throw Error('Manifest items must be an array');
  for (const item of items) {
    const id = item.id || '(missing id)';
    if (!item.id || ids.has(item.id)) fail(id, 'missing or duplicate id');
    ids.add(item.id);
    if (item.game !== 'redm') fail(id, 'game must be redm');
    if (!CATEGORIES.has(item.category)) fail(id, `unexpected category ${item.category}`);
    if (typeof item.name !== 'string' || !item.name.trim()) fail(id, 'missing display name');
    if (displayName(item.name) !== item.name) fail(id, 'display name needs cleaning');
    if (!CHANNELS.has(String(item.sourceChannel || '').replace(/^#/, ''))) fail(id, 'source channel is missing or outside the requested scope');
    if (EXCLUDED.test([id, item.name, item.sourceChannel].join(' '))) fail(id, 'excluded resource');
    if (!item.credits || (Array.isArray(item.credits) && !item.credits.length)) warnings.push(`${id}: original author credits have not been recorded`);
    if (!item.requirements || (Array.isArray(item.requirements) && !item.requirements.length)) warnings.push(`${id}: source-specific installation requirements have not been recorded`);
    if (!Array.isArray(item.files) || !item.files.length) warnings.push(`${id}: no locally available download`);
    for (const file of item.files || []) {
      if (!file.name || cleanName(file.name) !== file.name || UNSUPPORTED.test(file.name) || EXCLUDED.test(file.name)) fail(id, 'invalid, unclean, executable, or excluded download name');
      if (VIDEO.test(file.name)) fail(id, 'showcase video is a private preview source, not a resource-page download');
      if (!file.localPath) { fail(id, 'resource download must be staged locally for same-page saving'); continue; }
      checkFile(file.localPath, file, `${id} download`);
      if (!Number.isSafeInteger(file.size) || file.size < 1 || !/^[a-f0-9]{64}$/i.test(file.sha256 || '')) fail(id, 'download needs positive byte size and SHA-256');
    }
    if (item.preview) {
      const metadata = checkFile(item.preview, null, `${id} preview`);
      if (metadata && !imageKind(metadata.header)) fail(id, 'preview is not a supported source image');
      if (item.previewVerified === true) {
        if (!['source-image', 'extracted-frame', 'original-image', 'author-preview'].includes(item.previewKind)) fail(id, 'verified preview needs source-image or extracted-frame provenance');
        if (!item.previewEvidence) fail(id, 'verified preview needs a private previewEvidence record');
        else {
          try {
            const proof = parse(ownPath(item.previewEvidence));
            if (!['source-image', 'extracted-frame'].includes(proof.kind) || proof.localPath !== item.preview || !proof.sourceReference || !proof.sourceChannel) fail(id, 'preview evidence does not identify the source image/frame');
            if (metadata && (proof.sha256 !== metadata.sha256 || proof.size !== metadata.size)) fail(id, 'preview evidence bytes differ');
            if (proof.kind === 'extracted-frame' && (!(proof.timestampSeconds > 0) || !/^[a-f0-9]{64}$/i.test(proof.sourceVideoSha256 || '') || proof.method !== 'ffmpeg decoded video frame')) fail(id, 'frame evidence lacks a decoded video timestamp and source hash');
          } catch (error) { fail(id, `invalid preview evidence: ${error.message}`); }
        }
      }
    } else if (item.previewVerified === true) fail(id, 'previewVerified without a preview');
  }
  const seenCoverage = new Set();
  for (const entry of manifest.coverage || []) {
    const channel = String(entry.channel || entry.sourceChannel || '').replace(/^#/, '');
    if (!CHANNELS.has(channel)) { errors.push(`Coverage outside the requested scope: ${channel}`); continue; }
    if (seenCoverage.has(channel)) errors.push(`Duplicate channel coverage: ${channel}`);
    seenCoverage.add(channel);
    if (entry.historyComplete === true && !(Array.isArray(entry.evidence) && entry.evidence.length)) errors.push(`${channel}: complete history claim needs bounded inspection evidence`);
  }
  for (const channel of CHANNELS) if (!seenCoverage.has(channel)) errors.push(`Missing coverage entry: ${channel}`);
  return { manifest: relative(path.resolve(manifestPath)), items: items.length, channels: seenCoverage.size, expectedChannels: CHANNELS.size, errors, warnings, valid: errors.length === 0, note: 'Checks local bytes and declared evidence only; does not establish archive contents, Discord history completeness, or runtime compatibility.' };
}
function optionsOf(args) {
  const options = {};
  for (let i = 0; i < args.length; i += 2) {
    if (!/^--[a-z][a-z-]*$/.test(args[i]) || !args[i + 1] || args[i + 1].startsWith('--')) throw Error(`Expected --option value, got ${args[i]}`);
    if (Object.hasOwn(options, args[i].slice(2))) throw Error(`Repeated option ${args[i]}`);
    options[args[i].slice(2)] = args[i + 1];
  }
  return options;
}
const HELP = `Offline RedM resource acquisition (no network; never edits redm.json)

  stage --file PATH --channel CHANNEL --source-reference TEXT
        [--name CLEAN-FILENAME] [--original-name SOURCE-FILENAME] [--credits TEXT]
        [--folder files]
        [--role download|source-image|video] [--caption TEXT]
  frame --video PATH --time SECONDS --channel CHANNEL --source-reference TEXT
        [--id RESOURCE-ID] [--ffmpeg INSTALLED-FFMPEG-PATH] [--caption TEXT]
  coverage
  validate [--manifest PATH]

stage copies unchanged bytes and emits a file/preview descriptor plus private
evidence. Copy the returned fields into the separately reviewed manifest.
source-image means an actual source still image, never a video thumbnail.
frame decodes the local video using an existing ffmpeg installation.
coverage emits the 31 requested channel rows as uninspected, with no claims.
validate requires local downloads and genuine preview evidence. Archives are
retained intact; inspect their dependencies/installation requirements separately.
`;
if (require.main === module) {
  try {
    const [command, ...args] = process.argv.slice(2);
    if (!command || command === '--help' || command === 'help') console.log(HELP);
    else {
      const options = optionsOf(args);
      const result = command === 'stage' ? stage(options) : command === 'frame' ? frame(options) : command === 'coverage' ? coverage() : command === 'validate' ? validate(options.manifest) : null;
      if (!result) throw Error(`Unknown command: ${command}`);
      console.log(JSON.stringify(result, null, 2));
      if (command === 'validate' && !result.valid) process.exitCode = 1;
    }
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
module.exports = { cleanName, imageKind, coverage, validate, stage, frame, GROUPS };
