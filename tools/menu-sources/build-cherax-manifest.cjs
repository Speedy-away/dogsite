'use strict';

// Deterministic metadata assembly only. Does not fetch, execute Lua, publish,
// mutate the main library, or control Discord. --check performs no writes.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const folder = 'project/community-menu-sources/';
const read = relative => JSON.parse(fs.readFileSync(path.join(root, relative), 'utf8'));
const sha = data => crypto.createHash('sha256').update(data).digest('hex');
const snapshot = read('project/community-marketplace/modverse.json');
const lua = read(folder + 'cherax-lua-audit.json');
const dataAudit = read(folder + 'cherax-data-audit.json');
const publicAudit = read(folder + 'cherax-public-audit.json');
const network = read(folder + 'cherax-network-checks.json');
const vehiclePreviews = read(folder + 'cherax-evidence/vehicle-preview-probes.json');
const registry = read(folder + 'cherax-export-channels.json');
const library = read('community/data/library.json');
const existing = new Map(library.items.map(item => [item.id, item]));
const paths = new Set(snapshot.paths);
const checks = new Map(network.entries.map(item => [item.id, item]));
const publicRows = new Map(publicAudit.items.map(item => [item.id, item]));
const vehicleSamples = new Map(vehiclePreviews.map(item => [item.id, item]));
const probes = new Map(dataAudit.sampleProbes.samples.map(item => [item.id, item]));
assert.equal(registry.guild?.name, 'Cherax');
assert.equal(registry.channels.length, 13);
assert.equal(new Set(registry.channels.map(channel => channel.id)).size, 13);
const channelsById = new Map(registry.channels.map(channel => [channel.id, channel]));
const raw = `https://raw.githubusercontent.com/${snapshot.repository}/${snapshot.revision}/`;
const repo = `https://github.com/${snapshot.repository}`;
const evidence = {
  lua: folder + 'cherax-lua-audit.json', data: folder + 'cherax-data-audit.json',
  public: folder + 'cherax-public-audit.json', network: folder + 'cherax-network-checks.json',
  channels: folder + 'cherax-evidence/user-channel-list.png',
  vehiclePreviews: folder + 'cherax-evidence/vehicle-preview-probes.json',
  channelRegistry: folder + 'cherax-export-channels.json',
};
const clean = value => typeof value === 'string' ? value.replace(/[\u0000-\u001f\u007f]/g, ' ').trim() : '';
const unique = values => [...new Set(values.filter(Boolean))];
const items = lua.items.map(item => ({
  ...item, sourceMenu: 'Cherax', supportedMenus: ['Cherax'],
  sourceFilename: path.posix.basename(item.provenance.localPaths[0].path),
  format: 'Cherax Lua', sourceFormat: 'Cherax Lua', formatExtension: 'lua',
  collection: 'unknown', collectionStatus: 'unclassified', discordCollection: null,
  collectionBasis: 'Local filenames and source folders do not establish current or old Discord channel membership. Individual old-path copies are labelled archival in provenance.',
  requirementLabel: 'Requires Cherax Lua API',
  requirements: ['Matching Cherax Lua host and GTA edition/build', 'Script-specific libraries, assets and author instructions'],
  sourceUrl: item.provenance.authorSource?.url || undefined,
  sourceProvenance: [{ kind: 'metadata-only-local-lua-audit', evidence: evidence.lua, itemId: item.id, ...item.provenance }],
  downloadStatus: 'pending', status: 'pending', files: [],
  preview: null, previewVerified: false,
  compatibilityLevel: 'original-host-requirement-only', runtimeVerified: false,
}));
const libraryOverrides = [], exclusions = [...lua.exclusions];

