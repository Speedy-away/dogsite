'use strict';

// Offline evidence report only. Reads explicit catalogs and importer source files;
// never loads preset data into a game or executes Lua. Does not edit the library.
// Usage: node tools/menu-sources/audit-cherax-data.cjs
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const site = path.resolve(__dirname, '../..');
const sources = path.join(site, 'project/community-menu-sources');
const github = path.dirname(site);
const snapshotPath = 'project/community-marketplace/modverse.json';
const snapshotBytes = fs.readFileSync(path.join(site, snapshotPath));
const snapshot = JSON.parse(snapshotBytes);
const library = JSON.parse(fs.readFileSync(path.join(site, 'community/data/library.json')));
const libraryIds = new Set(library.items.map(item => item.id));
const probes = JSON.parse(fs.readFileSync(path.join(sources, 'cherax-data-sample-probes.json')));
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const countBy = (items, get) => items.reduce((out, item) => {
  const key = String(get(item) ?? 'unspecified');
  out[key] = (out[key] || 0) + 1;
  return out;
}, {});
const catalogs = snapshot.catalogs.filter(catalog => /^marketplace\/(vehicles|outfits)\//.test(catalog.path));
const rows = catalogs.flatMap(catalog => catalog.data.items.map(item => ({ catalog, item, kind: catalog.path.split('/')[1] })));
const named = rows.filter(({ item }) => String(item.name || '').trim());
const paths = new Set(snapshot.paths);
const raw = `https://raw.githubusercontent.com/${snapshot.repository}/${snapshot.revision}/`;
const sourceRoot = 'Scooby-Op/GTA5/EE/GTA - Main Src/';
const nenyooRoot = 'project-native-gui/GTAV/';

function evidence(repositoryPath, claims) {
  const absolutePath = path.join(github, repositoryPath);
  if (!fs.existsSync(absolutePath)) return { repositoryPath, available: false };
  const bytes = fs.readFileSync(absolutePath);
  const lines = bytes.toString('utf8').split(/\r?\n/);
  return {
    repositoryPath, absolutePath, available: true, sha256: hash(bytes),
    claims: claims.map(([needle, claim]) => {
      const index = lines.findIndex(line => line.includes(needle));
      return { line: index < 0 ? null : index + 1, matched: index >= 0, claim };
    }),
  };
}

function mappedResource(catalog, item, kind) {
  const file = [`marketplace/${kind}/files/${item.id}.json`, `marketplace/${kind}/files/${item.filename}`].find(value => paths.has(value));
  const thumbnail = [item.thumbnail, ...['jpg', 'png', 'webp'].map(ext => `marketplace/${kind}/thumbnails/${item.id}.${ext}`), `${item.id}.jpg`]
    .filter(Boolean).find(value => paths.has(value));
  return {
    id: `gta5-modverse-${kind}-${item.id}`, name: item.name, category: kind,
    sourceCategory: kind === 'vehicles' ? 'json-vehicles' : 'outfit-shares',
    existingLibraryEntry: libraryIds.has(`gta5-modverse-${kind}-${item.id}`),
    sourceCatalog: catalog.path,
    fileUrl: file ? raw + file : null,
    fileName: item.filename,
    sourceChannelId: item.source_channel_id || null,
    sourceMessageId: item.source_message_id || null,
    sourceChannelName: null,
    channelCollectionStatus: 'unverified_from_catalog_metadata',
    sourceThumbnailUrl: item.thumbnail_url || (thumbnail ? raw + thumbnail : null),
    thumbnailKind: item.thumbnail_kind || 'unspecified',
    preview: item.thumbnail_kind === 'source_image' ? (item.thumbnail_url || (thumbnail ? raw + thumbnail : null)) : null,
    catalogCover: item.thumbnail_kind === 'catalog_cover' ? (item.thumbnail_url || (thumbnail ? raw + thumbnail : null)) : null,
    publisherCompatibilityStatus: item.compatibility_status || null,
    publisherSha256: item.sha256, publisherSize: item.size_bytes,
  };
}

const sourceEvidence = [
  evidence(sourceRoot + 'src/game/backend/SavedVehicles.cpp', [
    ['bool SavedVehicles::IsCheraxFormat', 'Scooby recognizes the Cherax Entity format marker.'],
    ['void ApplyCheraxVehicleDetails', 'Scooby applies named Cherax vehicle settings, mods, colours, extras and other supported fields.'],
    ['Vehicle SavedVehicles::SpawnFromCheraxJson(', 'Scooby spawns the model and applies Cherax vehicle data and attachments.'],
  ]),
  evidence(sourceRoot + 'src/game/frontend/submenus/OtherMenus/other-menus-outfits/cheraxOutfit.cpp', [
    ['nlohmann::json NormalizeJsonOutfit', 'Scooby normalizes model plus named/array component and prop objects.'],
    ['Stand::Outfits::ComponentSlotForName(key)', 'Scooby resolves Cherax named components through its Stand component-name map.'],
    ['void ApplyNormalizedOutfit', 'Scooby applies normalized clothing and props; this does not establish full appearance fidelity.'],
  ]),
  evidence(sourceRoot + 'src/game/frontend/submenus/OtherMenus/Stand/StandOutfits.cpp', [
    ['int ComponentSlotForName', 'The shared component map used by Cherax import maps Hands to slot 3, alongside Torso; this differs from the Cherax slot-5 Hands mapping in Nenyoo.'],
    ['int PropSlotForName', 'Scooby resolves named Cherax props, including Hip, through a shared map.'],
  ]),
  evidence(nenyooRoot + 'src/spooner/preset_loader.cpp', [
    ['Hash json_model(', 'Nenyoo accepts model/hash keys used by Cherax presets.'],
    ['void apply_cherax(', 'Nenyoo applies Cherax vehicle mods, extras, colours, plates, tyres and neon settings.'],
    ['bool load_vehicle_json(', 'Nenyoo routes supported vehicle JSON to the matching vehicle handler.'],
    ['bool load_outfit_json(', 'Nenyoo accepts Cherax named components and props, arrays, and other supported outfit structures.'],
    ['XOR_STATIC("Head"),XOR_STATIC("Beard")', 'Nenyoo named-component ordering places Torso at slot 3 and Hands at slot 5.'],
    ['XOR_STATIC("Head"),XOR_STATIC("Eyes")', 'Nenyoo named props include slots 0 through 7; the Hip key is not handled in that branch.'],
    ['rfind(XOR("feature").c_str(), 0) == 0', 'Nenyoo face-feature parsing expects feature-prefixed numeric keys; the sampled Cherax data uses named facial keys.'],
  ]),
  evidence(sourceRoot + 'src/game/features/addons/AddonArchive.cpp', [
    ['Use an unencrypted OpenIV OPEN-format RPF7 add-on.', 'Scooby requires an RPF7 archive with an OPEN key. Header compatibility alone does not verify the contained pack.'],
  ]),
  evidence(sourceRoot + 'src/game/features/addons/AddonCatalog.cpp', [
    ['Enter the full path of an add-on folder or dlc.rpf.', 'Scooby accepts an add-on folder or dlc.rpf.'],
    ['The pack edition could not be detected.', 'Scooby rejects unverified pack edition rather than assuming Legacy/Enhanced compatibility.'],
    ['Enhanced add-ons cannot be loaded in Legacy.', 'Scooby enforces edition compatibility during pack import.'],
  ]),
  evidence(nenyooRoot + 'src/features/dlc_library.cpp', [
    ['Downloaded mods often nest the ready-made pack', 'Nenyoo discovers dlc.rpf folders in imported packages and selects the running edition branch.'],
    ['A Legacy OPEN dlc.rpf dropped while playing Enhanced', 'Nenyoo has a conversion path for Legacy OPEN RPF packages; it does not imply every package converts.'],
  ]),
  evidence(nenyooRoot + 'src/features/custom_dlc_mgr.cpp', [
    ['Not loaded: some of this pack', 'Nenyoo refuses packs containing remaining incompatible Legacy model files when conversion fails.'],
  ]),
];

const report = {
  schemaVersion: 1,
  menu: 'Cherax',
  auditedAt: new Date().toISOString(),
  scope: 'Offline vehicle/outfit catalog audit with nine previously acquired public JSON samples and explicit local importer source evidence. No Discord UI access, game execution, Lua execution or shared importer/library writes.',
  snapshot: {
    path: snapshotPath, sha256: hash(snapshotBytes), repository: snapshot.repository,
    revision: snapshot.revision, fetchedAt: snapshot.fetchedAt,
  },
  coverage: {
    catalogFilesInspected: catalogs.length,
    catalogEntriesInspected: rows.length,
    namedCandidates: named.length,
    namedCandidatesAlreadyInMainLibrary: named.filter(({ item, kind }) => libraryIds.has(`gta5-modverse-${kind}-${item.id}`)).length,
    sourcePayloadsIndividuallyInspected: probes.samples.filter(sample => sample.status === 200 && sample.content).length,
    distinctCatalogIds: new Set(rows.map(({ item }) => item.id)).size,
    distinctPublisherHashes: new Set(rows.map(({ item }) => item.sha256)).size,
    excludedEmptyNames: rows.filter(({ item }) => !String(item.name || '').trim()).map(({ catalog, item }) => ({ id: item.id, catalog: catalog.path, reason: 'Source display name is empty; not converted into an invented resource name.' })),
  },
  catalogs: catalogs.map(catalog => ({
    path: catalog.path, url: catalog.url, catalogVersion: catalog.data.catalog_version,
    updatedAt: catalog.data.updated_at || null,
    entries: catalog.data.items.length,
    namedEntries: catalog.data.items.filter(item => String(item.name || '').trim()).length,
    sourceChannelCounts: countBy(catalog.data.items, item => item.source_channel_id),
    sourceChannelNames: 'Not established by this catalog. Bind IDs to visible channel evidence separately; do not infer old/current from message date.',
    publisherCompatibilityCounts: countBy(catalog.data.items, item => item.compatibility_status),
    thumbnailKindCounts: countBy(catalog.data.items, item => item.thumbnail_kind),
    missingPublicFilePaths: catalog.data.items.filter(item => !paths.has(`marketplace/${catalog.path.split('/')[1]}/files/${item.id}.json`)).map(item => item.id),
  })),
  compatibility: {
    suggestedSupportedMenus: ['Scooby', 'Nenyoo', 'Cherax'],
    categories: ['vehicles', 'outfits'],
    level: 'source_importer_support',
    runtimeVerified: false,
    basis: 'The user states Cherax vehicle/outfit data works in Scooby and Nenyoo, and both local source trees expose matching JSON format importers. Nine public JSON samples match those general structures. This is not an individual game test of all catalog entries.',
    publisherStatusInterpretation: {
      user_confirmed_in_game: 'Publisher statement about the source preset; target menu/build and test conditions are not established here.',
      format_and_sha256_verified_only: 'Publisher format/integrity claim; runtime unverified.',
      'Cherax_outfit_structure_verified; in_game_unverified': 'Publisher structure check; runtime unverified.',
      unspecified: 'No publisher compatibility status; the vehicle catalog includes one direct creator submission in this state.',
    },
    limitations: [
      'Scooby Cherax outfit normalization currently resolves the named Hands component to slot 3 via StandOutfits; Nenyoo uses slot 5. Clothing fidelity can differ.',
      'Scooby normalized outfit application passes palette 0 and handles clothing/props; complete Cherax appearance fields are not established by this path.',
      'Nenyoo named-prop import handles slots 0..7 and omits Hip; named Cherax face_features are not the featureN keys read in its face-feature branch.',
      'Nenyoo vehicle apply_cherax handles a subset of Cherax vehicle fields; Scooby and Nenyoo may differ in attachment and cosmetic fidelity.',
      'Model availability, clothing indices and DLC resources depend on the installed GTA edition/build.',
      'No compatibility extension to Lua, themes or translations is inferred from these data importers.',
    ],
    dlc: {
      sourceImporterSupport: ['Scooby', 'Nenyoo'],
      individualPackagesVerified: false,
      runtimeVerified: false,
      publisherStatus: 'RPF7_OPEN_header_verified; in_game_unverified',
      recommendation: 'Keep the 15 ModVerse DLC packages as conditional importer candidates until their archive TOC, actual resources and edition are inspected. Source support for RPF7 OPEN does not prove each package works.',
    },
  },
  sourceEvidence,
  fieldMapping: {
    id: 'gta5-modverse-{vehicles|outfits}-{item.id}',
    name: 'Exact nonempty item.name; blank-name items remain excluded.',
    category: { vehicles: 'vehicles', outfits: 'outfits' },
    sourceCategory: { vehicles: 'json-vehicles', outfits: 'outfit-shares' },
    sourceMenu: 'Cherax',
    fileUrl: `https://raw.githubusercontent.com/${snapshot.repository}/${snapshot.revision}/marketplace/{kind}/files/{item.id}.json (require exact path membership in snapshot.paths)`,
    publicSourceUrl: `https://github.com/${snapshot.repository}/blob/${snapshot.revision}/marketplace/{kind}/files/{item.id}.json`,
    preview: 'thumbnail_kind=source_image only; require exact file path membership or publisher thumbnail_url.',
    catalogCover: 'thumbnail_kind=catalog_cover; do not misrepresent a generated title cover as an asset preview.',
    unclassifiedThumbnail: 'All 120 vehicle thumbnail kinds are unspecified in publisher metadata. They remain candidates for separate visual evidence; do not label screenshot provenance from the missing field.',
    credits: 'Keep creator and shared_by distinct, including Original developer unverified.',
    tags: ['gta5', 'Cherax', 'ModVerse', '{kind}', '{format}', '{creator}', '{shared_by}', '{model when present}'],
    version: 'Resource version absent. catalog_version is only a catalog version; do not present it as an asset release version.',
    changelog: 'No per-resource changelog supplied by these vehicle/outfit catalogs. Keep an empty list. updated_at describes the catalog, and post_date describes a share rather than a release changelog.',
    checksum: 'Keep item.sha256/size_bytes under publisherChecksum until served bytes are independently checked. Seven sampled outfit downloads differ from the publisher byte claims.',
    collection: 'Pinned public collection snapshot. Current/-old Discord channel identity is not established by catalog ID/date alone.',
  },
  sampleProbes: {
    path: 'project/community-menu-sources/cherax-data-sample-probes.json', checkedAt: probes.checkedAt,
    samples: probes.samples.map(sample => ({
      id: sample.id, name: sample.name, catalog: sample.catalog, url: sample.url, status: sample.status,
      sha256: sample.sha256, bytes: sample.bytes, publisherSha256: sample.publisherSha256, publisherBytes: sample.publisherBytes,
      publisherChecksumMatchesServedBytes: sample.sha256 === sample.publisherSha256,
      format: sample.content?.format, type: sample.content?.type, model: sample.content?.model, keys: sample.keys,
    })),
    checksumCaution: 'Seven sampled outfits are 129 bytes smaller than the publisher size and have different hashes. A formatting/line-ending transformation is plausible but not proven by the saved parsed-content probes; do not claim verified normalization.',
  },
  exampleCandidates: catalogs.map(catalog => mappedResource(catalog, catalog.data.items.find(item => item.name?.trim()), catalog.path.split('/')[1])),
  acquisitionGaps: [
    'The catalog contains 2,832 outfits and 120 vehicles. Only nine actual payloads were read in this audit; do not claim all source payloads or all Discord shares were inspected.',
    'Current forum channels and -old text-channel mapping require visible Discord evidence or an explicit export manifest; never infer that mapping from dates.',
    'Source-image outfit previews number 870 across all catalog records (869 among named candidates); 1,962 other outfit thumbnails are generated catalog covers.',
    'Vehicle thumbnails have no thumbnail_kind metadata. Real screenshot provenance needs separate evidence.',
    'The 15 DLC payloads were not acquired or installed in this audit; only publisher metadata and local importer capabilities were inspected.',
    'Game runtime, exact target build support and complete cross-menu appearance fidelity were not tested.',
    'Original creator identity remains unverified for most catalog entries; uploader credit is preserved separately.',
  ],
};

for (const source of sourceEvidence) {
  if (source.available && source.claims.some(claim => !claim.matched)) {
    throw new Error(`Source evidence locator no longer matches: ${source.repositoryPath}`);
  }
}
fs.mkdirSync(sources, { recursive: true });
const output = path.join(sources, 'cherax-data-audit.json');
fs.writeFileSync(output, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ output: path.relative(site, output), coverage: report.coverage }, null, 2));
