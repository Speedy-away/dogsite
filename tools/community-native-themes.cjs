'use strict';

// Index native theme data and artwork from the existing checksum-pinned UI packs.
// Packages stay intact: individual presets link the complete collection so shared
// fonts, frame sequences and scripts are not separated from their dependencies.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const { renderListUiPreview } = require('./render-community-theme-preview.cjs');
const slug = value => String(value).normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'default';
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
const json = data => JSON.parse(data.toString('utf8').replace(/^\uFEFF/, ''));
const styles = { Stand: 'Stand', '2take1': '2Take1', impulse: 'Impulse', 'X-Force': 'X-Force', Silkroad: 'Silkroad', Ozark: 'Ozark', Paragon: 'Paragon' };
const styleIds = { Scooby: 0, '2Take1': 2, Impulse: 3, Stand: 4, Silkroad: 5, 'Silkroad Simple': 6, Ozark: 7, LTS: 8, 'X-Force': 9, Insight: 10, Paragon: 11 };

function openZip(file) {
  const bytes = fs.readFileSync(file);
  const minimum = Math.max(0, bytes.length - 65558);
  let end = bytes.length - 22;
  for (; end >= minimum && bytes.readUInt32LE(end) !== 0x06054b50; end--);
  if (end < minimum) throw Error(`Invalid native theme ZIP: ${file}`);
  const count = bytes.readUInt16LE(end + 10), entries = [];
  let position = bytes.readUInt32LE(end + 16);
  for (let i = 0; i < count; i++) {
    if (bytes.readUInt32LE(position) !== 0x02014b50) throw Error(`Invalid theme ZIP directory: ${file}`);
    const length = bytes.readUInt16LE(position + 28), extra = bytes.readUInt16LE(position + 30), comment = bytes.readUInt16LE(position + 32);
    const name = bytes.subarray(position + 46, position + 46 + length).toString('utf8');
    if (!name || name.startsWith('/') || name.includes('\\') || name.split('/').some(part => part === '..')) throw Error(`Unsafe theme ZIP member: ${name}`);
    entries.push({ name, size: bytes.readUInt32LE(position + 24), compressed: bytes.readUInt32LE(position + 20), method: bytes.readUInt16LE(position + 10), offset: bytes.readUInt32LE(position + 42) });
    position += 46 + length + extra + comment;
  }
  return {
    entries,
    read(entry) {
      const start = entry.offset + 30 + bytes.readUInt16LE(entry.offset + 26) + bytes.readUInt16LE(entry.offset + 28);
      const packed = bytes.subarray(start, start + entry.compressed);
      const result = entry.method === 0 ? packed : entry.method === 8 ? zlib.inflateRawSync(packed) : null;
      if (!result || result.length !== entry.size) throw Error(`Invalid theme ZIP payload: ${entry.name}`);
      return result;
    },
  };
}

