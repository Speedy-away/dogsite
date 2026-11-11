#!/usr/bin/env node
'use strict';

// Offline review/staging bridge for redm-import-exports.cjs. Only explicit review
// records admit new cards. Resource payloads are copied, never executed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const acquisition = require('./redm-acquire.cjs');
const { buildOverlay } = require('./redm-graphics-overlay.cjs');
const ROOT = path.resolve(__dirname, '../..');
const BASE = 'project/community-menu-sources/redm';
const EVIDENCE = `${BASE}/evidence`;
const EXPORTS = `${EVIDENCE}/export-observations`;
const REVIEW_FILE = `${EVIDENCE}/export-reviews.json`;
const INPUT = 'C:/Users/whatw/Desktop/redm-packs-';
const SEVENZIP = 'C:/Program Files/7-Zip/7z.exe';
const CATEGORIES = new Set(['weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings', 'addons']);
const CHANNELS = new Set(acquisition.coverage().map(row => row.channel));
const ARCHIVE = /\.(zip|rar|7z|tar|gz|bz2|xz)$/i;
const SCRIPT = /\.(lua|luac|pluto|js|mjs|cjs|py|ps1|psm1|bat|cmd|vbs|vbe|wsf|exe|dll|asi|msi|com|scr|lnk)$/i;
const FORBIDDEN = /(?:^|[^a-z0-9])(?:bypass|pm-bypass|fast-?scope|faster-?scope)(?:$|[^a-z0-9])/i;
const MEDIA = /\.(mp4|webm|mov|mkv|m4v|avi|png|jpe?g|webp|gif|bmp|avif)$/i;
const posix = value => value.split(path.sep).join('/');
const read = file => JSON.parse(fs.readFileSync(path.resolve(ROOT, file), 'utf8').replace(/^\uFEFF/, ''));
const exists = file => fs.existsSync(path.resolve(ROOT, file));
const within = (base, file) => { const rel = path.relative(base, file); return rel === '' || (!path.isAbsolute(rel) && rel !== '..' && !rel.startsWith(`..${path.sep}`)); };
const cleanText = value => String(value || '').replace(/https?:\/\/\S+/gi, '').replace(/\s*\(RedM\s+Hub\)\s*by\s+Dadash\b/gi, '').replace(/[\x00-\x08\x0b\x0c\x0e-\x1f]/g, '').trim();
const category = channel => channel === 'weaponskins' ? 'weapon-models' : channel === 'weapon-soundpack' ? 'sound-packs' : channel === 'clean-scope' ? 'scopes' : ['ui-boost', 'colorsxml-presets'].includes(channel) ? 'ui-presets' : ['tracer-presets', 'bloodfx', 'more-blood'].includes(channel) ? 'visual-effects' : acquisition.GROUPS['REDM GRAPHIC PACKS'].includes(channel) ? 'graphics-packs' : 'settings';

