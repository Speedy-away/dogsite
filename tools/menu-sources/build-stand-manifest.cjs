'use strict';

// Build source metadata only. Never evaluates Lua, fetches a mod, or changes the
// shared catalog. The main chat owns applying these explicit existing-record IDs.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const legacyInspector = require('./audit-stand-legacy.cjs');
const root = path.resolve(__dirname, '../..');
const destination = path.join(root, 'project/community-menu-sources');
const read = relative => JSON.parse(fs.readFileSync(path.join(root, relative), 'utf8'));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const date = '2026-11-11';
const sourceArchiveUrl = 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/ListUI/Themes/Stand';
const local = read('project/community-menu-sources/stand-local-audit.json');
const publicAudit = read('project/community-menu-sources/stand-public-audit.json');
const legacyAudit = read('project/community-menu-sources/stand-legacy-audit.json');
const library = read('community/data/library.json');
const libraryById = new Map(library.items.map(item => [item.id, item]));
const evidence = {
  localThemes: 'project/community-menu-sources/stand-local-audit.json',
  publicScripts: 'project/community-menu-sources/stand-public-audit.json',
  legacyData: 'project/community-menu-sources/stand-legacy-audit.json',
};
const policy = {
  lua: { downloadStatus: 'pending', files: [], visibleDiscordLinks: false },
  compatibility: 'Only explicit supportedMenus are integration instructions. Source format acceptance does not establish in-game appearance or every gameplay path.',
  originalShares: 'Current/Old Discord share histories were not inspected. Archival flags describe the retained source snapshot, never a verified Discord Old Shares assignment.',
};

const libraryOverrides = [];
for (const profile of local.profiles) {
  const match = profile.catalogMatches.find(value => value.game === 'gta5');
  if (!match || !libraryById.has(match.id)) throw Error(`Missing existing theme ${profile.profile}`);
  const item = libraryById.get(match.id);
  const preview = profile.authorPreviews.find(value => value.sourceUrl)?.sourceUrl;
  libraryOverrides.push({
    id: match.id, game: 'gta5', category: 'themes', name: item.name,
    sourceMenu: 'stand', supportedMenus: ['scooby', 'stand'],
    collection: 'archival', discordCollection: null,
    collectionBasis: 'Retained author theme snapshot inside checksum-pinned native Stand collections; Discord channel assignment unknown.',
    sourceUrl: profile.sourceUrl, sourcePath: profile.profile,
    sourceProvenance: [{ kind: 'local-author-snapshot', evidence: evidence.localThemes, archive: profile.archive, path: profile.profile }],
    version: null, versionBasis: 'No verified per-profile release version in this source snapshot.', changelog: [],
    tags: [...new Set([...item.tags, 'Stand profile', 'original Stand theme'])],
    ...(preview ? { preview, previewKind: 'author-preview', previewVerified: true } : { previewVerified: false }),
    compatibilityStatus: 'source-supported-native-theme',
    compatibility: 'Original Stand profile and supporting artwork. Stand: copy the theme folders into the Stand folder and load the profile. Scooby: use its native Stand ListUI collection loader and preserve archive paths. Nenyoo theme.lua conversions are separate packages.',
  });
}

