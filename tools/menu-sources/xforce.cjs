#!/usr/bin/env node
'use strict';

// Audit X-Force's existing public/local resource packs without running their content.
// Writes are confined to project/community-menu-sources/xforce*.
// Usage: node tools/menu-sources/xforce.cjs [--write|--check] [--source-root DIR]
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const zlib = require('node:zlib');
const assert = require('node:assert/strict');
const { inspect: inspectDiscord } = require('./xforce-export.cjs');
const SITE = path.resolve(__dirname, '../..');
const OUTPUT = path.join(SITE, 'project/community-menu-sources');
const AUDITED_AT = '2026-11-11';
const args = process.argv.slice(2);
const sourceIndex = args.indexOf('--source-root');
const discordIndex = args.indexOf('--discord-dir');
if (discordIndex !== -1 && (!args[discordIndex + 1] || args[discordIndex + 1].startsWith('--'))) throw Error('--discord-dir needs a directory');
if (sourceIndex !== -1 && !args[sourceIndex + 1]) throw Error('--source-root needs a directory');
const SOURCE = path.resolve(sourceIndex === -1 ? path.dirname(SITE) : args[sourceIndex + 1]);
const PREFIX = 'Rendererrr.github.io/scooby/GTA5/ListUI/Themes/X-Force';
const SOURCE_URL = 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/ListUI/Themes/X-Force';
const ADAPTER = 'Scooby-Op/GTA5/EE/GTA - Main Src/src/core/frontend/ListUI/Styles/XForce/Adapter.inl';
const STYLE = 'Scooby-Op/GTA5/EE/GTA - Main Src/src/core/frontend/ListUI/Styles/XForce/XForce.hpp';
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const parse = value => JSON.parse(String(value).replace(/^\uFEFF/, ''));
const slug = value => value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const posix = value => value.split(path.sep).join('/');
const read = relative => fs.readFileSync(path.join(SOURCE, ...relative.split('/')));

function openZip(bytes) {
  let end = bytes.length - 22;
  const min = Math.max(0, bytes.length - 65558);
  for (; end >= min && bytes.readUInt32LE(end) !== 0x06054b50; end--);
  assert.ok(end >= min, 'ZIP end record missing');
  const count = bytes.readUInt16LE(end + 10), entries = [];
  let at = bytes.readUInt32LE(end + 16);
  for (let i = 0; i < count; i++) {
    assert.equal(bytes.readUInt32LE(at), 0x02014b50, 'ZIP central directory signature');
    const n = bytes.readUInt16LE(at + 28), extra = bytes.readUInt16LE(at + 30), comment = bytes.readUInt16LE(at + 32);
    const name = bytes.subarray(at + 46, at + 46 + n).toString('utf8');
    assert.ok(name && !name.startsWith('/') && !name.includes('\\') && !name.split('/').some(x => x === '..'), `Unsafe ZIP member ${name}`);
    assert.ok(bytes.readUInt32LE(at + 24) < 32 * 1024 * 1024, `Oversized member ${name}`);
    entries.push({ name, size: bytes.readUInt32LE(at + 24), compressed: bytes.readUInt32LE(at + 20), method: bytes.readUInt16LE(at + 10), offset: bytes.readUInt32LE(at + 42) });
    at += 46 + n + extra + comment;
  }
  return entries.map(entry => {
    assert.equal(bytes.readUInt32LE(entry.offset), 0x04034b50, 'ZIP local header signature');
    const start = entry.offset + 30 + bytes.readUInt16LE(entry.offset + 26) + bytes.readUInt16LE(entry.offset + 28);
    const packed = bytes.subarray(start, start + entry.compressed);
    const data = entry.method === 0 ? packed : entry.method === 8 ? zlib.inflateRawSync(packed, { maxOutputLength: 32 * 1024 * 1024 }) : null;
    assert.ok(data && data.length === entry.size, `Invalid ZIP member ${entry.name}`);
    return { name: entry.name, size: entry.size, sha256: sha(data), data };
  });
}

