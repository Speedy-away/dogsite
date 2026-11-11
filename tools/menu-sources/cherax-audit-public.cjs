'use strict';

// Read cached public metadata only. No mod payloads are fetched or executed.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const snapshotPath = path.join(root, 'project/community-marketplace/modverse.json');
const snapshot = JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));
const base = `https://raw.githubusercontent.com/${snapshot.repository}/${snapshot.revision}/`;
const themes = snapshot.catalogs.find(c => c.path === 'marketplace/themes/catalog.json');
const dlcs = snapshot.catalogs.find(c => c.path === 'marketplace/dlcs/catalog.json');

function counted(values) {
  return values.reduce((counts, value) => {
    counts[value || 'unspecified'] = (counts[value || 'unspecified'] || 0) + 1;
    return counts;
  }, {});
}

function evidence(catalog, item) {
  const isTheme = catalog === themes;
  const realPreview = isTheme && ['original_discord_screenshot', 'source_theme_artwork'].includes(item.thumbnail_kind);
  const thumbnailPath = item.thumbnail || `marketplace/dlcs/thumbnails/${item.id}.jpg`;
  const publisherThumbnail = item.thumbnail_url || base + thumbnailPath;
  return {
    id: item.id,
    name: item.name,
    category: isTheme ? 'themes' : 'dlcs',
    sourceChannel: isTheme ? 'theme-shares' : 'dlc-shares',
    sourceMenu: 'cherax',
    supportedMenus: ['cherax'],
    collection: 'unknown',
    collectionBasis: isTheme
      ? 'Publisher records source_archive_post=theme-shares. The current-versus-old identity of the channel ID has not been independently verified.'
      : 'Publisher records a source channel ID, but its current-versus-old channel identity has not been independently verified.',
    creator: item.creator,
    sharedBy: item.shared_by || null,
    creatorCreditBasis: item.creator_credit_basis || 'Creator field as supplied by publisher; no independent identity verification performed.',
    sourceChannelId: item.source_channel_id,
    sourceMessageId: item.source_message_id,
    sourceArchivePost: item.source_archive_post || null,
    sourceOriginalFilename: item.source_original_filename || item.source_original_file || null,
    sourceInternalPath: item.source_internal_path || null,
    sourceOriginalSha256: item.source_original_sha256 || item.source_sha256 || null,
    sourceCatalogPath: catalog.path,
    sourceCatalogUrl: catalog.url,
    sourceRevision: snapshot.revision,
    sourceCatalogUpdatedAt: catalog.data.updated_at || null,
    postDateText: item.post_date || null,
    postDateBasis: item.post_date ? 'Publisher-supplied source post timestamp; timezone unspecified.' : 'No verified post date in catalog; do not convert snowflake IDs into a claimed verified changelog date.',
    version: null,
    versionBasis: 'Catalog/metadata versions are schema versions and do not establish the package version.',
    changelog: [],
    changelogBasis: 'No verified per-package dated changelog in the inspected catalog.',
    preview: realPreview ? publisherThumbnail : null,
    previewKind: realPreview ? item.thumbnail_kind : null,
    publisherThumbnail,
    publisherThumbnailKind: item.thumbnail_kind || null,
    thumbnailListedInSnapshotTree: snapshot.paths.includes(thumbnailPath),
    thumbnailUrlVerification: 'URL recorded by publisher; no response body or image pixels independently inspected in this audit.',
    previewBasis: realPreview
      ? item.thumbnail_kind === 'source_theme_artwork' ? 'Included theme artwork, not an in-game screenshot.' : 'Publisher identifies this as the original Discord screenshot.'
      : isTheme ? 'Generated text placeholder omitted from the real preview field.' : 'Catalog cover omitted from the real preview field; original visual content is unverified.',
    compatibilityStatus: item.compatibility_status || catalog.data.compatibility_notice || 'unverified',
    compatibilityBasis: isTheme
      ? 'Cherax ClickGUI package. No evidence supports Scooby, Nenyoo, Stand or other-menu theme compatibility.'
      : 'Publisher reports an RPF7 OPEN header check, not live game compatibility or a verified Scooby/Nenyoo loader test.',
    permissionBasis: item.permission_basis || null,
    publisherFiles: item.files || [{
      name: item.filename,
      url: `https://github.com/${snapshot.repository}/releases/download/${item.release_tag}/${item.asset_name}`,
      sha256: item.sha256,
      size: item.size_bytes,
    }],
    tags: isTheme ? ['Cherax', 'ClickGUI', 'theme'] : ['Cherax', 'DLC', 'RPF7', 'in-game-unverified'],
    description: item.description || null,
  };
}

