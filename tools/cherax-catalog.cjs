'use strict';

const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const sourceFile = path.join(root, 'project/community-menu-sources/cherax-site.json');
const previewCaptions = {
  'publisher-outfit': 'Outfit image from the ModVerse catalog',
  'source-outfit': 'Image from the original outfit share',
  'source-vehicle': 'Original vehicle image',
  'source-dlc': 'Screenshot from the original DLC share',
  'source-lua': 'Screenshot from the original script share',
  'source-artwork': 'Artwork from the original script share',
  'author-artwork': 'Artwork from the author’s repository',
  'source-theme': 'Screenshot from the original theme share'
};

function themeMetadata(interfaces) {
  const label = interfaces.join(' and ');
  const format = `Cherax ${label} theme package`;
  return {
    uiStyle: interfaces.length === 1 ? interfaces[0] : interfaces,
    format,
    sourceFormat: format,
    description: `Theme package for Cherax ${label}.`,
    compatibility: 'Use the included theme files for the active Cherax interface.',
    requirementLabel: `Requires Cherax ${label}`,
    requirements: ['Use the theme files for the active interface', 'Keep bundled artwork and settings together']
  };
}

function applyCheraxCatalog(catalog) {
  if (!fs.existsSync(sourceFile)) return;
  const manifest = JSON.parse(fs.readFileSync(sourceFile, 'utf8'));
  // The public RPF indexes for these packages contain vehicles.meta and a vehicle archive.
  const vehicleDlcIds = new Set(manifest.vehicleDlcIds);
  function vehicleDlc(entry) {
    return entry.category === 'dlc' && entry.sourceMenu === 'cherax' && vehicleDlcIds.has(entry.id)
      ? {
        sourceFormat: 'Vehicle DLC archive (RPF7)',
        compatibility: 'The RPF index contains vehicle metadata and a vehicle archive. Match the game edition and DLC loader before installing.'
      } : {};
  }
  const previews = new Map();
  for (const { ids, file, kind } of manifest.previews) {
    const preview = '/assets/images/resource-previews/cherax/' + file;
    if (!/^[a-f0-9]{20}\.webp$/.test(file) || !previewCaptions[kind] || !fs.existsSync(path.join(root, preview))) {
      throw Error('Invalid Cherax preview ' + file);
    }
    for (const id of ids) previews.set(id, {
      preview, previewVerified: true, previewKind: kind, previewCaption: previewCaptions[kind]
    });
  }
  const curated = new Map(manifest.items.map(entry => {
    for (const file of entry.files) {
      if (!/^\/assets\/downloads\/cherax\/[a-f0-9]{20}\.(?:lua|zip|rar|7z|json)$/.test(file.url) ||
          !fs.existsSync(path.join(root, file.url))) throw Error('Missing Cherax download ' + file.url);
    }
    const available = entry.files.length > 0;
    const isTheme = entry.category === 'themes';
    const normalized = {
      ...entry,
      ...(isTheme ? themeMetadata(entry.uiStyle) : {}),
      game: 'gta5', sourceMenu: 'cherax', supportedMenus: ['cherax'],
      listedMenus: ['cherax'],
      menuResource: true, sourceCatalog: 'menu-resources',
      status: available ? 'download' : 'pending',
      downloadStatus: available ? 'available' : 'pending',
      ...(!available && { downloadLabel: 'Download unavailable' }),
      guide: '/resources/guides/?game=gta5&menu=cherax&category=' + entry.category
    };
    return [entry.id, normalized];
  }));
  const replaced = new Set([...manifest.replaces, ...curated.keys()]);
  catalog.items = [...catalog.items.filter(entry => !replaced.has(entry.id)), ...curated.values()].map(entry => {
    const interfaces = manifest.themeInterfaces[entry.id];
    return {
      ...entry,
      ...vehicleDlc(entry),
      ...(interfaces ? { ...themeMetadata(interfaces), tags: [...new Set([...entry.tags, ...interfaces])] } : {}),
      ...previews.get(entry.id)
    };
  });
  catalog.libraryOverrides = catalog.libraryOverrides.map(entry => ({ ...entry, ...vehicleDlc(entry), ...previews.get(entry.id) }));
}

module.exports = { applyCheraxCatalog };