function inspectFile(file) {
  const stat = fs.statSync(file), hash = crypto.createHash('sha256');
  if (!stat.isFile()) throw Error('Source asset is not a file');
  const fd = fs.openSync(file, 'r'), bytes = Buffer.alloc(1024 * 1024);
  let length, size = 0;
  try { while ((length = fs.readSync(fd, bytes, 0, bytes.length, null)) > 0) { hash.update(bytes.subarray(0, length)); size += length; } } finally { fs.closeSync(fd); }
  if (size !== stat.size) throw Error('Source file changed during inspection');
  return { size, sha256: hash.digest('hex') };
}
function sourcePath(asset) {
  if (!asset.local?.exists || !asset.local.path) throw Error(`Local source bytes unavailable: ${asset.originalFileName}`);
  let input = path.resolve(ROOT, asset.local.path), allowed = path.resolve(INPUT);
  if (!within(allowed, input) || input === allowed) throw Error('Source asset is outside the user-selected export directory');
  if (!fs.existsSync(input)) {
    // A later export can replace the desktop batch. Reuse a staged original
    // only when its bytes still match the recorded attachment hash and size.
    const evidenceRoot = path.resolve(ROOT, EVIDENCE);
    const suffix = `-${asset.local.sha256?.slice(0, 12)}.json`;
    const proof = fs.readdirSync(evidenceRoot).filter(name => name.endsWith(suffix)).map(name => read(path.join(evidenceRoot, name)))
      .find(record => record.sha256 === asset.local.sha256 && record.size === asset.local.size &&
        record.originalFileName === asset.originalFileName && ['download', 'source-image'].includes(record.kind));
    if (proof?.localPath) {
      input = path.resolve(ROOT, proof.localPath);
      allowed = path.resolve(ROOT, BASE);
      if (!within(allowed, input) || input === allowed) throw Error('Staged fallback escaped the RedM asset directory');
    }
  }
  for (let at = input; ; at = path.dirname(at)) {
    if (fs.existsSync(at) && fs.lstatSync(at).isSymbolicLink()) throw Error('Source asset path contains a symbolic link');
    if (at === allowed) break;
  }
  const actual = inspectFile(input);
  if (actual.size !== asset.local.size || actual.sha256 !== asset.local.sha256 || (asset.declaredBytes != null && actual.size !== asset.declaredBytes)) throw Error(`Source bytes differ from export evidence: ${asset.originalFileName}`);
  return input;
}
function observation(candidate) {
  const references = candidate.observations || [];
  if (!references.length) throw Error('Candidate has no export observation evidence');
  for (const reference of references) {
    if (!String(reference.evidenceFile || '').startsWith(`${EXPORTS}/channel-`)) continue;
    const value = read(reference.evidenceFile);
    if (value.schema !== 'redm-offline-export-observation-v1' || value.classification?.sourceChannel !== candidate.sourceChannel || String(value.channel?.id) !== String(candidate.sourceChannelId)) continue;
    const message = value.messages?.find(row => row.sourceMessageId === candidate.sourceMessageId);
    if (message) return { reference, value, message };
  }
  throw Error('Candidate message is absent from its export evidence');
}
function inspectArchive(input, originalName) {
  if (!ARCHIVE.test(originalName)) return { archive: false, blocked: SCRIPT.test(originalName) || FORBIDDEN.test(originalName), members: [], documents: [] };
  if (!fs.existsSync(SEVENZIP)) throw Error('Installed 7-Zip is unavailable for archive inspection');
  const listing = spawnSync(SEVENZIP, ['l', '-slt', '-ba', '-sccUTF-8', '--', input], { encoding: 'utf8', windowsHide: true, timeout: 120000, maxBuffer: 16 * 1024 * 1024 });
  if (listing.error || listing.status !== 0) throw Error(`7-Zip static inventory failed: ${listing.error?.message || listing.stderr?.trim()}`);
  const members = listing.stdout.split(/\r?\n\r?\n/).map(block => Object.fromEntries(block.split(/\r?\n/).filter(line => line.includes(' = ')).map(line => { const at = line.indexOf(' = '); return [line.slice(0, at), line.slice(at + 3)]; }))).filter(row => row.Path).map(row => ({ path: row.Path, size: Number(row.Size || 0), crc: row.CRC || null, directory: row.Folder === '+' || /^D/.test(row.Attributes || ''), encrypted: row.Encrypted === '+', link: Boolean(row['Symbolic Link'] || row['Hard Link'] || /(?:^|\s)l[rwx-]{9}/.test(row.Attributes || '')) }));
  if (!members.length) throw Error('No archive members could be inventoried');
  const issues = [];
  for (const member of members.filter(row => !row.directory)) {
    const name = member.path.replace(/\\/g, '/');
    if (SCRIPT.test(name) || FORBIDDEN.test(name)) issues.push(`Excluded code/resource member: ${member.path}`);
    if (member.encrypted) issues.push(`Encrypted member cannot be inspected: ${member.path}`);
    if (member.link) issues.push(`Archive member is a link: ${member.path}`);
    if (path.posix.isAbsolute(name) || /^[a-z]:/i.test(name) || name.split('/').includes('..')) issues.push(`Unsafe member path: ${member.path}`);
    if (ARCHIVE.test(name)) issues.push(`Nested archive requires separate inspection: ${member.path}`);
  }
  const documents = [];
  for (const member of members.filter(row => !row.directory && row.size > 0 && row.size <= 256 * 1024 && /(?:readme|install|instructions?|tutorial|credits?|licen[cs]e)[^/\\]*\.(?:txt|md|ini|xml|json)$/i.test(row.path)).slice(0, 8)) {
    const result = spawnSync(SEVENZIP, ['x', '-so', '--', input, member.path], { encoding: 'utf8', windowsHide: true, timeout: 30000, maxBuffer: 512 * 1024 });
    if (result.status === 0 && !result.error) documents.push({ path: member.path, content: result.stdout });
    else issues.push(`Could not read source documentation: ${member.path}`);
  }
  return { archive: true, blocked: issues.length > 0, issues, memberCount: members.length, extensions: [...new Set(members.filter(row => !row.directory).map(row => path.extname(row.path).toLowerCase()))].sort(), members, documents, method: 'Installed 7-Zip static listing and bounded text output only; no downloaded content executed' };
}
function loadCandidates() {
  if (!exists(`${EXPORTS}/source-candidates.json`)) return [];
  const input = read(`${EXPORTS}/source-candidates.json`);
  if (input.schema !== 'redm-offline-source-candidates-v1' || input.privateEvidenceOnly !== true) throw Error('Unexpected source candidate schema');
  return input.items || [];
}
function inspectCandidates() {
  return loadCandidates().map(candidate => {
    try {
      if (!CHANNELS.has(candidate.sourceChannel)) throw Error('Candidate channel outside requested scope');
      const source = observation(candidate);
      const assets = (candidate.sourceAssets || []).map(asset => {
        if (asset.role !== 'resource-file' || SCRIPT.test(asset.originalFileName) || FORBIDDEN.test(asset.originalFileName) || MEDIA.test(asset.originalFileName)) throw Error(`Excluded or non-resource attachment: ${asset.originalFileName}`);
        const input = sourcePath(asset);
        return { originalFileName: asset.originalFileName, sourceAttachmentId: asset.sourceAttachmentId, localPath: asset.local.path, size: asset.local.size, sha256: asset.local.sha256, inspection: inspectArchive(input, asset.originalFileName) };
      });
      return { candidateId: candidate.id, sourceChannel: candidate.sourceChannel, sourceMessageId: candidate.sourceMessageId, proposedName: candidate.name, sharedBy: candidate.sharedBy, sourceContent: source.message.sourceContent, sourceTimestamp: source.message.timestamp, sourceEvidence: source.reference.evidenceFile, assets, samePostImages: candidate.sourceImages || [], privateShowcaseCount: candidate.privateShowcases?.length || 0, blocked: !assets.length || assets.some(asset => asset.inspection.blocked), reviewRequired: true };
    } catch (error) { return { candidateId: candidate.id, sourceChannel: candidate.sourceChannel, blocked: true, error: error.message }; }
  });
}

