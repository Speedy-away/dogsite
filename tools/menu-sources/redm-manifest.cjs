#!/usr/bin/env node
'use strict';

// Curated, offline RedM source manifest. No fetching, UI, shared catalog writes,
// archive execution, or inference that every channel message has been inspected.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const acquisition = require('./redm-acquire.cjs');
const exportStaging = require('./redm-stage-exports.cjs');
const ROOT = path.resolve(__dirname, '../..');
const BASE = 'project/community-menu-sources/redm';
const EVIDENCE = `${BASE}/evidence`;
const read = file => JSON.parse(fs.readFileSync(path.join(ROOT, file), 'utf8').replace(/^\uFEFF/, ''));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const exists = file => fs.existsSync(path.join(ROOT, file));
const write = (file, value) => {
  if (file !== 'project/community-menu-sources/redm.json' && !file.startsWith(`${EVIDENCE}/`)) throw Error('Write outside RedM manifest/evidence scope');
  fs.mkdirSync(path.dirname(path.join(ROOT, file)), { recursive: true });
  fs.writeFileSync(path.join(ROOT, file), typeof value === 'string' ? value : JSON.stringify(value, null, 2) + '\n');
};
const prefix = file => file.startsWith(`${BASE}/`) ? file : `${BASE}/${file}`;