function localPreview(file, expectedSha) {
  assert.ok(file.startsWith(folder), 'Preview outside source folder');
  const absolute = path.resolve(root, file);
  assert.ok(absolute.startsWith(path.resolve(root, folder) + path.sep), 'Preview escaped source folder');
  const bytes = fs.readFileSync(absolute);
  if (expectedSha) assert.equal(sha(bytes), expectedSha, 'Preview checksum changed: ' + file);
  return file;
}
function previewFor(kind, row) {
  if (kind === 'themes') {
    const verified = checks.get(row.id)?.preview;
    if (verified && ['original_discord_screenshot','source_theme_artwork'].includes(verified.kind)) return {
      preview: localPreview(verified.localPath, verified.sha256), previewVerified: true, previewKind: verified.kind,
      previewVerificationLevel: 'downloaded-original-source-image-with-sha256',
      previewCaption: verified.kind === 'source_theme_artwork' ? 'Original theme artwork' : 'Original Cherax screenshot',
    };
    return { preview: null, previewVerified: false, previewKind: row.thumbnail_kind || null,
      previewVerificationLevel: 'generated-cover-omitted' };
  }
  const candidates = [row.thumbnail, ...['jpg','png','webp'].map(ext => `marketplace/${kind}/thumbnails/${row.id}.${ext}`), `${row.id}.jpg`].filter(Boolean);
  const matched = candidates.find(candidate => paths.has(candidate));
  const candidateUrl = row.thumbnail_url || (matched ? raw + matched : null);
  if (kind === 'vehicles' && vehicleSamples.has(row.id)) {
    const sample = vehicleSamples.get(row.id);
    return { preview: localPreview(sample.localPath), previewVerified: true,
      previewKind: 'sampled-source-vehicle-image', previewVerificationLevel: 'saved-source-image-sample',
      previewCaption: 'Original source vehicle image', sourcePreviewUrl: sample.url };
  }
  if (row.thumbnail_kind === 'source_image' && candidateUrl) return {
    preview: candidateUrl, sourcePreviewUrl: candidateUrl, previewVerified: false, previewKind: 'source_image',
    previewVerificationLevel: 'publisher-source-image-classification-and-snapshot-path',
    previewVerification: 'Publisher classifies this as a source image; exact thumbnail path is present in the pinned tree. Image bytes and pixels were not individually inspected by this audit.',
  };
  if (kind === 'vehicles') return { preview: candidateUrl, previewVerified: false, previewKind: 'unclassified-source-thumbnail',
    sourcePreviewUrl: candidateUrl, previewVerificationLevel: 'snapshot-path-proven-content-uninspected',
    previewVerification: 'No thumbnail_kind supplied. Three sampled images were inspected separately; classification is not extrapolated to all vehicle thumbnails.' };
  return { preview: null, previewVerified: false, previewKind: row.thumbnail_kind || null,
    previewVerificationLevel: 'generated-or-unclassified-cover-omitted' };
}
function dlcName(row) {
  const internal = (row.source_internal_path || '').split('/').filter(Boolean);
  const original = clean(row.source_original_file);
  // A source folder/archive basename is evidence; a generic dlc.rpf is not a title.
  if (internal.length > 1 && internal[0].toLowerCase() !== 'dlc') return { name: internal[0], nameBasis: 'Original archive internal folder name; publisher display name preserved separately.' };
  if (original && !/^dlc\.rpf$/i.test(original)) return { name: original.replace(/\.(?:zip|rar|7z|rpf)$/i, ''), nameBasis: 'Original source archive basename; publisher display name preserved separately.' };
  return { name: clean(row.name), nameBasis: 'Publisher display name; source filename dlc.rpf supplies no specific resource name.' };
}
for (const catalog of snapshot.catalogs) {
  const kind = catalog.path.split('/')[1];
  assert.ok(['themes','vehicles','outfits','dlcs'].includes(kind));
  for (const row of catalog.data.items) {
    if (!clean(row.name)) { exclusions.push({ id: row.id, catalog: catalog.path, reason: 'Empty source display name; no invented replacement.' }); continue; }
    const id = `gta5-modverse-${kind}-${row.id}`;
    const category = kind === 'dlcs' ? 'dlc' : kind;
    const sharedData = kind === 'vehicles' || kind === 'outfits';
    const sourceCategory = {themes:'theme-shares',vehicles:'json-vehicles',outfits:'outfit-shares',dlcs:'dlc-shares'}[kind];
    // Only an explicit publisher channel ID may bind a source row to the
    // reviewed registry. A sourceId prefix is never treated as a channel ID.
    const registeredChannel = row.source_channel_id ? channelsById.get(row.source_channel_id) : null;
    if (registeredChannel) assert.equal(registeredChannel.name.replace(/-old$/, ''), sourceCategory, 'Catalog category differs from the exact registered channel');
    const archival = registeredChannel?.collection === 'archival';
    const collection = registeredChannel ? (archival ? 'old' : 'current') : 'unknown';
    const format = {themes:'Cherax ClickGUI theme package',vehicles:'Cherax vehicle JSON',outfits:'Cherax outfit JSON',dlcs:'RPF7 addon package'}[kind];
    const possible = [`marketplace/${kind}/files/${row.id}.json`, `marketplace/${kind}/files/${row.filename}`];
    const filePath = possible.find(candidate => paths.has(candidate));
    let files;
    if (kind === 'themes') {
      const verified = checks.get(row.id);
      assert.ok(verified?.complete && verified.files.length, 'Theme network verification missing: ' + row.id);
      assert.ok(verified.files.every(file=>file.verified), 'Unverified theme download: ' + row.id);
      files = verified.files.map(file => ({ url:file.url, name:file.name, size:file.size,
        downloadMethod:'direct', availabilityVerification:'HTTP HEAD 200 with non-HTML content type; payload hash not independently checked' }));
    } else {
      const url = row.download_url || (row.release_tag && row.asset_name ? `${repo}/releases/download/${encodeURIComponent(row.release_tag)}/${encodeURIComponent(row.asset_name)}` : filePath ? raw + filePath : null);
      assert.ok(url, 'Missing verified source path: ' + id);
      files = [{ url, name:row.filename || row.asset_name }];
      // Seven sampled outfit bodies do not match the publisher byte claims.
      // Only actual previously saved probe hashes belong on a served-file record.
      const probe = probes.get(row.id);
      if (probe?.status === 200 && probe.url === url) Object.assign(files[0], { size:probe.bytes, sha256:probe.sha256, verification:'Saved public served-byte probe' });
    }
    const named = kind === 'dlcs' ? dlcName(row) : {name:clean(row.name),nameBasis:'Exact nonempty publisher display name.'};
    const sourceUrl = kind === 'themes' ? catalog.url : filePath ? `${repo}/blob/${snapshot.revision}/${filePath}` : `${repo}/releases/tag/${encodeURIComponent(row.release_tag)}`;
    const common = {
      id, game:'gta5', category, ...named, publisherName:row.name,
      sourceMenu:'Cherax', supportedMenus:sharedData?['Scooby','Nenyoo','Cherax']:['Cherax'],
      description: kind === 'themes' ? (clean(row.description) || 'Cherax ClickGUI theme package with original settings and supplied artwork.') : `${format} from the pinned ModVerse source catalog.`,
      sourceCategory, sourceChannel:registeredChannel?.name || null, sourceChannelId:row.source_channel_id || null,
      sourceMessageId:row.source_message_id || row.source_post_id || null,
      sourceArchivePost:row.source_archive_post || null, sourceUrl, source:'ModVerse public catalog',
      publisherArchiveLabel:row.source_archive_post || null, sourceType:row.source_type || null,
      sourceFilename:row.source_original_filename || row.source_original_file || row.filename || null,
      sourceInternalPath:row.source_internal_path || null,
      collection, collectionStatus:registeredChannel ? (archival ? 'archival' : 'current') : 'unclassified', discordCollection:registeredChannel ? collection : null,
      collectionBasis:registeredChannel ? 'Exact publisher source_channel_id matched the reviewed official CLI channel registry. The original publisher archive label is retained separately; post dates are not used to infer collection identity.' : 'No explicit publisher source_channel_id matches the reviewed registry. SourceId prefixes, filenames and post dates are not used to infer channel or collection identity.',
      creator:row.creator || 'Original developer unverified', sharedBy:row.shared_by || null,
      creatorCreditBasis:row.creator_credit_basis || 'Publisher creator field; author identity not independently established.',
      credits:unique([row.creator, row.shared_by && row.shared_by !== row.creator ? 'shared by '+row.shared_by : null]).join('; '),
      tags:unique(['Cherax','ModVerse',kind,format,row.creator,row.shared_by,row.model&&String(row.model),kind==='themes'?'ClickGUI':null,...(archival?['old shares','archival']:[])]),
      version:null, versionBasis:'No verified resource release version supplied; catalog and metadata schema versions are not package versions.',
      changelog:[], changelogBasis:'No verified per-resource dated changelog supplied. Share dates and catalog update dates remain source timestamps.',
      sourcePostDateText:row.post_date || null, sourcePostDateBasis:row.post_date?'Publisher-supplied share timestamp; timezone unspecified.':null,
      sourceCatalogUpdatedAt:catalog.data.updated_at || null,
      format, sourceFormat:format, formatExtension:sharedData?'json':kind==='dlcs'?'rpf':null,
      downloadStatus:'available', status:'download', files,
      publisherChecksum:kind==='themes'?{ files:(row.files||[]).map(f=>({name:f.asset_name,sha256:f.sha256,size:f.size_bytes})),verification:'Publisher metadata; downloaded payload bodies not independently hashed.' }:{sha256:row.sha256,size:row.size_bytes,verification:'Publisher claim; see actual served-byte sample hashes separately.'},
      permissionBasis:row.permission_basis || catalog.data.license_policy || 'Source author terms apply.',
      license:'Original author terms apply; metadata links retain the original publisher file locations.',
      model:row.model ?? null, sourceCompatibility:row.compatibility_status || null,
      runtimeVerified:false,
      compatibilityLevel:sharedData?'source_importer_support':kind==='themes'?'original-host-package-requirement':'conditional-loader-candidate',
      compatibility:sharedData ? dataAudit.compatibility.basis : kind==='themes' ? 'Original Cherax ClickGUI package. Scooby, Nenyoo and Stand theme compatibility is not established.' : 'Publisher reports an RPF7 OPEN header check. Package contents, GTA edition and runtime loading remain unverified; conditional Scooby/Nenyoo importer candidates are recorded separately.',
      ...(sharedData ? {compatibilityLimitations:dataAudit.compatibility.limitations, compatibilityEvidence:evidence.data} : kind==='dlcs'?{candidateMenus:['Scooby','Nenyoo'],compatibilityEvidence:evidence.data,edition:'unverified'}:{}),
      requirements:sharedData?['Matching Cherax JSON resource importer','Intended vehicle/character model and edition-compatible resources']:kind==='themes'?['Cherax ClickGUI theme loader','Preserve the complete package and supplied artwork']:['Edition-compatible addon loader','Inspect the package and follow its original instructions'],
      ...previewFor(kind,row),
      sourceProvenance:[{kind:'pinned-public-catalog',repository:snapshot.repository,revision:snapshot.revision,catalog:catalog.path,catalogUrl:catalog.url,sourceId:row.id,
        sourceOriginalFile:row.source_original_file || null,sourceInternalPath:row.source_internal_path || null,sourceOriginalSha256:row.source_original_sha256 || row.source_sha256 || null,
        evidence:sharedData?evidence.data:evidence.public}],
    };
    if (registeredChannel) common.sourceProvenance.push({kind:'exact-source-channel-id-registry-match',evidence:evidence.channelRegistry,guildId:registry.guild.id,channelId:registeredChannel.id,channelName:registeredChannel.name,collection:registeredChannel.collection});
    if(kind==='themes') {
      const pub=publicRows.get(row.id);
      assert.ok(pub, 'Theme missing public audit row');
      common.uiStyle='ClickUI'; common.requirementLabel='Requires Cherax ClickGUI format';
      common.sourceProvenance.push({kind:'public-availability-and-original-preview-check',evidence:evidence.network,sourceId:row.id});
      items.push(common);
    } else {
      assert.ok(existing.has(id), 'Expected exact existing library ID: '+id);
      libraryOverrides.push(common);
    }
  }
}
const categoryCounts = values => values.reduce((counts,item)=>(counts[item.category]=(counts[item.category]||0)+1,counts),{});
const all = [...items,...libraryOverrides];
const channels = [
  ['lua-scripts','lua','current'],['outfit-shares','outfits','current'],['dlc-shares','dlc','current'],
  ['theme-shares','themes','current'],['json-vehicles','vehicles','current'],['translation-shares','languages','current'],['cherax-wallpaper','wallpapers','current'],
  ['outfit-shares-old','outfits','old'],['dlc-shares-old','dlc','old'],['cherax-wallpaper-old','wallpapers','old'],
  ['json-vehicles-old','vehicles','old'],['translation-shares-old','languages','old'],['theme-shares-old','themes','old'],
];
const coverage=channels.map(([channel,category,collection])=>{
  const entry=registry.channels.find(value=>value.name===channel);
  assert.ok(entry, 'Expected channel absent from reviewed registry: '+channel);
  const bound=all.filter(item=>item.sourceChannelId===entry.id&&item.sourceChannel===entry.name).length;
  return {channel,channelId:entry.id,guildId:registry.guild.id,category,collection,
    channelVisible:true,visibilityEvidence:evidence.channels,channelRegistryEvidence:evidence.channelRegistry,channelIdentityVerified:true,
    historyStatus:'incomplete',fullHistoryInspected:false,postsInspectedInThisManifestBuild:0,boundedSourceRecords:bound,
    sourceRecordsBoundToThisExactChannel:bound>0,
    reason:bound?'Exact publisher source channel IDs bind these bounded snapshot records to the reviewed channel. This does not establish complete history; the in-progress CLI export is not consumed by this build.':'The reviewed registry establishes this channel identity, but this bounded manifest has no source records explicitly bound to its ID. The in-progress CLI export is not consumed by this build.'};
});
const result={
  schemaVersion:1,version:1,menu:'Cherax',sourceMenu:'Cherax',auditedAt:'2026-11-11',
  purpose:'Reviewable Cherax source manifest. New items and exact-ID library overrides retain evidence without duplicating existing ModVerse resources.',
  completeness:'Bounded local/public source audit with exact current/old channel IDs verified through the official CLI registry. All 13 channel histories remain incomplete until the authorized export is finished and inspected.',
  summary:{newItems:items.length,libraryOverrides:libraryOverrides.length,totalRepresentedResources:all.length,
    resourcesByCategory:categoryCounts(all),newItemsByCategory:categoryCounts(items),overridesByCategory:categoryCounts(libraryOverrides),
    pendingLuaCards:items.filter(x=>x.category==='lua').length,luaWithDatedChangelog:items.filter(x=>x.category==='lua'&&x.changelog.length).length,
    verifiedThemeDownloadLinks:items.filter(x=>x.category==='themes').flatMap(x=>x.files).length,
    downloadedOriginalThemePreviews:items.filter(x=>x.category==='themes'&&x.previewVerified).length,
    publisherClassifiedOutfitSourceImages:libraryOverrides.filter(x=>x.category==='outfits'&&x.previewKind==='source_image').length,
    independentlySavedVehiclePreviewSamples:libraryOverrides.filter(x=>x.category==='vehicles'&&x.previewVerified).length,
    unclassifiedVehicleThumbnailPaths:libraryOverrides.filter(x=>x.category==='vehicles'&&!x.previewVerified&&x.sourcePreviewUrl).length,
    visibleShareChannels:coverage.length,currentShareChannels:7,oldShareChannels:6,fullChannelHistoriesInspected:0,
    excludedEmptyOutfitNames:exclusions.filter(x=>x.reason.startsWith('Empty source display')).length,
    sourceDataPayloadSamples:dataAudit.sampleProbes.samples.length,
    authoritativeChannelRegistryMatchedRecords:all.filter(item=>item.collectionStatus==='archival'||item.collectionStatus==='current').length,
    sourceRecordCollections:{archival:all.filter(item=>item.collectionStatus==='archival').length,current:all.filter(item=>item.collectionStatus==='current').length,unclassified:all.filter(item=>item.collectionStatus==='unclassified').length},
  },
  policy:{lua:{downloadStatus:'pending',files:[],visibleDiscordLinks:false},
    compatibility:'Vehicle/outfit support denotes matching importer source formats with runtimeVerified:false. It does not extend to Lua, themes, translations or edition-unverified DLC.',
    previews:'Original source screenshots/artwork/source_image only. Source classification, saved-byte verification and uninspected path candidates are labelled separately. Generated title covers are omitted.',
    collection:'Collection assignment requires an explicit source_channel_id matched to the reviewed official CLI registry. Original publisher archive labels remain separate. No inference from sourceId prefixes, timestamps or filenames.'},
  evidence,items,libraryOverrides,legacyOverrides:[],coverage,exclusions,
  gaps:unique([...lua.acquisitionGaps.map(value=>value.startsWith('Current and old Discord Lua channels')?'The 47 local Lua entries are not bound to a verified source-channel export. The current Lua channel history remains incomplete; no old Lua channel is inferred.':value),...dataAudit.acquisitionGaps.filter(value=>!value.startsWith('Current forum channels and -old text-channel mapping')),...publicAudit.gaps,
    'No finished translation-share or wallpaper-share entry was acquired; all four corresponding current/old channel histories remain incomplete.',
    'Vehicle previews: three saved image samples, 117 remaining thumbnail paths with unclassified image content. No global screenshot-provenance claim.',
    '869 named outfit thumbnails are publisher-classified source images with tree membership; these URLs remain unverified preview candidates pending independent image-byte/content checks. One additional source_image record has an empty name and is excluded.',
    '36 theme label thumbnails, 1962 named-outfit generated covers and all 15 DLC generated covers are omitted from real preview fields.',
    'All DLC packages remain Cherax-only supported entries; source-level Scooby/Nenyoo loader candidates are separate until package/edition inspection.',
    'The reviewed registry maps 3161 publisher records to old-share channel IDs. One direct creator vehicle submission without a source_channel_id remains unclassified, alongside the 47 local Lua entries.',
    'This build does not ingest an in-progress CLI export. Rebuild after the authorized export has finished and its evidence has been independently reviewed.']),
  integrationNotes:[
    'Import items and libraryOverrides by exact ID; do not append new copies of existing ModVerse vehicle/outfit/DLC cards.',
    'Replace older fallback filename-only Cherax Lua cards and blanket compatibility labels with this manifest; these 47 cards include only explicit original Cherax host requirements.',
    'Overrides with preview:null and previewVerified:false intentionally clear inherited generated base.preview values. A normalizer that drops null/false must explicitly remove those inherited images.',
    'Preserve sourceProvenance, compatibilityLevel, runtimeVerified, previewVerificationLevel and publisherChecksum distinction in review evidence even if the public payload is compact.',
    'No lua-scripts-old channel is visible in the supplied screenshot; do not fabricate that coverage row.',
  ],
  inputs:['project/community-marketplace/modverse.json',evidence.lua,evidence.data,evidence.public,evidence.network,evidence.vehiclePreviews,evidence.channels,evidence.channelRegistry]
    .map(relative=>({path:relative,sha256:sha(fs.readFileSync(path.join(root,relative)))})),
};