function stageOriginalPreview(candidate, source, review) {
  const imageMessage = review.preview.sourceMessageId ? source.value.messages.find(message => message.sourceMessageId === review.preview.sourceMessageId) : source.message;
  if (!imageMessage || (imageMessage !== source.message && !review.preview.associationReason)) throw Error('Separate-post preview requires an explicit reviewed association');
  const imageAsset = imageMessage.sourceImages?.find(asset =>
    (review.preview.sourceAttachmentId && asset.sourceAttachmentId === review.preview.sourceAttachmentId) ||
    (review.preview.localPath && asset.local?.path === review.preview.localPath));
  if (!imageAsset || !['source-image', 'embed-image'].includes(imageAsset.role) || imageAsset.previewReviewReason?.includes('thumbnail')) throw Error(`Preview is not an associated original source image: ${candidate.id}`);
  return acquisition.stage({ file: sourcePath(imageAsset), channel: candidate.sourceChannel, role: 'source-image',
    'source-reference': source.reference.evidenceFile, 'original-name': imageAsset.originalFileName, credits: review.credits,
    caption: review.preview.caption || 'Original image supplied with the resource.' });
}

function stageShowcaseStill(candidate, source, review) {
  const evidenceFile = review.showcaseStill.evidence;
  const evidenceRoot = path.resolve(ROOT, EVIDENCE);
  const resolvedEvidence = fs.realpathSync(path.resolve(ROOT, evidenceFile));
  if (!within(evidenceRoot, resolvedEvidence)) throw Error('Showcase evidence is outside RedM evidence');
  const proof = read(resolvedEvidence);
  const image = new URL(proof.sourceReference);
  const id = image.pathname.match(/^\/vi\/([\w-]{11})\/maxres[123]\.jpg$/)?.[1];
  const matchesShowcase = id && source.message.privateShowcases?.some(asset => {
    if (asset.role !== 'private-showcase-link') return false;
    const video = new URL(asset.sourceUrl);
    return video.protocol === 'https:' && (
      (video.hostname === 'youtu.be' && video.pathname === '/' + id) ||
      (video.hostname === 'www.youtube.com' && video.pathname === '/watch' && video.searchParams.get('v') === id)
    );
  });
  if (image.origin !== 'https://i.ytimg.com' || !matchesShowcase || proof.kind !== 'source-image' || proof.sourceChannel !== candidate.sourceChannel) {
    throw Error(`Still is not a numbered frame from the resource’s linked showcase: ${candidate.id}`);
  }
  const file = fs.realpathSync(path.resolve(ROOT, proof.localPath));
  if (!within(path.resolve(ROOT, BASE, 'previews', candidate.sourceChannel), file)) throw Error('Showcase still is outside its preview directory');
  const bytes = fs.readFileSync(file);
  if (proof.size !== bytes.length || proof.sha256 !== crypto.createHash('sha256').update(bytes).digest('hex') || acquisition.imageKind(bytes) !== 'jpg') {
    throw Error('Showcase still differs from its reviewed source image');
  }
  return { preview: proof.localPath, previewKind: 'source-image', previewVerified: true, previewEvidence: evidenceFile, previewCaption: review.showcaseStill.caption };
}