function build() {
  const plans = new Map();
  const plan = (relative, value) => {
    assert.ok(relative.startsWith('xforce/') || relative === 'xforce.json', 'Output outside X-Force scope');
    plans.set(relative, Buffer.isBuffer(value) ? value : Buffer.from(JSON.stringify(value, null, 2) + '\n'));
  };
  const catalog = parse(read(`${PREFIX}/packs.json`));
  const archives = catalog.packs.map(pack => {
    const data = read(`${PREFIX}/${pack.file}`);
    assert.equal(data.length, pack.bytes, `Archive size: ${pack.file}`);
    assert.equal(sha(data), pack.sha256, `Archive hash: ${pack.file}`);
    const members = openZip(data);
    const declared = parse(members.find(x => x.name === 'asset-manifest.json').data);
    assert.equal(declared.length, pack.files, `Declared file count: ${pack.file}`);
    assert.equal(members.length, declared.length + 1, `Archive file count: ${pack.file}`);
    for (const member of declared) {
      const actual = members.find(x => x.name === member.path);
      assert.ok(actual && actual.size === member.size && actual.sha256 === member.sha256, `Member hash: ${member.path}`);
    }
    return { ...pack, localSource: `${PREFIX}/${pack.file}`, members };
  });
  const selected = archives.find(x => x.file === 'ListUI-XForce-v6-All-02.zip');
  assert.ok(selected, 'Expected current local collection archive');
  const entries = selected.members.filter(x => x.name !== 'asset-manifest.json');
  const member = name => {
    const result = entries.find(x => x.name === name);
    assert.ok(result, `Missing archive member: ${name}`);
    return result;
  };
  const hostedPath = `downloads/shared/themes/x-force/${selected.file}`;
  assert.equal(sha(read(`cool-repo/${hostedPath}`)), selected.sha256, 'Existing download differs from inspected archive');
  const file = { path: hostedPath, name: selected.file, size: selected.bytes, sha256: selected.sha256 };
  const adapter = read(ADAPTER), style = read(STYLE);
  assert.ok(adapter.includes('LoadXForceTheme') && adapter.includes('.xf_cnfg') && adapter.includes('.ui'), 'Missing scoped native UI loader');
  assert.ok(style.includes('C:/scooby/GTA5/Themes/ListUI/X-Force v6'), 'Unexpected native install path');
  const items = [];
  function preview(entry, id) {
    if (!entry) return {};
    const relative = `xforce/previews/${id}${path.posix.extname(entry.name).toLowerCase()}`;
    plan(relative, entry.data);
    return { preview: `project/community-menu-sources/${relative}`, previewKind: 'artwork', previewCaption: 'Artwork included in the inspected collection; this is not a script or full-menu screenshot.' };
  }
  function base(id, name, sourceChannel, category, original, entry) {
    return {
      id: `gta5-xforce-${id}`, game: 'gta5', category, name, menu: 'X-Force', sourceMenu: 'X-Force',
      sourceChannel, supportedMenus: original ? ['Scooby'] : ['Scooby', 'X-Force'],
      supportedMenuVersions: original ? { Scooby: 'GTA5 builds with the native X-Force v6 ListUI adapter' } : { Scooby: 'GTA5 builds with the native X-Force v6 ListUI adapter', 'X-Force': 'Archived v6-era format only; current builds not verified' },
      version: null, sourceVersion: 'X-Force v6 collection', versionStatus: 'Individual author revision not supplied',
      collectionStatus: 'archival', archival: true, currentCollection: false,
      origin: original ? 'local-scooby-adaptation' : 'retained-v6-collection',
      credits: original ? 'Scooby local X-Force collection; generated artwork where noted' : 'Original author not identified in the retained collection; preserve supplied credits and dependencies',
      sourceUrl: SOURCE_URL,
      sourceProvenance: {
        type: 'checksum-verified-local-archive', sourceRepository: 'Rendererrr/Rendererrr.github.io',
        archive: selected.file, archiveSha256: selected.sha256, member: entry.name, memberSha256: entry.sha256,
        auditedAt: AUDITED_AT, originalAuthorVerified: false, discordMessageInspected: false,
        note: 'The mirror and local collection were inspected. The original Discord post, original publication date and current upstream release were not established.'
      },
      tags: ['gta5', 'x-force', 'v6', 'archival', sourceChannel, ...(original ? ['scooby-adaptation'] : [])],
      files: [file], status: 'download', downloadStatus: 'available',
      downloadScope: 'Complete existing collection ZIP; retain original directories and dependencies',
      license: 'No general redistribution license was established by this audit; the existing collection is referenced without creating another archive.',
      changelog: [], changelogStatus: 'No dated author changelog found; audit observations are not release notes.'
    };
  }
  const uiFiles = entries.filter(x => /\.(ui|xf_cnfg)$/i.test(x.name));
  const duplicateAliases = [];
  const seen = new Map();
  const headerForUI = new Map();
  const headerSpecs = [
    ['breaking-bad', 'Breaking-Bad.jpg', 'Collection/themes/Breaking_Bad/Breaking-Bad.jpg'],
    ['standforce', 'StandForce.png', 'Collection/themes/StandForce/header/StandForce.png'],
    ['anom-original', 'Anom_Original.png', 'Collection/themes/anom/Anom_Original.png'],
    ['astolfo-pink', 'pink.png', 'Collection/themes/astolfo_config/pink.png'],
    ['dark-force', 'Xforce_gif.gif', 'Collection/themes/dark-force/Xforce_gif.gif'],
    ['black', 'x-force_1_2.gif', 'Collection/themes/dark/x-force_1_2.gif'],
    ['die', 'x-force_1.gif', 'Collection/themes/die/x-force_1.gif'],
    ...['935Z83T', 'HLUGC5b', 'L8gr8yT', 'helluva', 'n97KwAG'].map(n => [slug(n), `${n}.png`, `Collection/headers/${n}.png`]),
    ['nyan', 'nyan.gif', 'Collection/headers/nyan.gif'],
    ['lsd-lucid', 'lsd-lucid.png', 'Collection/Originals/headers/lsd-lucid.png'],
    ['space-nebula', 'space-nebula.png', 'Collection/Originals/headers/space-nebula.png']
  ];
  const headerArt = new Map();
  for (const [id, name, relative] of headerSpecs) {
    const entry = member(`X-Force v6/${relative}`), original = relative.startsWith('Collection/Originals/');
    const fields = preview(entry, `header-${id}`);
    headerArt.set(entry.name, fields);
    const alternatives = relative.endsWith('.png') ? entries.filter(x => x.name === entry.name.replace(/\.png$/, '.webp')) : [];
    items.push({
      ...base(`header-${id}`, name, 'custom-header', 'themes', original, entry),
      resourceType: 'custom-header', uiStyle: 'ListUI', style: 'X-Force',
      description: `Included ${/\.gif$/i.test(name) ? 'animated GIF' : 'image'} header artwork. Select the X-Force style and load the image through its header controls.`,
      ...fields, previewVerified: !original, tags: ['gta5', 'themes', 'x-force', 'listui', 'header', /\.gif$/i.test(name) ? 'animated' : 'image', ...(original ? ['scooby-adaptation', 'generated-artwork'] : ['archival'])],
      assetPaths: [entry.name, ...alternatives.map(x => x.name)],
      compatibility: 'Scooby GTA5 native X-Force ListUI image loader verified in source. Retained upstream images are v6-era resources. Nenyoo, RDR2 and other menu support was not established.',
      ...(original ? { artworkOrigin: 'Generated artwork recorded in the local xforce-v6-original-artwork.json; not an original Discord release' } : {}),
      guide: '/resources/guides/?game=gta5&category=themes'
    });
  }
  for (const entry of uiFiles) {
    if (seen.has(entry.sha256)) {
      const first = seen.get(entry.sha256);
      first.aliases = [...(first.aliases || []), path.posix.basename(entry.name)];
      first.assetPaths.push(entry.name);
      duplicateAliases.push({ member: entry.name, canonicalItem: first.id, aliasExistingLibraryId: `gta5-themes-preset-x-force-${sha(entry.name).slice(0, 14)}`, sha256: entry.sha256 });
      continue;
    }
    const config = parse(entry.data);
    assert.ok(config.ui_settings && typeof config.ui_settings === 'object', `Not a UI preset: ${entry.name}`);
    const original = entry.name.includes('/Collection/Originals/');
    const stem = path.posix.basename(entry.name).replace(/\.(ui|xf_cnfg)$/i, '');
    const name = stem === '' ? 'Default' : stem.trim();
    const id = `ui-${sha(entry.name).slice(0, 14)}`;
    let art;
    const settings = config.ui_settings;
    const custom = settings.header?.custom_name;
    if (custom && custom !== 'null') art = entries.find(x => x.name.startsWith(path.posix.dirname(entry.name).replace(/\/ui$/, '') + '/') && path.posix.basename(x.name).toLowerCase() === String(custom).toLowerCase());
    if (!art) {
      const folder = entry.name.includes('/StandForce/') ? 'Collection/themes/StandForce/header/' : posix(path.posix.dirname(entry.name)).replace(/^X-Force v6\//, '') + '/';
      art = entries.find(x => x.name.startsWith(`X-Force v6/${folder}`) && /\.(png|jpg|gif)$/i.test(x.name) && (!original || x.name.endsWith(`/${stem}.png`)));
    }
    if (!art && original) art = entries.find(x => x.name === `X-Force v6/Collection/Originals/headers/${stem}.png`);
    if (!art && (!custom || custom === 'null')) {
      const builtins = ['greenp.png', 'green.png', 'starwars.png', 'doge.png', 'pepe.png', 'ela.png', 'iana.png', 'purple.png', 'blue.png', 'white.png', 'loading.png', 'neo.gif'];
      const builtin = settings.header?.type === 2 ? 'neo.gif' : builtins[Math.min(11, Math.max(0, Number(settings.header?.image_index || 0)))];
      art = entries.find(x => x.name === `X-Force v6/builtin/${builtin}`);
    }
    const image = art && (headerArt.get(art.name) || preview(art, id));
    const item = {
      ...base(id, name, 'ui-configs', 'themes', original, entry),
      id: `gta5-themes-preset-x-force-${sha(entry.name).slice(0, 14)}`, themePath: entry.name,
      resourceType: 'ui-config', categories: ['themes', 'configs'], uiStyle: 'ListUI', style: 'X-Force',
      description: `Named ${path.posix.extname(entry.name)} UI preset retained in the X-Force v6 collection. Keep its supplied header and fonts with the preset.`,
      ...(image ? { ...image, previewVerified: !original } : {}), tags: ['gta5', 'themes', 'configs', 'x-force', 'listui', name, 'archival', ...(original ? ['scooby-adaptation'] : [])],
      assetPaths: [entry.name], sourceFormat: `JSON ui_settings serialized as ${path.posix.extname(entry.name)}`,
      compatibility: 'Scooby GTA5 native X-Force .ui/.xf_cnfg loader verified in source. Original v6-format requirements remain version-scoped; Nenyoo, RDR2 and current upstream X-Force builds were not verified.',
      requirements: ['Scooby GTA5 with the native X-Force v6 ListUI style, or the original version-scoped host for retained upstream presets', 'Install the whole pack into C:/scooby/GTA5/Themes/ListUI; preserve X-Force v6 subfolders', 'Keep bundled fonts and matching image artwork with each preset'],
      guide: '/resources/guides/?game=gta5&category=themes'
    };
    if (art) headerForUI.set(entry.name, art.name);
    seen.set(entry.sha256, item);
    items.push(item);
  }
  const publicFile = path.join(OUTPUT, 'xforce/public-lua-candidates.json');
  const publicEvidence = fs.existsSync(publicFile) ? parse(fs.readFileSync(publicFile)) : { items: [], sources: [] };
  for (const resource of publicEvidence.items || []) {
    assert.equal(resource.sourceMenu, 'X-Force');
    assert.equal(resource.category, 'lua');
    assert.equal(resource.downloadStatus, 'pending');
    assert.deepEqual(resource.files, []);
    assert.ok(!/discord\.(?:com|gg)/i.test(resource.sourceUrl || ''), 'Lua cards must not expose Discord links');
    assert.deepEqual(resource.supportedMenus, ['X-Force'], 'Lua API compatibility must remain native');
    items.push({ menu: 'X-Force', sourceChannel: 'public-author-lua', archival: resource.collectionStatus === 'archival', currentCollection: resource.collectionStatus === 'current', ...resource });
  }
  const exportRecord = 'xforce/discord-export-import.json';
  const previousExport = fs.existsSync(path.join(OUTPUT, exportRecord)) ? parse(fs.readFileSync(path.join(OUTPUT, exportRecord))) : null;
  let exported = previousExport;
  if (discordIndex !== -1) {
    const pinned = items.map(item => item.sourceProvenance?.memberSha256).filter(Boolean);
    const result = inspectDiscord(args[discordIndex + 1], pinned);
    const reviewed = new Set(result.coverage.map(channel => channel.channelId));
    const missing = (previousExport?.coverage || []).filter(channel => !reviewed.has(channel.channelId));
    assert.equal(missing.length, 0, 'Input is missing a previously inspected export. Preserve all imported channels when refreshing.');
    if (result.coverage.length) {
      exported = { items: result.items, coverage: result.coverage, audit: result.audit };
      for (const [relative, bytes] of result.plans) plan(relative, bytes);
      plan(exportRecord, exported);
    } else {
      throw Error('No completed X-Force media exports are readable yet. ' + JSON.stringify(result.audit.skipped));
    }
  }
  if (exported) items.push(...exported.items);
  const inspectedMessages = (exported?.coverage || []).reduce((total, entry) => total + entry.inspectedDiscordMessages, 0);
  const channels = ['ui-configs', 'custom-header', 'asi-scripts', 'outfits', 'translations', 'custom-dlc-addons', 'xml-vehicles', 'xml-maps', 'misc-files'];
  const coverage = channels.map(channel => ({
    channel, inspectedDiscordMessages: (exported?.coverage || []).filter(entry => entry.channel === channel).reduce((total, entry) => total + entry.inspectedDiscordMessages, 0),
    resourceCount: items.filter(x => x.sourceChannel === channel).length,
    status: ['ui-configs', 'custom-header'].includes(channel) ? 'local-archival-collection-inspected' : 'acquisition-gap',
    gap: exported ? 'No completed X-Force export was inspected for this channel.' : 'No X-Force Discord channel evidence was available to this worker. Channel history and its current downloadable attachments were not inspected.'
  })).map(row => exported?.coverage.some(entry => entry.channel === row.channel) ? {
    ...row,
    status: 'user-supplied-export-inspected',
    gap: 'Coverage is limited to the supplied export and its saved attachments.',
    exportCount: exported.coverage.filter(entry => entry.channel === row.channel).length
  } : row);
  const support = entries.filter(x => /\.(ttf|otf|wav|txt)$/i.test(x.name));
  const manifest = {
    schemaVersion: 1, sourceMenu: 'X-Force', auditedAt: AUDITED_AT,
    downloadBaseUrl: 'https://raw.githubusercontent.com/Speedy-away/cool-repo/main/',
    scope: 'Reviewable source manifest only; shared library/importer/UI not modified',
    completeness: exported ? 'Partial. Coverage includes the completed Discord exports listed below, three local v6 archives and public author sources.' : 'Partial. Three local v6 archives and the listed public author resources were inspected. This is not every X-Force share.',
    coverage,
    summary: {
      totalResources: items.length, newResourceRecords: items.filter(x => x.resourceType !== 'ui-config').length,
      existingLibraryOverrides: seen.size, uniqueLocalUIConfigs: seen.size, localUIFiles: uiFiles.length,
      duplicateUIAliases: duplicateAliases.length, localCustomHeaders: headerSpecs.length,
      localScoobyAdaptationUIConfigs: items.filter(x => x.resourceType === 'ui-config' && x.origin === 'local-scooby-adaptation').length,
      localScoobyGeneratedHeaders: items.filter(x => x.resourceType === 'custom-header' && x.origin === 'local-scooby-adaptation').length,
      publicLuaPlaceholders: (publicEvidence.items || []).length, inspectedDiscordMessages: inspectedMessages,
      ...(exported ? { importedDiscordRecords: exported.items.length, inspectedDiscordExports: exported.coverage.length } : {}),
      inspectedArchiveMembersIncludingManifests: archives.reduce((n, x) => n + x.members.length, 0),
      latestLocalArchiveAssetMembers: entries.length
    },
    policy: {
      luaDownloads: 'All Lua entries remain pending with files:[]; no working URL is exposed by a Download button.',
      luaCompatibility: 'Source-menu Lua API is required. No cross-menu support is inferred.',
      compatibleData: 'Compatibility is recorded per format. Discord import records identify their original menu and file format. Cross-menu support requires additional evidence.',
      uiCompatibility: 'Only the inspected native Scooby GTA5 X-Force v6 adapter is established. Local adaptations do not imply original-menu support.',
      previouslyExcludedBrokenLua: 'No removed or broken local Lua example is reintroduced.',
      yim: 'Explicitly deferred'
    },
    sources: [
      { id: 'xforce-local-v6-packs', type: 'local-archive-mirror', sourceUrl: SOURCE_URL, upstreamCurrentReleaseVerified: false, localSource: `${PREFIX}/packs.json`, archives: archives.map(({ members, ...pack }) => pack) },
      { id: 'scooby-gta5-native-xforce-adapter', type: 'local-source-code', files: [{ path: ADAPTER, sha256: sha(adapter) }, { path: STYLE, sha256: sha(style) }], claims: ['.ui and .xf_cnfg loading', 'PNG/JPG/JPEG/GIF/BMP header formats', 'GTA5-specific install path'] },
      ...[...new Set((publicEvidence.items || []).map(x => x.repositoryUrl))].map(repositoryUrl => ({ type: 'public-author-repository', sourceUrl: repositoryUrl, revisions: [...new Set(publicEvidence.items.filter(x => x.repositoryUrl === repositoryUrl).map(x => x.revision))], evidenceFile: 'project/community-menu-sources/xforce/public-source-responses.json' })),
      ...(publicEvidence.sources || [])
    ],
    officialMenuReference: publicEvidence.officialMenuReference || null,
    ...(exported ? { discordExportEvidence: 'project/community-menu-sources/' + exportRecord } : {}),
    evidenceNotes: ['project/community-menu-sources/xforce/README.md', 'project/community-menu-sources/xforce/public-research.md', 'project/community-menu-sources/xforce/local-inventory.json', 'project/community-menu-sources/xforce/public-source-responses.json'],
    supportingAssets: support.map(({ data, ...x }) => ({ ...x, role: /\.(ttf|otf)$/i.test(x.name) ? 'font-dependency' : /\.wav$/i.test(x.name) ? 'bundled-sound' : 'package-instructions', exposedAsIndependentCard: false })),
    duplicateAliases,
    libraryOverrides: items.filter(x => x.resourceType === 'ui-config'),
    items: items.filter(x => x.resourceType !== 'ui-config')
  };
  const ids = items.map(x => x.id);
  assert.equal(new Set(ids).size, ids.length, 'Duplicate resource IDs');
  plan('xforce/local-inventory.json', {
    auditedAt: AUDITED_AT,
    archives: archives.map(({ members, ...archive }) => ({ ...archive, members: members.map(({ data, ...entry }) => entry) })),
    headerForUI: Object.fromEntries(headerForUI), duplicateAliases,
    note: 'ZIP timestamps are normalized by the source packager and were not treated as publication dates.'
  });
  plan('xforce.json', manifest);
  return { plans, manifest };
}

const { plans, manifest } = build();
if (args.includes('--write')) {
  for (const [relative, bytes] of plans) {
    const target = path.join(OUTPUT, ...relative.split('/'));
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, bytes);
  }
} else if (args.includes('--check')) {
  for (const [relative, bytes] of plans) assert.ok(fs.existsSync(path.join(OUTPUT, relative)) && fs.readFileSync(path.join(OUTPUT, relative)).equals(bytes), `Outdated output: ${relative}`);
}
process.stdout.write(JSON.stringify({ mode: args.includes('--write') ? 'write' : args.includes('--check') ? 'check' : 'audit-only', ...manifest.summary, coverage: manifest.coverage.map(({ channel, resourceCount, status }) => ({ channel, resourceCount, status })), outputFiles: plans.size }, null, 2) + '\n');