const allInOne = local.summary.allinone[0];
for (const item of library.items.filter(item => item.game === 'gta5' && item.themePath?.startsWith(`${allInOne.path}#`))) {
  libraryOverrides.push({
    id: item.id, game: 'gta5', category: 'themes', name: item.name,
    sourceMenu: 'stand', supportedMenus: ['scooby', 'stand'], collection: 'archival', discordCollection: null,
    sourceUrl: sourceArchiveUrl, sourcePath: item.themePath,
    sourceProvenance: [{ kind: 'local-author-snapshot', evidence: evidence.localThemes, archive: allInOne.archive, path: allInOne.path }],
    creator: 'CocoW', version: '0.6.4', versionBasis: 'Version stated in the original Lua source header.', changelog: [],
    tags: [...new Set([...item.tags, 'CocoW', 'All-in-One'])],
    compatibilityStatus: 'source-supported-isolated-theme-runtime',
    compatibility: 'Requires original Stand or Scooby native Stand ListUI theme runtime. Isolated theme support does not establish compatibility for arbitrary Stand gameplay scripts. Nenyoo compatibility is not established.',
  });
}
for (const item of library.items.filter(item => item.game === 'gta5' && /^gta5-themes-stand-collection-\d+$/.test(item.id))) {
  libraryOverrides.push({
    id: item.id, game: 'gta5', category: 'themes', name: item.name,
    sourceMenu: 'stand', supportedMenus: ['scooby', 'stand'], collection: 'archival', discordCollection: null,
    sourceUrl: sourceArchiveUrl, sourceProvenance: [{ kind: 'checksum-pinned-local-archive', evidence: evidence.localThemes, file: item.files[0].name, sha256: item.files[0].sha256 }],
    version: null, versionBasis: 'Archive part numbers are not theme versions.', changelog: [],
    tags: item.tags,
    compatibility: 'Retains original Stand resources inside the Scooby native Stand archive layout. Scooby loads the full collection; original Stand users must install each theme/profile according to the author instructions. No blanket Nenyoo theme support is claimed.',
  });
}

// Public audit is intentionally a small normalized evidence input. New cards are
// always placeholders, even where an upstream public download happens to exist.
const publicRows = publicAudit.items || publicAudit.entries || publicAudit.scripts || [];
const items = publicRows.filter(item => item.category === 'lua' || !item.category).map((item, index) => ({
  ...item,
  id: item.id || `gta5-lua-stand-public-${index + 1}`,
  game: 'gta5', category: 'lua', sourceMenu: 'stand', supportedMenus: ['stand'],
  downloadStatus: 'pending', files: [],
  sourceUrl: item.sourceUrl || item.source?.sourceUrl || item.repositoryUrl,
  sourceProvenance: item.sourceProvenance || [{ ...item.source, evidence: evidence.publicScripts }],
  version: item.version ?? null,
  changelog: (item.changelog || []).map(change => ({ ...change, version: change.version ?? null, changes: change.changes || [change.summary] })),
  tags: [...new Set(['Stand', 'Lua', ...(item.tags || [])])],
  compatibility: item.compatibility || 'Requires the matching Stand Lua/Pluto APIs and script dependencies. Scooby/Nenyoo gameplay Lua compatibility has not been verified.',
}));
items.push({
  id: 'gta5-lua-stand-luatheme-all-in-one', game: 'gta5', category: 'lua', name: 'LuaTheme All-in-One Stand',
  description: 'CocoW’s retained Stand theme script with 31 nondefault theme choices.',
  creator: 'CocoW', sourceMenu: 'stand', supportedMenus: ['stand'], collection: 'archival', discordCollection: null,
  sourceUrl: sourceArchiveUrl,
  sourceProvenance: [{ kind: 'local-author-snapshot', evidence: evidence.localThemes, archive: allInOne.archive, path: allInOne.path }],
  version: '0.6.4', versionBasis: 'Original Lua source header; no verified release date.', changelog: [],
  tags: ['Stand', 'Lua', 'ListUI', 'themes', 'CocoW', 'All-in-One', 'archival'],
  downloadStatus: 'pending', files: [],
  compatibility: 'Original Stand script. The existing Scooby native Stand theme catalog exposes supported theme choices separately; gameplay Lua support is not implied.',
});