function importNativeThemeCatalog(context) {
  const { sourceRoot, roots, items, add, plan, planSource, zip } = context;
  const previews = context.themePreviews !== false;
  const hosted = path.join(sourceRoot, 'Rendererrr.github.io/scooby/GTA5/ListUI/Themes');
  const catalogFile = path.join(hosted, 'packs.json');
  if (!fs.existsSync(catalogFile)) return;
  const catalog = json(fs.readFileSync(catalogFile));
  plan('catalog/listui-theme-packs-source.json', fs.readFileSync(catalogFile));
  const resourceCache = new Map(items.flatMap(item => item.files || []).filter(file => file.path).map(file => [file.path, file]));
  const imageCache = new Map();
  const ensureSource = (relative, source) => {
    if (!resourceCache.has(relative)) resourceCache.set(relative, planSource(relative, source));
    return resourceCache.get(relative);
  };
  const capture = style => {
    if (!previews) return {};
    if (imageCache.has(style)) return imageCache.get(style);
    if (style === 'Infamous' || style === 'Sx') {
      const source = path.join(roots.gta5, 'assets/listui', style === 'Infamous' ? 'Infamous-Full' : 'Sx', 'header.png');
      if (fs.existsSync(source)) {
        const preview = ensureSource(`previews/themes/styles/${slug(style)}-header.png`, source).path;
        const result = { preview, previewKind: 'artwork', previewCaption: `Included ${style} header artwork` };
        imageCache.set(style, result);
        return result;
      }
    }
    const id = styleIds[style] ?? 0;
    const source = path.join(roots.gta5, `build/listui-globe-20261109/production-preview/${id}.png`);
    if (!fs.existsSync(source)) throw Error(`Missing actual ListUI style capture: ${style}`);
    const preview = ensureSource(`previews/themes/styles/${slug(style)}.png`, source).path;
    const result = { preview, previewKind: 'style', previewCaption: `Scooby ${style === 'Scooby' ? 'Default ListUI' : style} style reference. Collection contents vary.` };
    imageCache.set(style, result);
    return result;
  };
  const artwork = (style, name, record, caption = 'Included theme artwork') => {
    if (!previews) return {};
    if (!record || record.entry.size > 3 * 1024 * 1024) return capture(style);
    const extension = path.posix.extname(record.entry.name).toLowerCase();
    if (!['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'].includes(extension)) return capture(style);
    const relative = `previews/themes/artwork/${slug(style)}-${digest(name).slice(0, 16)}${extension}`;
    plan(relative, record.zip.read(record.entry));
    return { preview: relative, previewKind: 'artwork', previewCaption: caption };
  };
  const makeBuiltin = (game, id, name, style, description, extra = {}) => add({
    id: `${game}-themes-builtin-${id}`, game, category: 'themes', uiStyle: 'ListUI', style, name,
    description, files: [], status: 'in-menu', guide: `/resources/guides/?game=${game}&category=themes`,
    credits: 'Scooby native ListUI', tags: ['ListUI', style, 'built-in'], ...capture(style), ...extra,
    compatibility: `Built into compatible Scooby ${game === 'gta5' ? 'GTA5' : 'RDR2'} builds. Choose the style in Settings > Appearance > ListUI.`,
  });
  for (const game of ['gta5', 'rdr2']) {
    makeBuiltin(game, 'default', 'Default ListUI', 'Scooby', 'The built-in Scooby ListUI interface. Select Normal / Default in the native ListUI style selector.');
    makeBuiltin(game, 'lts-soft-red', 'LTS Soft Red', 'LTS', 'Built-in LTS color preset. Select LTS, open Appearance > Colors and choose Soft Red.');
    const limePreview = previews ? plan(`previews/themes/listui-colors/${game}-lts-classic-lime.svg`, renderListUiPreview({ name: 'LTS Classic Lime', game, colors: { background: '#00000064', header: '#000000e1', selected: '#000000e1', accent: '#b9f47eff', text: '#ebebebff', selectedText: '#ebebebff' } })).path : undefined;
    makeBuiltin(game, 'lts-classic-lime', 'LTS Classic Lime', 'LTS', 'Built-in LTS color preset. Select LTS, open Appearance > Colors and choose Classic Lime.', { preview: limePreview, previewKind: 'palette', previewCaption: 'LTS Classic Lime color palette illustration' });
    makeBuiltin(game, 'insight-default', 'Insight Default', 'Insight', 'Built-in Insight ListUI interface and default preset. Choose Insight in the native style selector.');
    makeBuiltin(game, 'silkroad-simple', 'Silkroad Simple', 'Silkroad Simple', 'The native Silkroad Simple layout. Select Silkroad and choose the Simple layout variant in its Appearance controls.');
  }

  const addVariant = (style, key, name, files, preview, fields = {}) => {
    for (const game of ['gta5', 'rdr2']) add({
      id: `${game}-themes-preset-${slug(style)}-${digest(key).slice(0, 14)}`, game, category: 'themes', uiStyle: 'ListUI', style,
      name: `${name} · ${style}`, description: `Named ${style} preset included in the native collection. Download the collection files together to retain shared dependencies, then select ${name} in that style’s Themes controls.`,
      files, credits: 'Original theme authors; source collection and author artwork retained.',
      tags: ['ListUI', style, name, 'theme', 'preset'], themePath: key, ...(typeof preview === 'function' ? preview(game) : preview),
      sourceUrl: 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/ListUI/Themes',
      guide: `/resources/guides/?game=${game}&category=themes`,
      compatibility: `Scooby ${game === 'gta5' ? 'GTA5' : 'RDR2'} native ${style} theme import. Keep complete collection files and their original paths.`, ...fields,
    });
  };

  for (const [sourceStyle, packs] of Object.entries(catalog.styles)) {
    const style = styles[sourceStyle];
    if (!style) continue;
    const records = new Map(), files = [], archives = [];
    for (const pack of packs) {
      if (pack.file === 'impulse/Impulse-GTA-Content.zip') continue; // maps/vehicles, not a UI theme pack
      const source = path.join(hosted, ...pack.file.split('/'));
      if (fs.statSync(source).size !== pack.bytes || digest(fs.readFileSync(source)) !== pack.sha256) throw Error(`Native ListUI pack checksum mismatch: ${pack.file}`);
      const resource = ensureSource(`downloads/shared/themes/${slug(style)}/${path.posix.basename(pack.file)}`, source);
      files.push(resource);
      const zip = openZip(source);
      archives.push({ pack, zip, resource });
      for (const entry of zip.entries) records.set(entry.name, { entry, zip });
      if (style !== 'Stand') {
        for (const game of ['gta5', 'rdr2']) add({
          id: `${game}-themes-hosted-${slug(pack.file)}`, game, category: 'themes', uiStyle: 'ListUI', style,
          name: `${style} collection · ${path.posix.basename(pack.file, '.zip').replace(/^ListUI-/, '')}`,
          description: `Complete native ${style} resource pack with its original themes and supporting assets.`, files: [resource],
          ...capture(style), tags: ['ListUI', style, 'collection'], credits: 'Original collection authors.',
          sourceUrl: 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/ListUI/Themes',
          guide: `/resources/guides/?game=${game}&category=themes`,
          compatibility: `Compatible Scooby ${game === 'gta5' ? 'GTA5' : 'RDR2'} native ${style} style. Preserve the archive folders.`,
        });
      }
    }
    const candidates = [...records.keys()];
    const findArt = (folder, preferredName) => {
      let pictures = candidates.filter(name => name.startsWith(`${folder}/`) && /\.(png|jpg|jpeg|webp|gif|bmp)$/i.test(name) && !/menu_icons|checkbox|toggle|arrow|logo[_\/.]/i.test(name));
      if (preferredName) {
        const exact = candidates.find(name => /\/Previews\//.test(name) && slug(path.posix.basename(name, path.posix.extname(name))) === slug(preferredName));
        if (exact) return { ...records.get(exact), authorPreview: true };
      }
      pictures.sort((a, b) => {
        const score = name => (/preview/i.test(name) ? 100 : 0) + (/header/i.test(name) ? 40 : 0) + (/\.(png|webp|jpg)$/i.test(name) ? 15 : 0) - records.get(name).entry.size / 1000000;
        return score(b) - score(a) || a.localeCompare(b);
      });
      return records.get(pictures[0]);
    };
    if (style === '2Take1' || style === 'Impulse') {
      for (const key of candidates.filter(name => /\/theme_config\.json$/i.test(name))) {
        const folder = path.posix.dirname(key), name = path.posix.basename(folder);
        addVariant(style, key, name, files, artwork(style, key, findArt(folder)));
      }
    } else if (style === 'Stand') {
      for (const key of candidates.filter(name => /\/Profiles\/[^/]+\.txt$/i.test(name))) {
        const folder = key.slice(0, key.lastIndexOf('/Profiles/')), name = path.posix.basename(folder);
        const image = findArt(folder, name);
        addVariant(style, key, name, files, artwork(style, key, image, image?.authorPreview ? 'Original author’s Stand theme preview' : 'Included Stand theme artwork'), {
          sourceUrl: `https://github.com/stagnate6628/stand-themerepo/tree/main/Themes/${encodeURIComponent(name)}`,
          credits: 'Original Stand theme authors; stagnate6628/stand-themerepo collection.',
        });
      }
      const allInOne = candidates.find(name => name.endsWith('/LuaTheme-All-In-One-Stand.lua'));
      if (allInOne) {
        const record = records.get(allInOne), text = record.zip.read(record.entry).toString('utf8');
        const list = text.split(/\r?\n/).find(line => line.startsWith('local theme =')) || '';
        for (const match of list.matchAll(/"([^"\r\n]+)"/g)) {
          const name = match[1];
          if (name.toLowerCase() === 'default') continue;
          const folder = allInOne.slice(0, allInOne.indexOf('/Lua Scripts/'));
          const image = findArt(folder, name);
          addVariant(style, `${allInOne}#${name}`, `${name} (All-in-One)`, files, artwork(style, `all-in-one-${name}`, image, image?.authorPreview ? 'Original author’s Stand theme preview' : 'Artwork from the All-in-One collection; appearance varies by preset'), {
            description: `Built-in choice from the Scooby-supported Stand All-in-One theme collection. Install the full Stand collections, then choose ${name} from the native theme selector.`,
          });
        }
      }
    } else if (style === 'X-Force') {
      const selected = files.filter(file => /All-02\.zip$/.test(file.path));
      for (const key of candidates.filter(name => /\.(ui|xf_cnfg)$/i.test(name))) {
        const stem = path.posix.basename(key, path.posix.extname(key));
        const name = stem === '' || stem === '.ui' ? 'Default' : stem.replace(/[_-]+/g, ' ');
        let settings;
        try { const record = records.get(key); settings = json(record.zip.read(record.entry)).ui_settings; } catch { /* Native legacy presets can use another serialization. */ }
        const custom = settings?.header?.custom_name;
        const customImage = custom && custom !== 'null' && candidates.find(candidate => candidate.endsWith(`/${custom}`));
        let preview;
        if (customImage) preview = artwork(style, key, records.get(customImage));
        else if (settings?.components?.background && settings?.components?.scroller && settings?.header?.box && settings?.text?.unselected) {
          const packed = value => (value.red | value.green << 8 | value.blue << 16 | value.alpha << 24) >>> 0;
          const colors = { background: packed(settings.components.background), header: packed(settings.header.box), selected: packed(settings.components.scroller), accent: packed(settings.header.line || settings.components.scroller), text: packed(settings.text.unselected), selectedText: packed(settings.text.selected || settings.text.unselected) };
          preview = game => previews ? ({ preview: plan(`previews/themes/xforce-colors/${game}-${digest(key).slice(0, 14)}.svg`, renderListUiPreview({ name, game, colors })).path, previewKind: 'palette', previewCaption: 'Source-defined X-Force color palette illustration' }) : {};
        } else preview = capture(style);
        addVariant(style, key, name, selected.length ? selected : files, preview);
      }
    } else if (style === 'Silkroad') {
      const key = candidates.find(name => name.endsWith('/theme-catalog.json'));
      if (key) {
        const record = records.get(key), themes = json(record.zip.read(record.entry)).themes;
        for (const theme of themes) {
          const image = theme.artwork && records.get(`Silkroad/${theme.artwork}`);
          addVariant(style, `${key}#${theme.id}`, theme.name, files, artwork(style, `${key}-${theme.id}`, image));
        }
      }
    } else if (style === 'Ozark') {
      for (const key of candidates.filter(name => /\/Presets\/[^/]+\.json$/i.test(name))) {
        const record = records.get(key), document = json(record.zip.read(record.entry));
        const art = document.values?.['Ozark.Image.header'];
        const image = art && records.get(`Ozark v34/${art}`);
        addVariant(style, key, path.posix.basename(key, '.json'), files, artwork(style, key, image));
      }
    } else if (style === 'Paragon') {
      for (const key of candidates.filter(name => /\/theme\.json$/i.test(name))) {
        const folder = path.posix.dirname(key);
        addVariant(style, key, path.posix.basename(folder), files, artwork(style, key, findArt(folder)));
      }
    }
  }

  // Additional Paragon collections are bundled in the source resource pack,
  // separate from the published default archive indexed above.
  for (const name of ['animated', 'black', 'Small']) {
    const folder = path.join(roots.gta5, 'assets/listui/Paragon/Collections', name);
    const filename = fs.existsSync(folder) && fs.readdirSync(folder).find(file => /^theme\.json$/i.test(file));
    if (!filename) continue;
    const document = json(fs.readFileSync(path.join(folder, filename)));
    const headerFile = ['header.gif', 'header.png'].map(file => path.join(folder, file)).find(file => fs.existsSync(file));
    const color = value => (value.r | value.g << 8 | value.b << 16 | value.a << 24) >>> 0;
    const colors = { background: color(document.Options['Background Color']), header: color(document.Header.Color), selected: color(document.Options['Scroller Color']), accent: color(document.Options['Scroller Color']), text: color(document.Options['Unselected Text Color']), selectedText: color(document.Options['Selected Text Color']) };
    for (const game of ['gta5', 'rdr2']) {
      const resource = items.find(item => item.id === `${game}-themes-scooby-paragon-resources`)?.files;
      if (!resource?.length) throw Error(`Missing complete Paragon source resource pack for ${game}`);
      const id = `${game}-themes-preset-paragon-local-${slug(name)}`;
      const preview = !previews ? undefined : headerFile ? ensureSource(`previews/themes/artwork/paragon-local-${slug(name)}${path.extname(headerFile)}`, headerFile).path
        : plan(`previews/themes/paragon-colors/${id}.svg`, renderListUiPreview({ name: `Paragon ${name}`, game, colors })).path;
      add({ id, game, category: 'themes', uiStyle: 'ListUI', style: 'Paragon', name: `Paragon ${name === 'animated' ? 'Animated' : name === 'black' ? 'Black' : 'Small'}`,
        description: 'Native Paragon theme collection included in the complete Scooby resource bundle. Keep its theme JSON and supporting files together.',
        files: resource, preview, previewKind: headerFile ? 'artwork' : 'palette', previewCaption: headerFile ? 'Included Paragon header artwork' : 'Source-defined Paragon color palette illustration',
        themePath: `Paragon/Collections/${name}`, tags: ['ListUI', 'Paragon', name, 'theme'], credits: 'Original Paragon theme authors; bundled Scooby resources.',
        guide: `/resources/guides/?game=${game}&category=themes`, compatibility: `Scooby ${game === 'gta5' ? 'GTA5' : 'RDR2'} native Paragon style.` });
    }
  }

  // Reproduce the data/artwork layout documented by package_brazil_themes.py.
  // The native appearance actions own applying the actual style settings.
  const brazilRoot = path.join(roots.gta5, 'src/core/frontend/ListUI/Styles/Impulse/Assets/Themes/Brazil');
  if (fs.existsSync(brazilRoot)) {
    const mapping = [['Normal', 'Scooby'], ['IMPULSE', 'Impulse'], ['2TAKE1', '2Take1'], ['Stand', 'Stand'], ['Silkroad v3-v4', 'Silkroad'], ['Silkroad Simple', 'Silkroad Simple'], ['Ozark v34', 'Ozark'], ['LTS', 'LTS'], ['X-Force v6', 'X-Force']];
    const artworkFiles = ['Brazil-header.gif', 'Brazil-flag.gif', 'Brazil-footer.png'].map(name => ({ name, data: fs.readFileSync(path.join(brazilRoot, name)) }));
    const entries = mapping.flatMap(([folder]) => artworkFiles.map(file => ({ name: `${folder}/Brazil/${file.name}`, data: file.data })));
    entries.push({ name: 'IMPULSE/Brazil/theme_config.json', data: fs.readFileSync(path.join(brazilRoot, 'theme_config.json')) });
    entries.push({ name: 'INSTALL.txt', data: 'Extract the style folders into C:/scooby/<game>/Themes/ListUI. In a compatible native style, choose Brazil (Animated) in Themes. RDR2 LTS exposes this action under Colors. Native style actions apply the settings; installing artwork alone does not change your theme. Original geometric flag artwork comes from the Scooby build_brazil_theme.py generator.\n' });
    const resource = plan('downloads/shared/themes/brazil/ListUI-Brazil-All-01.zip', zip(entries));
    const preview = previews ? ensureSource('previews/themes/artwork/brazil-animated-header.gif', path.join(brazilRoot, 'Brazil-header.gif')).path : undefined;
    for (const game of ['gta5', 'rdr2']) {
      add({ id: `${game}-themes-hosted-brazil-all`, game, category: 'themes', uiStyle: 'ListUI', style: 'Scooby', name: 'Brazil Animated · all supported ListUI styles',
        description: 'Original geometric flag artwork for the native Brazil theme actions across supported ListUI styles.', files: [resource], preview, previewKind: 'artwork', previewCaption: 'Original animated Brazil theme header artwork',
        credits: 'Scooby original procedural flag artwork', tags: ['ListUI', 'Brazil', 'animated', 'collection'], guide: `/resources/guides/?game=${game}&category=themes`, compatibility: 'Requires a compatible Scooby build with the native Brazil (Animated) appearance action.' });
      for (const [folder, style] of mapping) {
        if (game === 'gta5' && style === 'LTS') continue;
        add({ id: `${game}-themes-preset-${slug(style)}-${digest(`Brazil/${folder}`).slice(0, 14)}`, game, category: 'themes', uiStyle: 'ListUI', style, name: `Brazil (Animated) · ${style === 'Scooby' ? 'Default ListUI' : style}`,
          files: [resource], preview, previewKind: 'artwork', previewCaption: 'Original animated Brazil theme header artwork', themePath: `${folder}/Brazil`,
          description: `Install the original Brazil artwork, then choose Brazil (Animated) in ${style === 'LTS' ? 'LTS Colors' : `${style === 'Scooby' ? 'Default ListUI' : style} Themes`}. Native style settings are applied by the menu.`,
          credits: 'Scooby original procedural flag artwork', tags: ['ListUI', 'Brazil', 'animated', style], guide: `/resources/guides/?game=${game}&category=themes`,
          compatibility: `Compatible Scooby ${game === 'gta5' ? 'GTA5' : 'RDR2'} native ${style === 'Scooby' ? 'Default ListUI' : style} style.`,
        });
      }
    }
  }

  // Shared built-in color palette names and exact channel values, not invented themes.
  for (const game of ['gta5', 'rdr2']) {
    const source = fs.readFileSync(path.join(roots[game], 'src/core/frontend/ListUIColorThemes.hpp'), 'utf8');
    const expression = /\{"([^"]+)",((?:IM_COL32\([\d,\s]+\),?){5})\}/g;
    let count = 0;
    for (const match of source.matchAll(expression)) {
      const vectors = [...match[2].matchAll(/IM_COL32\(([^)]+)\)/g)].map(m => m[1].split(',').map(Number));
      const packed = vector => (vector[0] | vector[1] << 8 | vector[2] << 16 | vector[3] << 24) >>> 0;
      const [accent, background, header, text] = vectors.map(packed);
      const selected = packed([Math.round(vectors[0][0] * .58), Math.round(vectors[0][1] * .58), Math.round(vectors[0][2] * .58), vectors[0][3]]);
      const name = `${match[1]} ListUI colors`, id = `${game}-themes-shared-${slug(match[1])}`;
      const preview = previews ? plan(`previews/themes/listui-colors/${id}.svg`, renderListUiPreview({ name, game, colors: { background, header, accent, selected, text, selectedText: text } })).path : undefined;
      add({ id, game, category: 'themes', uiStyle: 'ListUI', style: 'Scooby', name,
        description: `Built-in shared ListUI color preset. Choose ${match[1]} from the native ListUI color Themes controls.`, files: [], status: 'in-menu',
        preview, previewKind: 'palette', previewCaption: 'ListUI color palette illustration', tags: ['ListUI', 'colors', 'palette', match[1]], credits: 'Scooby native ListUI palette data',
        guide: `/resources/guides/?game=${game}&category=themes`, compatibility: 'Built into compatible Scooby ListUI styles; select it in the native Appearance controls.' });
      count++;
    }
    if (count !== 8) throw Error(`Expected eight source-backed shared ListUI palettes for ${game}; got ${count}`);
  }

  // Every active theme gets an image. Style references are explicit context images,
  // while palette exports and indexed original artwork carry precise captions.
  for (const item of items.filter(item => item.category === 'themes' && !item.preview)) {
    Object.assign(item, capture(item.style || 'Scooby'));
  }
}

module.exports = { importNativeThemeCatalog, openZip };