function build(options = {}) {
  const downloads = exists(`${EVIDENCE}/downloads.json`) ? read(`${EVIDENCE}/downloads.json`).files || [] : [];
  const acquired = downloads.filter(file => file.status === 'downloaded');
  const filesFor = (channel, names) => names.map(name => {
    const file = acquired.find(row => row.channel === channel && row.originalFilename === name);
    if (!file) return null;
    const localPath = prefix(file.localPath), bytes = fs.readFileSync(path.join(ROOT, localPath));
    if (bytes.length !== file.size || sha(bytes) !== file.sha256) throw Error(`Acquired file differs from evidence: ${name}`);
    return { localPath, name: acquisition.cleanName(name), size: bytes.length, sha256: sha(bytes) };
  }).filter(Boolean);
  const items = [];
  const shared = (id, channel, category, name) => ({
    id, game: 'redm', category, name, sourceChannel: channel,
    version: null, versionBasis: 'The inspected source post does not identify a numbered release version.',
    status: 'download', downloadStatus: 'available',
    credits: 'Shared by 021 in RedM Hub. The inspected post does not identify the original file author; preserve all notices supplied with the file.',
    license: 'No license statement was supplied with this inspected attachment.',
    changelog: [], changelogStatus: 'No dated author changelog was supplied in the inspected channel posts.',
    preview: null, previewVerified: false,
    tags: ['redm', channel, 'client resource'],
    sourceProvenance: [{ kind: 'observed-discord-attachment', evidence: `${EVIDENCE}/${channel}.json`, acquisitionEvidence: `${EVIDENCE}/downloads.json` }],
  });
  const uiFiles = filesFor('ui-boost', ['durations.xml']);
  if (uiFiles.length) items.push({
    ...shared('redm-ui-boost-durations', 'ui-boost', 'ui-presets', 'UI Boost'),
    description: 'UI duration data shared for quicker map and pause-menu transitions and scrolling.',
    files: uiFiles,
    requirements: ['RedM client installation.', 'Place durations.xml in RedM Application Data/citizen/common/data/ui. Create the ui folder if it is absent.'],
    compatibility: 'RedM client UI data override. The source post describes faster map and pause-menu transitions and scrolling; runtime behavior has not been independently tested.',
    sourceDate: '2024-10-30', sourceDateBasis: 'Original attachment message timestamp visible in the inspected channel.',
    readme: `${EVIDENCE}/README.md`,
  });
  const bloodFiles = filesFor('more-blood', ['vfxbloodinfo.ymt']);
  if (bloodFiles.length) items.push({
    ...shared('redm-more-blood-vfxbloodinfo', 'more-blood', 'visual-effects', 'More Blood'),
    description: 'The vfxbloodinfo data attachment shared in the More Blood channel.',
    files: bloodFiles,
    requirements: ['RedM client installation.', 'Place vfxbloodinfo.ymt in RedM Application Data/citizen/common/data/effects. Create the effects folder if it is absent.'],
    compatibility: 'RedM client effect data override. Installation path is stated in the inspected source post; in-game appearance has not been independently tested.',
    sourceDate: '2025-01-08', sourceDateBasis: 'Original attachment message timestamp visible in the inspected channel.',
    readme: `${EVIDENCE}/README.md`,
  });

  // The PNG was decoded from the downloaded source GIF at t=1s using installed
  // ShareX ffmpeg. It is an actual source image frame, not a video thumbnail.
  const png = `${BASE}/previews/ui-boost/ui-boost-source-gif-frame.png`;
  const gif = acquired.find(file => file.channel === 'ui-boost' && file.originalFilename === 'uiboost.gif');
  const proofPath = `${EVIDENCE}/ui-boost-source-gif-frame.json`;
  const previewProofs = [];
  if (gif && exists(png)) {
    const bytes = fs.readFileSync(path.join(ROOT, png));
    if (acquisition.imageKind(bytes) !== 'png') throw Error('UI Boost decoded source frame is not PNG');
    const original = fs.readFileSync(path.join(ROOT, prefix(gif.localPath)));
    if (sha(original) !== gif.sha256) throw Error('Original UI Boost source GIF differs from downloaded evidence');
    previewProofs.push({ file: proofPath, value: {
      id: 'ui-boost-source-gif-frame', kind: 'source-image',
      localPath: png, size: bytes.length, sha256: sha(bytes),
      sourceReference: `${EVIDENCE}/ui-boost-media.json`, sourceChannel: 'ui-boost',
      sourceMessageId: gif.messageId, originalFileName: gif.originalFilename,
      originalLocalPath: prefix(gif.localPath), originalSha256: gif.sha256,
      sourceMediaType: 'image/gif', timestampSeconds: 1,
      method: 'ffmpeg decoded frame from original source GIF; no video thumbnail used',
      extractionCommand: ['C:/Program Files/ShareX/ffmpeg.exe', '-nostdin', '-hide_banner', '-loglevel', 'error', '-n', '-i', prefix(gif.localPath), '-ss', '1', '-frames:v', '1', '-an', png],
      verifiedBy: 'Local image inspection: the frame shows the in-game map from the source GIF.',
    } });
    const item = items.find(value => value.id === 'redm-ui-boost-durations');
    if (item) Object.assign(item, { preview: png, previewVerified: true, previewKind: 'source-image', previewEvidence: proofPath, previewCaption: 'Map view decoded at 1 second from the original UI Boost source GIF.' });
  }

  const coverage = acquisition.coverage().map(row => {
    const observedFile = `${EVIDENCE}/${row.channel}.json`;
    const candidate = exists(observedFile) ? read(observedFile) : null;
    // Metadata labels alone are insufficient after a failed UI navigation.
    // Known repeated colors-channel message IDs cannot establish tracer history.
    const expectedChannelIds = { 'ui-boost': '1301225316353577082', 'more-blood': '1326684182788837396', 'colorsxml-presets': '1315313159656964200' };
    const observedIds = candidate ? [...new Set([...(candidate.tree || '').matchAll(/ID: chat-messages-(\d+)-\d+/g)].map(match => match[1]))] : [];
    const wrongChannelIds = observedIds.some(id => Object.entries(expectedChannelIds).some(([channel, knownId]) => channel !== row.channel && id === knownId));
    const source = candidate?.channel === row.channel && !wrongChannelIds ? candidate : null;
    const messageIds = source ? [...new Set([...(source.tree || '').matchAll(/ID: chat-messages-\d+-(\d+)/g)].map(match => match[1]))] : [];
    const resourceItems = items.filter(item => item.sourceChannel === row.channel);
    const staged = acquired.filter(file => file.channel === row.channel);
    return {
      ...row,
      status: resourceItems.length ? 'acquired-from-bounded-observation' : source ? 'observed-acquisition-pending' : 'not-inspected',
      inspectedPosts: messageIds.length,
      observedMessageIds: messageIds,
      acquiredFiles: resourceItems.reduce((total, item) => total + item.files.length, 0),
      privateMediaFiles: staged.filter(file => /\.(mp4|webm|mov|mkv|gif)$/i.test(file.originalFilename)).length,
      resourceItems: resourceItems.length,
      historyComplete: false,
      ...(source ? { observedAtUtc: source.at, channelStartMarkerObserved: (source.tree || '').includes('This is the start of') } : {}),
      evidence: source ? [observedFile] : [],
      gaps: source ? ['Only the bounded loaded channel observation is recorded; exhaustive channel history was not independently verified.', ...(resourceItems.length ? resourceItems.filter(item => !item.previewVerified).map(item => `${item.name}: no genuine source still image or extracted showcase frame has been acquired.`) : ['No resource download bytes from this channel have been acquired for the catalog.'])] : ['Channel content has not been inspected; a visible channel name does not establish resource history or downloads.'],
    };
  });
  const colors = coverage.find(row => row.channel === 'colorsxml-presets');
  if (colors.inspectedPosts) Object.assign(colors, {
    observedResources: 7,
    observedResourceNames: ['Colors.xml design update', 'Yellow Colors.xml Preset', 'Purple Colors.xml Preset', 'Pink Colors.xml Preset', 'Blue Colors.xml Preset', 'Green Colors.xml Preset', 'Light blue Color Preset'],
    gaps: ['Seven loaded resource posts were observed; their colors.xml download bytes have not been acquired.', 'Original preview image bytes have not been acquired. Visible Discord screenshots are not being presented as original resource previews.', 'Source installation instructions place colors.xml under RedM Application Data/citizen/common/data/ui and require in-game colorblindness mode off. No excluded scope package is acquired or included.', 'Exhaustive channel history was not independently verified.'],
  });
  const weapons = coverage.find(row => row.channel === 'weaponskins');
  if (!weapons.inspectedPosts && exists(`${EVIDENCE}/user-screenshots.json`)) Object.assign(weapons, {
    status: 'user-screenshot-evidence-only', observedResources: 2,
    observedResourceNames: ['Star Wars Weapon Skins', 'Valorant Weapon Skins'],
    evidence: [`${EVIDENCE}/user-screenshots.json`],
    gaps: ['Two resource posts are visible in the user screenshots; live channel history was not inspected.', 'Neither weapon-skin archive has been acquired.', 'Visible showcase thumbnails do not qualify as extracted video frames. Genuine previews remain pending.'],
  });
  const exports = exportStaging.apply(items, coverage, options);
  const manifest = {
    schemaVersion: 1, version: 1, game: 'redm', auditedAt: '2026-11-11',
    purpose: 'Catalog of acquired RedM downloads and settings guides, with coverage limited to observed channel posts and local exports.',
    summary: { requestedChannels: coverage.length, boundedChannelObservations: coverage.filter(row => row.inspectedPosts > 0).length, offlineExportChannels: coverage.filter(row => row.inspectedExports > 0).length, resourceItems: items.length, resourceFiles: items.reduce((total, item) => total + item.files.length, 0), verifiedPreviews: items.filter(item => item.previewVerified).length, exportCandidatesPendingReview: exports.results.filter(row => row.status === 'review-pending').length, completeChannelHistories: 0 },
    policy: {
      excludedChannels: ['pm-bypass', 'fast-scope', 'faster-scope'],
      excludedContent: 'No Lua, bypass scripts, or FiveM resources are included.',
      downloads: 'Staged attachments retain original bytes. Graphics overlays retain selected original data files, and settings guides document source instructions.',
      previews: 'Only original source images or decoded source frames may be verified; no video thumbnails are presented as extracted frames.',
      credits: 'Display names and suggested download filenames omit the requested source suffix. Original attachment bytes, author notices, original source names, and private provenance are retained.',
      history: 'No channel is claimed as exhaustively inspected.',
    },
    evidence: { acquisitions: `${EVIDENCE}/downloads.json`, notes: `${EVIDENCE}/README.md`, screenshots: `${EVIDENCE}/user-screenshots.json`, offlineExports: `${EVIDENCE}/export-observations/coverage.json`, exportReviews: exports.reviewEvidence, stagedExports: `${EVIDENCE}/export-staging.json` },
    items, coverage,
  };
  const notes = `# RedM acquisition evidence

Private preparation notes. Do not copy this evidence directory, original showcase videos, source message links, or signed asset URLs onto resource pages.

## Acquired resource files

${items.map(item => `- ${item.name}: ${item.files.map(file => `${file.name} (${file.size} bytes, SHA-256 ${file.sha256})`).join('; ')}. Credits: ${item.credits} Installation: ${item.requirements.join(' ')}`).join('\n')}

## Original content and credits

Direct downloads preserve the original attachments. Citizen graphics overlays retain the original selected game data and package credits while omitting bundled runtime code. The original archive hashes and overlay file lists are in export-staging.json. Settings guides are text summaries of the exported posts. Original names and source messages stay in private evidence. Details retains the credited authors.

## Previews

${items.map(item => `- ${item.name}: ${item.previewVerified ? `${item.previewCaption} Private proof: ${item.previewEvidence}.` : 'No verified preview acquired.'}`).join('\n')}

The original UI Boost GIF was decoded at 1 second into a PNG showing the in-game map. A single frame does not verify transition speed. UI_BOOST.mp4 remains private tutorial material. Only reviewed original source images or actually decoded frames may be verified; no video thumbnail is treated as a frame.

## Saved export review

${exports.results.map(row => `- ${row.candidateId}: ${row.status}${row.itemId ? ` (${row.itemId})` : ''}.`).join('\n') || 'No saved export candidates inspected.'}

The importer reads saved HTML and JSON exports from Desktop/redm-packs-. Reviewed metadata is recorded in export-reviews.json. Files from one source post stay together. The installed 7-Zip inventories attachments and packages reviewed graphics overlays. Source documentation stays in the archive or private evidence.

## Channel coverage

All 31 requested channels have explicit coverage rows. Loaded observations, saved export batches, source candidates, missing bytes, and missing previews are recorded separately. No row claims exhaustive channel history. See redm.json coverage for exact current gaps. The misleadingly named tracer-presets.json and duplicate colorsxml observation contain colors messages (channel ID 1315313159656964200); corrected metadata preserves their bodies and they do not establish tracer history.

## Scope and integration

pm-bypass, fast-scope, and faster-scope are excluded. No Lua or bypass script, FiveM item, shared UI/catalog write, push, or deployment is performed here. Preserve the game-specific installation instructions above. Runtime behavior and appearance are not independently verified.

Inspect new exports: node tools/menu-sources/redm-stage-exports.cjs --write-inspection
Regenerate after source review: node tools/menu-sources/redm-manifest.cjs --write
Validate: node tools/menu-sources/redm-acquire.cjs validate
`;
  return { manifest, notes, previewProofs, exports };
}
if (require.main === module) {
  try {
    const result = build({ write: process.argv.includes('--write') });
    if (process.argv.includes('--write')) {
      for (const proof of result.previewProofs) write(proof.file, proof.value);
      write('project/community-menu-sources/redm.json', result.manifest);
      write(`${EVIDENCE}/README.md`, result.notes);
      const stagingFile = `${EVIDENCE}/export-staging.json`;
      const previous = exists(stagingFile) ? read(stagingFile).records || [] : [];
      const records = new Map(previous.map(row => [`${row.candidateId}:${row.sourceAttachmentId || row.previewEvidence}`, row]));
      for (const row of result.exports.privateRecords) records.set(`${row.candidateId}:${row.sourceAttachmentId || row.previewEvidence}`, row);
      write(stagingFile, { schema: 'redm-reviewed-export-staging-v1', privateEvidenceOnly: true, results: result.exports.results, records: [...records.values()] });
    }
    console.log(JSON.stringify({ write: process.argv.includes('--write'), ...result.manifest.summary, exportResults: result.exports.results, items: result.manifest.items.map(item => ({ id: item.id, name: item.name, files: item.files.length, previewVerified: item.previewVerified })) }, null, 2));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
module.exports = { build };