const legacyOverrides = [];
for (const family of ['vehicles', 'outfits']) {
  const { index, records } = legacyInspector.readSelected(family);
  records.forEach(record => {
    const recordIndex = record.index, format = record.format;
    if (!/^\.\/media\/[A-Za-z0-9_.-]+$/.test(record.localFile)) throw Error(`Unexpected media path ${record.localFile}`);
    const inspection = legacyInspector.inspectPayload(fs.readFileSync(path.join(root, 'community', record.localFile)), format, family);
    const disposition = legacyInspector.compatibility(family, inspection);
    // Accepted TXT signatures are directly implemented in both Stand adapters.
    // Other construct formats remain explicit review entries until matched to
    // their own converter; file extension or source folder alone is insufficient.
    const shared = disposition.disposition === 'format-eligible-with-limitations';
    const previewExists = Boolean(record.localPreview && fs.existsSync(path.join(root, 'community', record.localPreview)));
    legacyOverrides.push({
      family, index: recordIndex, id: `${family}-${recordIndex}`, name: record.name, category: family,
      sourceMenu: 'stand', supportedMenus: shared ? ['scooby', 'nenyoo', 'stand'] : ['stand'],
      collection: 'archival', discordCollection: null, format,
      sourceRevision: index.sourceRevision,
      sourcePath: record.sourcePath,
      sourceProvenance: [{ kind: 'existing-preset-index', evidence: evidence.legacyData, sourceCategory: 'ST512', indexPath: `community/data/${family}/index.json`, recordIndex }],
      version: null, changelog: [],
      ...(inspection.metadata?.author ? { creator: inspection.metadata.author } : {}),
      ...(inspection.metadata?.version ? { formatVersion: inspection.metadata.version } : {}),
      preview: previewExists ? `/community/${record.localPreview.replace(/^\.\//, '')}` : null,
      previewVerified: previewExists,
      tags: ['Stand', family, format, 'archival'],
      compatibilityStatus: shared ? 'source-accepted-format-not-runtime-tested' : 'requires-schema-specific-review',
      compatibility: disposition.reason,
    });
  });
}

const coverage = [
  { collection: 'local-theme-archives', category: 'themes', inspectedArchives: 11, payloadFiles: 8242, profileRecords: 75, allInOneNondefaultChoices: 31, existingLibraryOverrides: libraryOverrides.length, authorPreviews: 72, status: 'bounded-local-inventory-complete' },
  { collection: 'public-author-repositories', category: 'lua', inspectedEntries: items.length - 1, newPendingCards: items.length, status: 'bounded-public-source-audit', evidence: evidence.publicScripts },
  ...['vehicles', 'outfits'].map(family => ({ collection: 'existing-ST512-source-snapshot', category: family, records: legacyOverrides.filter(item => item.family === family).length, sharedFormatCandidates: legacyOverrides.filter(item => item.family === family && item.supportedMenus.includes('scooby')).length, status: 'local-static-format-audit', evidence: evidence.legacyData })),
  ...['Shares', 'Old Shares'].flatMap(collection => ['lua', 'legacy-lua', 'themes', 'outfits', 'vehicles', 'dlc', 'asi-mods', 'misc'].map(category => ({ collection, category, inspectedDiscordPosts: 0, status: 'not-inspected', reason: 'Discord Computer Use stopped by the user; no visible Stand share evidence supplied.' }))),
  { collection: 'BiggerScript Shares', category: 'vehicles/maps', inspectedDiscordPosts: 0, status: 'not-inspected', reason: 'No specific vehicle/map share payload was evidenced. Current author main is a Cherax launcher stub, so no Stand or map resource is inferred.' },
];