const audit = {
  schemaVersion: 1,
  auditedAt: '2026-11-11',
  menu: 'cherax',
  purpose: 'Bounded public-source evidence audit; this is not the final resource manifest or a claim of complete Discord coverage.',
  source: {
    localPath: 'project/community-marketplace/modverse.json',
    repository: snapshot.repository,
    revision: snapshot.revision,
    fetchedAt: snapshot.fetchedAt,
    pathCount: snapshot.paths.length,
    catalogCounts: snapshot.catalogs.map(c => ({ path: c.path, count: c.data.items.length })),
  },
  coverage: {
    themes: {
      inspectedEntries: themes.data.items.length,
      uniqueIds: new Set(themes.data.items.map(item => item.id)).size,
      previewKinds: counted(themes.data.items.map(item => item.thumbnail_kind)),
      entriesWithVerifiedPostDateText: themes.data.items.filter(item => item.post_date).length,
      entriesWithPackageVersion: 0,
      entriesWithDatedChangelog: 0,
      thumbnailsListedInSnapshotTree: themes.data.items.filter(item => snapshot.paths.includes(item.thumbnail)).length,
      channelIds: [...new Set(themes.data.items.map(item => item.source_channel_id))],
      sourceArchiveLabels: [...new Set(themes.data.items.map(item => item.source_archive_post))],
      archiveCoverage: 'Unknown. No theme-shares-old channel history inspected.',
    },
    dlcs: {
      inspectedEntries: dlcs.data.items.length,
      uniqueIds: new Set(dlcs.data.items.map(item => item.id)).size,
      previewKinds: counted(dlcs.data.items.map(item => item.thumbnail_kind)),
      entriesWithVerifiedPostDateText: 0,
      entriesWithPackageVersion: 0,
      entriesWithDatedChangelog: 0,
      channelIds: [...new Set(dlcs.data.items.map(item => item.source_channel_id))],
      archiveCoverage: 'Unknown. No dlc-shares-old channel history inspected.',
    },
    translations: { inspectedShareEntries: 0, status: 'No translation-share catalog or language payload was present in the 6010-path public snapshot. Related translator tool found, but it is not a translated language-file share.' },
    wallpapers: { inspectedShareEntries: 0, status: 'No wallpaper-share catalog or identified wallpaper payload was present in the 6010-path public snapshot. No current or old wallpaper Discord channel history inspected.' },
  },
  publicVerification: [
    {
      url: `https://github.com/${snapshot.repository}`,
      status: 'Public GitHub repository README read through web tool on 2026-11-11.',
      findings: 'README identifies a Cherax marketplace for outfits, vehicles, DLCs and ClickGUI themes; it separates uploader attribution from verified original creator identity and describes JSON/RPF installation destinations.',
      limitations: 'Web cache README reports 8 themes and no outfits/DLC bytes; the locally acquired pinned snapshot instead contains 196 themes, 2832 outfits and 15 DLCs. Use the pinned JSON for exact snapshot counts. Raw pinned catalog and main catalog web opens returned cache miss; independent direct Node fetch failed. No payloads were downloaded by this audit.',
    },
    {
      url: 'https://github.com/stefcee/-Cherax---Impulse-Lua-Translator-',
      status: 'Primary author README read through web tool on 2026-11-11.',
      name: 'Impulse Language Translator',
      author: 'Stefc3 / stefcee',
      version: '1.0',
      changelogDate: null,
      paraphrasedChangelog: 'Initial translator with nested JSON preservation, resumed translation via cache, selectable speeds and automatic update checks.',
      resourceType: 'Related translation authoring tool; not a Cherax menu translation share.',
      limitations: 'README compatibility statement concerns Impulse nested language JSON and Cherax Lua. It does not establish native Cherax menu language-file compatibility or support for other menus. No finished translation files or real preview were identified. Undated README changelog; release page unavailable through web cache.',
    },
  ],
  publicSearches: [
    'Cherax translation GitHub language json',
    'Cherax theme wallpaper github',
    '"Cherax" "translations" site:github.com',
    '"Cherax" "wallpaper" site:github.com',
    '"Cherax" "theme" site:github.com -Chillax -cherax-crayfish',
    '"Cherax" "translation-shares"',
  ],
  gaps: [
    'Current and old Discord share histories were not inspected in this public audit.',
    'No independent author identity checks beyond public README attribution and publisher catalog fields.',
    '36 theme thumbnails are generated labels; 15 DLC thumbnails are catalog covers. These are not real content previews.',
    'The snapshot tree lists no marketplace/themes paths although its cached catalogs include a theme catalog. Preserve the 196 publisher-supplied main-branch thumbnail URLs instead of inventing revision-pinned theme image URLs. URL availability and image pixels still require independent verification.',
    'All 15 DLC display names are publisher-generated uploader labels, not verified original asset titles; preserve original filenames/internal paths and avoid presenting those labels as actual vehicle/ped names.',
    'No package-version or dated-changelog evidence for the 211 inspected theme/DLC records.',
    'No verified translation or wallpaper share entries identified; no comprehensive web-wide coverage claimed.',
  ],
  items: [...themes.data.items.map(item => evidence(themes, item)), ...dlcs.data.items.map(item => evidence(dlcs, item))],
};

const output = path.join(root, 'project/community-menu-sources/cherax-public-audit.json');
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, JSON.stringify(audit, null, 2) + '\n');
console.log(JSON.stringify({ output: path.relative(root, output), counts: audit.coverage, items: audit.items.length }));