// Meaningful cross-input invariants; no game scripts are executed.
assert.deepEqual(result.summary.resourcesByCategory,{lua:47,themes:196,dlc:15,outfits:2831,vehicles:120});
assert.equal(new Set(all.map(x=>x.id)).size,all.length);
assert.equal(result.summary.downloadedOriginalThemePreviews,160);
assert.equal(result.summary.publisherClassifiedOutfitSourceImages,869);
assert.equal(result.summary.independentlySavedVehiclePreviewSamples,3);
assert.equal(result.summary.visibleShareChannels,13);
assert.deepEqual(result.summary.sourceRecordCollections,{archival:3161,current:0,unclassified:48});
assert.equal(coverage.filter(entry=>entry.collection==='current').reduce((sum,entry)=>sum+entry.boundedSourceRecords,0),0);
assert.equal(coverage.filter(entry=>entry.collection==='old').reduce((sum,entry)=>sum+entry.boundedSourceRecords,0),3161);
for(const item of all){
  assert.ok(item.name && item.sourceMenu==='Cherax');
  assert.ok(item.sourceProvenance.length);
  if(item.category==='lua'){
    assert.equal(item.downloadStatus,'pending');assert.deepEqual(item.files,[]);assert.deepEqual(item.supportedMenus,['Cherax']);
    assert.ok(!/https?:\/\/[^\s"']*discord(?:app)?\.(?:com|gg)/i.test(JSON.stringify(item)));
  }
  if(['themes','dlc'].includes(item.category))assert.deepEqual(item.supportedMenus,['Cherax']);
  if(['vehicles','outfits'].includes(item.category)){assert.deepEqual(item.supportedMenus,['Scooby','Nenyoo','Cherax']);assert.equal(item.runtimeVerified,false);}
  if(item.previewVerified)assert.ok(item.preview && !/generated|catalog_cover/.test(item.previewKind));
  if(item.category!=='lua'){assert.equal(item.version,null);assert.deepEqual(item.changelog,[]);}
  if(item.sourceType==='direct_creator_submission'&&!item.sourceChannelId){assert.equal(item.collectionStatus,'unclassified');assert.equal(item.sourceChannel,null);}
  for(const release of item.changelog)assert.match(release.date,/^\d{4}-\d{2}-\d{2}$/);
}
assert.ok(!coverage.some(x=>x.channel==='lua-scripts-old'));
const publicationPath = folder + 'cherax-publication.json';
if (fs.existsSync(path.join(root, publicationPath))) {
  const publication = read(publicationPath);
  assert.match(publication.coolRepoCommit, /^[a-f0-9]{40}$/);
  assert.equal(publication.menu, 'Cherax');
  const byId = new Map(all.map(item => [item.id, item]));
  for (const { id, ...changes } of publication.updates) {
    const item = byId.get(id);
    if (item) Object.assign(item, changes);
  }
  for (const item of publication.items) {
    assert.equal(item.sourceMenu, 'Cherax');
    assert.ok(!byId.has(item.id), 'Duplicate published Cherax item: ' + item.id);
    if (item.category === 'lua') {
      assert.equal(item.downloadStatus, 'pending');
      assert.deepEqual(item.files, []);
      assert.equal(item.showSourceLink, false);
    }
    items.push(item);
    byId.set(item.id, item);
  }
  result.summary.newItems = items.length;
  result.summary.newItemsByCategory = categoryCounts(items);
  result.summary.totalRepresentedResources = byId.size;
  const represented = [...byId.values()];
  result.summary.resourcesByCategory = categoryCounts(represented);
  result.summary.pendingLuaCards = items.filter(item => item.category === 'lua').length;
  result.summary.luaWithDatedChangelog = items.filter(item => item.category === 'lua' && item.changelog.length).length;
  result.summary.sourceRecordCollections = {
    archival: represented.filter(item => item.collectionStatus === 'archival').length,
    current: represented.filter(item => item.collectionStatus === 'current').length,
    unclassified: represented.filter(item => !['archival', 'current'].includes(item.collectionStatus)).length,
  };
  result.summary.authoritativeChannelRegistryMatchedRecords = result.summary.sourceRecordCollections.archival + result.summary.sourceRecordCollections.current;
  result.summary.publishedAcquisitions = publication.summary;
  if (publication.exportCoverage) {
    const { exports, threads, messages, channels } = publication.exportCoverage;
    const byChannel = new Map(channels.map(channel => [channel.channelId, channel]));
    for (const channel of coverage) {
      const exported = byChannel.get(channel.channelId);
      assert.ok(exported, 'Completed export coverage is missing ' + channel.channel);
      delete channel.fullHistoryInspected;
      channel.historyStatus = 'accessible-export-complete';
      channel.accessibleHistoryInspected = true;
      channel.postsInspectedInThisManifestBuild = exported.messages;
      channel.exportedThreads = exported.threads;
      channel.reason = 'The completed exporter run supplied the accessible history for this channel.';
    }
    delete result.summary.fullChannelHistoriesInspected;
    result.summary.accessibleChannelHistoriesInspected = channels.length;
    result.summary.exportedThreads = threads;
    result.summary.exportedMessages = messages;
    result.completeness = `The selected Discord export supplied ${messages} messages across ${threads} accessible forum threads and ${exports - threads} historical channels.`;
    const replaced = [
      'The 47 local Lua entries are not bound to a verified source-channel export.',
      'Current and old Discord share histories were not inspected in this public audit.',
      'No verified translation or wallpaper share entries identified',
      'No finished translation-share or wallpaper-share entry was acquired',
      'This build does not ingest an in-progress CLI export.',
    ];
    result.gaps = result.gaps.filter(gap => !replaced.some(prefix => gap.startsWith(prefix)));
    result.gaps.push(...(publication.acquisitionGaps || []).map(({ name, reason }) => `${name} — ${reason}`));
  } else {
    result.completeness += ' Published Cherax acquisitions: ' + publication.coverage;
  }
  result.evidence.publication = publicationPath;
  result.inputs.push({ path: publicationPath, sha256: sha(fs.readFileSync(path.join(root, publicationPath))) });
}
const serialized=JSON.stringify(result,null,2)+'\n';
const output=path.join(root,folder+'cherax.json');
if(process.argv.includes('--check'))assert.equal(fs.readFileSync(output,'utf8'),serialized,'Manifest is stale; rebuild it.');
else fs.writeFileSync(output,serialized);
console.log(JSON.stringify({mode:process.argv.includes('--check')?'check':'build',path:folder+'cherax.json',bytes:Buffer.byteLength(serialized),sha256:sha(serialized),summary:result.summary},null,2));