const output = {
  schemaVersion: 1, version: 1, menu: 'stand', sourceMenu: 'stand', auditedAt: date,
  purpose: 'Reviewable Stand resource metadata; the shared integration owns applying items, legacyOverrides, and libraryOverrides without duplicate cards.',
  summary: {
    pendingLuaCards: items.length, publicLuaSources: publicRows.length,
    luaCardsWithDatedChangelog: items.filter(item => item.changelog.some(change => /^\d{4}-\d{2}-\d{2}$/.test(change.date))).length,
    namedThemeProfiles: 75, allInOneThemeChoices: 31, themeArchiveParts: 11,
    existingThemeLibraryOverrides: libraryOverrides.length,
    legacyRecords: legacyOverrides.length,
    sharedFormatCandidates: legacyOverrides.filter(item => item.supportedMenus.includes('scooby')).length,
    reviewNeededRecords: legacyOverrides.filter(item => !item.supportedMenus.includes('scooby')).length,
    legacyPreviewsPresent: legacyOverrides.filter(item => item.previewVerified).length,
    legacyPreviewsMissing: legacyOverrides.filter(item => !item.previewVerified).length,
    inspectedDiscordPosts: 0,
  },
  policy, evidence, items, libraryOverrides, legacyOverrides, coverage,
  legacyDefaults: {
    compatibilityBasis: 'TXT payloads were statically inspected and both adapters accept Model plus named fields. Scooby and Nenyoo differ in named vehicle mod index handling; appearance parity and live acceptance are unverified.',
    formatReview: 'XML, INI and JSON construct data remain Stand-only in this manifest pending schema-specific converter checks, despite generic format support in some host loaders.',
    collectionBasis: 'Existing bundled source snapshot, generated 2025-11-15. This is not evidence of Discord Old Shares membership.',
    downloadPolicy: 'Keep existing resolved local/hosted files. This metadata does not synthesize new preset download URLs.',
  },
  exclusions: [
    'Previously removed broken Scooby Lua examples are not restored.',
    'Nenyoo converted theme.lua packages are not mislabeled as original Stand profiles.',
    'Brazil (Animated) native style resource is not attributed to Stand without author provenance.',
    'Repository versions and release versions are kept distinct; no unverified latest-version claims.',
  ],
  gaps: [
    'No full current or Old Shares Discord channel history was inspected; no claim of every share is made.',
    'No specific Stand custom DLC, ASI, misc, translation, or BiggerScript vehicle/map share payload acquired.',
    'Three ThemeRepo profiles lack exact named author previews: Discord v2, Japanese Chill, Standxo.',
    'No per-theme dated changelog or release version is verified, except the undated All-in-One source header version.',
    'Non-TXT legacy construct variants require schema-specific compatibility review before adding Scooby/Nenyoo support.',
    'Nine vehicle TXT records have sectioned or unrecognized signatures and are excluded from shared compatibility candidates.',
    '79 vehicle previews are absent locally; no image is invented or linked for those records.',
  ],
  inputs: ['community/data/library.json', 'community/data/vehicles/index.json', 'community/data/outfits/index.json'].map(relative => ({ path: relative, sha256: sha(fs.readFileSync(path.join(root, relative))) })),
};

if (new Set(items.map(item => item.id)).size !== items.length) throw Error('Duplicate new Stand IDs');
if (new Set(libraryOverrides.map(item => item.id)).size !== libraryOverrides.length) throw Error('Duplicate existing Stand theme IDs');
if (legacyOverrides.length !== legacyAudit.totalRecords) throw Error('Legacy source record count changed');
if (legacyOverrides.filter(item => item.supportedMenus.includes('scooby')).length !== legacyAudit.eligibleCandidateRecords) throw Error('Legacy compatibility count differs from the audit');
if (items.some(item => item.downloadStatus !== 'pending' || item.files.length || /discord(?:app)?\.(?:com|gg)/i.test(JSON.stringify(item)))) throw Error('Lua placeholder policy violated');
fs.mkdirSync(destination, { recursive: true });
const rendered = `${JSON.stringify(output, null, 2)}\n`;
const outputPath = path.join(destination, 'stand.json');
if (process.argv.includes('--check')) {
  if (!fs.existsSync(outputPath) || fs.readFileSync(outputPath, 'utf8') !== rendered) throw Error('Stand manifest differs; rebuild it before integration.');
} else fs.writeFileSync(outputPath, rendered);
console.log(JSON.stringify({ file: 'project/community-menu-sources/stand.json', items: items.length, libraryOverrides: libraryOverrides.length, legacyOverrides: legacyOverrides.length, legacyAudit: legacyAudit.summary || legacyAudit.coverage }, null, 2));