function apply(items, coverage, options = {}) {
  const candidates = loadCandidates(), reviews = exists(REVIEW_FILE) ? read(REVIEW_FILE).reviews || [] : [];
  const results = [], privateRecords = [];
  for (const candidate of candidates) {
    const review = reviews.find(row => row.candidateId === candidate.id && row.reviewed === true);
    const source = observation(candidate);
    const known = items.find(item => item.sourceChannel === candidate.sourceChannel && item.files?.length && candidate.sourceAssets?.length === item.files.length && item.files.every(file => candidate.sourceAssets.some(asset => asset.local?.sha256 === file.sha256 && asset.local?.size === file.size)));
    if (known) {
      for (const file of known.files) {
        const staged = inspectFile(path.resolve(ROOT, file.localPath));
        if (staged.sha256 !== file.sha256 || staged.size !== file.size) throw Error(`Previously acquired bytes differ: ${file.name}`);
      }
      known.sourceProvenance.push({ kind: 'reviewed-offline-export-duplicate', evidence: source.reference.evidenceFile, sourceMessageId: candidate.sourceMessageId });
      if (options.write && !known.previewVerified && review?.preview?.reviewed === true) {
        Object.assign(known, stageOriginalPreview(candidate, source, review));
      }
      results.push({ candidateId: candidate.id, status: 'deduplicated', itemId: known.id });
      continue;
    }
    if (!review) { results.push({ candidateId: candidate.id, status: 'review-pending' }); continue; }
    if (!Array.isArray(review.requirements) || !review.requirements.length || !review.name || !review.credits) throw Error(`Reviewed candidate lacks requirements, name, or credits: ${candidate.id}`);
    const categoryName = review.category || category(candidate.sourceChannel);
    if (!CATEGORIES.has(categoryName)) throw Error(`Invalid reviewed category: ${candidate.id}`);
    const assets = candidate.sourceAssets || [];
    if (!assets.length && !(review.guide && categoryName === 'settings')) throw Error(`Reviewed candidate has no resources: ${candidate.id}`);
    const staged = [];
    if (options.write && review.guide && !assets.length) {
      const guideName = `${review.name}.txt`;
      const file = path.join(ROOT, EVIDENCE, 'settings-guides', candidate.id, guideName);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, [review.name, '', review.credits, '', ...review.requirements].join('\n') + '\n', 'utf8');
      const output = acquisition.stage({ file, channel: candidate.sourceChannel, 'source-reference': source.reference.evidenceFile, credits: review.credits, folder: 'files' });
      staged.push(output.file);
      privateRecords.push({ candidateId: candidate.id, staged: output.file, evidence: output.sourceEvidence, kind: 'settings-guide-derived-from-source-post' });
    }
    for (const asset of assets) {
      if (asset.role !== 'resource-file' || SCRIPT.test(asset.originalFileName) || FORBIDDEN.test(asset.originalFileName) || MEDIA.test(asset.originalFileName)) throw Error(`Excluded or non-resource attachment: ${asset.originalFileName}`);
      const input = sourcePath(asset), inspection = inspectArchive(input, asset.originalFileName);
      if (!options.write) continue;
      const desiredName = review.downloadNames?.[asset.originalFileName] || asset.suggestedDownloadName || acquisition.cleanName(asset.originalFileName);
      let stageInput = input, stageName = desiredName, originalName = asset.originalFileName, overlayMembers;
      if (inspection.blocked) {
        if (categoryName !== 'graphics-packs' || !review.graphicsOverlay || !inspection.archive) {
          throw Error(`Package cannot be staged: ${asset.originalFileName}`);
        }
        stageName = `${path.parse(desiredName).name}.zip`;
        originalName = stageName;
        stageInput = path.join(ROOT, EVIDENCE, 'graphics-overlays', `${asset.local.sha256}-v1.zip`);
        overlayMembers = buildOverlay({ input, output: stageInput, members: inspection.members, binary: SEVENZIP });
        const derived = inspectArchive(stageInput, stageName);
        if (derived.blocked || derived.members.filter(member => !member.directory).length !== overlayMembers.length) {
          throw Error(`Generated overlay did not pass archive validation: ${stageName}`);
        }
      }
      const stagedFile = acquisition.stage({ file: stageInput, channel: candidate.sourceChannel, 'source-reference': source.reference.evidenceFile, 'original-name': originalName, name: stageName, credits: review.credits, folder: 'files' });
      staged.push(stagedFile.file);
      privateRecords.push({ candidateId: candidate.id, sourceAttachmentId: asset.sourceAttachmentId, originalFileName: asset.originalFileName, originalSha256: asset.local.sha256, staged: stagedFile.file, evidence: stagedFile.sourceEvidence, inspection, ...(overlayMembers ? { overlayMembers } : {}) });
    }
    if (!options.write) { results.push({ candidateId: candidate.id, status: 'reviewed-awaiting-stage' }); continue; }
    const item = {
      id: review.id || candidate.id, game: 'redm', category: categoryName, sourceChannel: candidate.sourceChannel,
      name: cleanText(review.name), description: cleanText(review.description || review.name),
      files: staged, status: 'download', downloadStatus: 'available',
      credits: String(review.credits).replace(/https?:\/\/\S+/gi, '').trim(), requirements: review.requirements.map(cleanText).filter(Boolean),
      compatibility: cleanText(review.compatibility || 'Install according to the supplied source instructions. Runtime behavior has not been independently tested.'),
      version: review.version || null, versionBasis: cleanText(review.versionBasis || 'No explicit numbered release version was established in the reviewed source.'),
      ...(review.sourceFormat ? { sourceFormat: cleanText(review.sourceFormat) } : {}),
      changelog: [], changelogStatus: 'No independently reviewed author changelog recorded.',
      preview: null, previewVerified: false,
      tags: ['redm', candidate.sourceChannel, ...(review.tags || []).map(cleanText)],
      sourceProvenance: [{ kind: 'reviewed-offline-export', evidence: source.reference.evidenceFile, reviewEvidence: REVIEW_FILE, sourceMessageId: candidate.sourceMessageId, packageEvidence: `${EVIDENCE}/export-staging.json` }],
    };
    if (review.preview?.reviewed === true) {
      const output = stageOriginalPreview(candidate, source, review);
      Object.assign(item, output);
      privateRecords.push({ candidateId: candidate.id, previewEvidence: output.previewEvidence, sourceMessageId: review.preview.sourceMessageId || candidate.sourceMessageId, associationReason: review.preview.associationReason || 'Original image attachment in the same post as the resource.' });
    } else if (review.showcaseStill?.evidence) {
      const output = stageShowcaseStill(candidate, source, review);
      Object.assign(item, output);
      privateRecords.push({ candidateId: candidate.id, previewEvidence: output.previewEvidence, sourceMessageId: candidate.sourceMessageId, associationReason: 'YouTube-provided numbered video still from the showcase linked in the same resource post.' });
    } else if (review.frame?.localPath) {
      const videoMessage = review.frame.sourceMessageId ? source.value.messages.find(message => message.sourceMessageId === review.frame.sourceMessageId) : source.message;
      const video = videoMessage?.privateShowcases?.find(asset => asset.role === 'private-showcase-video' && asset.local?.path === review.frame.localPath);
      if (!video || (videoMessage !== source.message && !review.frame.associationReason)) throw Error('No reviewed local source video for preview frame');
      const input = sourcePath(video);
      const preview = acquisition.frame({ video: input, channel: candidate.sourceChannel, 'source-reference': source.reference.evidenceFile, id: candidate.id, time: String(review.frame.seconds), ffmpeg: 'C:/Program Files/ShareX/ffmpeg.exe', caption: review.frame.caption || 'Still from the original gameplay showcase.' });
      Object.assign(item, preview);
      privateRecords.push({ candidateId: candidate.id, previewEvidence: preview.previewEvidence, sourceMessageId: videoMessage.sourceMessageId, associationReason: review.frame.associationReason || 'Video attachment in the same resource post.' });
    }
    for (const preview of review.additionalPreviews || []) {
      if (preview.reviewed !== true) continue;
      const imageAsset = source.message.sourceImages?.find(asset => asset.sourceAttachmentId === preview.sourceAttachmentId);
      if (!imageAsset || !['source-image', 'embed-image'].includes(imageAsset.role) || imageAsset.previewReviewReason?.includes('thumbnail')) throw Error('Supplemental preview is not a same-post original source image');
      const output = acquisition.stage({ file: sourcePath(imageAsset), channel: candidate.sourceChannel, role: 'source-image', 'source-reference': source.reference.evidenceFile, 'original-name': imageAsset.originalFileName, credits: review.credits, caption: preview.caption || 'Additional original source screenshot from the same resource post.' });
      item.additionalPreviews ||= [];
      item.additionalPreviews.push({ preview: output.preview, previewKind: output.previewKind, previewVerified: true, previewEvidence: output.previewEvidence, previewCaption: output.previewCaption });
      privateRecords.push({ candidateId: candidate.id, previewEvidence: output.previewEvidence, sourceMessageId: source.message.sourceMessageId, associationReason: 'Additional original source screenshot in the same resource post; visually inspected.' });
    }
    items.push(item);
    results.push({ candidateId: candidate.id, status: 'staged', itemId: item.id, files: staged.length });
  }
  const exportCoverage = exists(`${EXPORTS}/coverage.json`) ? read(`${EXPORTS}/coverage.json`).coverage || [] : [];
  for (const row of coverage) {
    const exported = exportCoverage.find(value => value.sourceChannel === row.channel && value.inspectedExports > 0);
    if (!exported) continue;
    const channelItems = items.filter(item => item.sourceChannel === row.channel);
    Object.assign(row, { status: channelItems.length ? 'acquired-from-reviewed-offline-export' : 'offline-export-reviewed-acquisition-pending', inspectedExports: exported.inspectedExports, exportedMessages: exported.uniqueInspectedMessages, inspectedPosts: Math.max(row.inspectedPosts, exported.uniqueInspectedMessages), historyComplete: false, resourceItems: channelItems.length, acquiredFiles: channelItems.reduce((sum, item) => sum + item.files.length, 0), evidence: [...new Set([...row.evidence, ...exported.exports.map(value => value.evidenceFile)])], gaps: ['Saved export batches were inspected; exhaustive channel history is not independently verified.', ...results.filter(result => result.status === 'review-pending' && candidates.find(candidate => candidate.id === result.candidateId)?.sourceChannel === row.channel).map(result => `${result.candidateId}: installation, dependency, package, or preview review remains pending.`), ...channelItems.filter(item => !item.previewVerified).map(item => `${item.name}: genuine preview is pending.`)] });
  }
  return { results, privateRecords, reviewEvidence: REVIEW_FILE };
}
if (require.main === module) {
  try {
    const result = { schema: 'redm-static-export-inspection-v1', method: 'Offline local file hashes and installed 7-Zip listing only', candidates: inspectCandidates() };
    if (process.argv.includes('--write-inspection')) {
      const file = path.resolve(ROOT, `${EVIDENCE}/export-inspection.json`);
      fs.writeFileSync(file, JSON.stringify(result, null, 2) + '\n');
    }
    console.log(JSON.stringify(result, null, 2));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
module.exports = { apply, inspectCandidates, sourcePath, inspectArchive, category, inspectFile };
