'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const menus = require('../resources/menus.js');

const root = path.resolve(__dirname, '..');
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const siteData = file => read(path.join(root, file));
const fields = ['id', 'category', 'name', 'description', 'sourceFilename', 'sourceFormat', 'format', 'formatExtension',
  'collection', 'collectionStatus', 'sourceChannel', 'version', 'versionBasis', 'changelog', 'changelogStatus',
  'compatibility', 'requirementLabel', 'requirements', 'previewKind', 'previewCaption', 'tags', 'model', 'modelLabel'];
const luaName = name => String(name || '').toLowerCase().replace(/\.lua$/, '').replace(/\s+v?\d+(?:\.\d+)+\s*$/, '').replace(/[^a-z0-9]+/g, '');
const fileIdentity = ({ category, files }) => files?.length && files.every(file => file.sha256)
  ? `${category}:${files.map(file => file.sha256).sort().join(',')}` : '';

function build(manifestPath, repo) {
  const manifest = read(manifestPath);
  const publication = read(path.join(path.dirname(manifestPath), 'cherax-publication.json'));
  const revision = publication.coolRepoCommit;
  if (!publication.exportCoverage || !/^[a-f0-9]{40}$/.test(revision)) throw Error('Expected a completed, published Cherax export');
  const git = (...args) => execFileSync('git', ['-c', `safe.directory=${repo.replace(/\\/g, '/')}`, ...args], {
    cwd: repo, encoding: 'utf8', maxBuffer: 80 * 1024 * 1024
  });
  git('merge-base', '--is-ancestor', revision, 'refs/remotes/origin/main');
  const acquired = JSON.parse(git('show', `${revision}:catalog/cherax-acquired-assets.json`));
  const assets = new Map(acquired.assets.map(row => [row.path, row.actual]));
  const tree = new Map(git('ls-tree', '-r', '-z', '--long', revision, '--', 'downloads/gta5/menus/cherax', 'previews/gta5/menus/cherax')
    .split('\0').filter(Boolean).map(row => {
      const [metadata, name] = row.split('\t');
      return [name, Number(metadata.trim().split(/\s+/).at(-1))];
    }));
  function asset(file, expected) {
    const actual = assets.get(file);
    if (!actual || actual.size !== tree.get(file) || (expected && (actual.sha256 !== expected.sha256 || actual.size !== expected.size))) {
      throw Error(`Cherax asset differs from the published catalog: ${file}`);
    }
    return actual;
  }
  function media(entry) {
    const result = {};
    if (entry.previewVerified && /^previews\/gta5\/menus\/cherax\//.test(entry.preview || '')) {
      asset(entry.preview);
      Object.assign(result, { preview: entry.preview, previewVerified: true, previewKind: entry.previewKind, previewCaption: entry.previewCaption });
    }
    if (entry.category !== 'lua' && entry.files?.length) {
      result.files = entry.files.map(file => {
        asset(file.path, file);
        return { path: file.path, name: file.name, sha256: file.sha256, size: file.size };
      });
      result.status = 'download';
      result.downloadStatus = 'available';
    }
    return result;
  }

  const site = siteData('community/data/menu-resources.json');
  const curated = siteData('project/community-menu-sources/cherax-site.json');
  const current = site.items.filter(entry => entry.game === 'gta5' && entry.sourceMenu === 'cherax');
  const ids = new Map(current.map(entry => [entry.id, entry]));
  const fileMatches = new Map(current.map(entry => [fileIdentity(entry), entry]).filter(([key]) => key));
  const scriptNames = new Map(current.filter(entry => entry.category === 'lua').map(entry => [luaName(entry.name), entry]));
  const replaced = new Set(curated.replaces);
  const items = new Map();
  for (const entry of manifest.items) {
    const hosted = media(entry);
    const themeId = entry.id.startsWith('gta5-modverse-themes-') && entry.id.replace('gta5-modverse-themes-', 'menu-cherax-theme-');
    const existing = ids.get(entry.id) || ids.get(themeId) || fileMatches.get(fileIdentity(entry)) ||
      (entry.category === 'lua' && scriptNames.get(luaName(entry.name)));
    if (existing) {
      if (existing.category !== 'lua' && !existing.files?.some(file => file.url?.startsWith('/assets/downloads/cherax/')) && hosted.files) {
        items.set(existing.id, { ...existing, ...items.get(existing.id), ...hosted });
      } else if (hosted.preview && !existing.preview) {
        items.set(existing.id, { ...items.get(existing.id), id: existing.id, preview: hosted.preview, previewVerified: true,
          previewKind: hosted.previewKind, previewCaption: hosted.previewCaption });
      }
      continue;
    }
    if (replaced.has(entry.id) || (!hosted.files && entry.category !== 'lua')) continue;
    const supportedMenus = menus.menuIds({ ...entry, game: 'gta5', sourceMenu: 'cherax' });
    const normalized = {
      ...Object.fromEntries(fields.filter(key => entry[key] !== undefined && entry[key] !== null).map(key => [key, entry[key]])),
      game: 'gta5', sourceMenu: 'cherax', supportedMenus, listedMenus: supportedMenus, menuResource: true, sourceCatalog: 'menu-resources',
      credits: entry.credits || (entry.creator !== 'Original developer unverified' ? entry.creator : null) || entry.sharedBy,
      guide: '/resources/guides/?game=gta5&menu=cherax&category=' + entry.category,
      ...hosted
    };
    if (!normalized.sourceFormat && entry.compatibilityLevel === 'source_importer_support') {
      normalized.sourceFormat = `Cherax ${entry.category === 'outfits' ? 'outfit' : 'vehicle'} JSON`;
    }
    if (entry.category === 'lua') Object.assign(normalized, { files: [], status: 'pending', downloadStatus: 'pending', downloadLabel: 'Download unavailable' });
    items.set(entry.id, normalized);
  }
  const libraryIds = new Set(siteData('community/data/library.json').items.map(entry => entry.id));
  const libraryOverrides = manifest.libraryOverrides.map(entry => {
    if (!libraryIds.has(entry.id)) throw Error(`Missing Cherax library record: ${entry.id}`);
    return { id: entry.id, ...media(entry) };
  }).filter(entry => Object.keys(entry).length > 1);
  return { version: 1, assetRevision: revision, items: [...items.values()], libraryOverrides };
}

if (require.main === module) {
  const [manifest, repo] = process.argv.slice(2);
  if (!manifest || !repo) throw Error('Pass the completed Cherax manifest and the cool-repo checkout.');
  const archive = build(path.resolve(manifest), path.resolve(repo));
  const output = path.join(root, 'community/data/cherax-resources.json');
  const rows = entries => entries.map(entry => `    ${JSON.stringify(entry)}`).join(',\n');
  const body = `{"version":${archive.version},"assetRevision":"${archive.assetRevision}",\n` +
    `  "items":[\n${rows(archive.items)}\n  ],\n` +
    `  "libraryOverrides":[\n${rows(archive.libraryOverrides)}\n  ]\n}\n`;
  fs.writeFileSync(output, body);
  console.log(JSON.stringify({ items: archive.items.length, libraryOverrides: archive.libraryOverrides.length, revision: archive.assetRevision }));
}
