'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { zip } = require('./build-reseller-media.cjs');
const ROOT = path.resolve(__dirname, '..');
const GAMES = new Set(['gta5', 'rdr2', 'cs2', 'redm', 'l4d']);
const MENUS = new Set(['scooby', 'nenyoo', 'cherax', 'stand', 'xforce']);
const CATEGORIES = new Set(['vehicles', 'modded', 'outfits', 'maps', 'textures', 'paintjobs', 'liveries', 'players', 'weapons', 'knives', 'throwables', 'bombs', 'skyboxes', 'themes', 'configs', 'lua', 'languages', 'misc', 'dlc', 'wallpapers', 'asi-mods', 'dotnet-mods', 'addon-vehicles', 'addon-peds', 'addon-objects', 'addon-animations', 'addon-maps', 'addon-clothing', 'weapon-models', 'sound-packs', 'graphics-packs', 'ui-presets', 'visual-effects', 'scopes', 'settings']);
const EXTENSIONS = new Set(['.json', '.xml', '.ini', '.txt', '.ui', '.xf_cnfg', '.lua', '.pluto', '.zip', '.rar', '.7z', '.rpf', '.awc', '.ymap', '.ytyp', '.ydd', '.ytd', '.ydr', '.yft', '.ybn', '.ymt', '.ycd', '.vmdl_c', '.vmat_c', '.vtex_c', '.cfg', '.config', '.asi', '.dll', '.cs', '.wav', '.ogg', '.png', '.jpg', '.jpeg', '.webp', '.gif', '.dds', '.bmp', '.ttf', '.otf', '.md', '.pdf']);
const IMAGE = /\.(png|jpe?g|webp|gif)$/i;
const supportedFile = name => EXTENSIONS.has(path.extname(name).toLowerCase()) || /\.(?:zip|7z)\.\d{3}$/i.test(name);
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const portable = value => value.split(path.sep).join('/');
function collect(directory) {
  if (fs.lstatSync(directory).isSymbolicLink()) throw Error('Resource payload directories cannot be symbolic links');
  return fs.readdirSync(directory, { withFileTypes: true }).filter(entry => !entry.isSymbolicLink() && !entry.name.startsWith('.'))
    .sort((a, b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => entry.isDirectory() ? collect(path.join(directory, entry.name)) : entry.isFile() ? [path.join(directory, entry.name)] : []);
}
function importInbox(inbox = path.join(ROOT, 'project/resource-inbox'), options = {}) {
  const stageRoot = options.stageRoot || path.join(ROOT, 'project/community-menu-sources/inbox-assets');
  const output = options.output || path.join(ROOT, 'project/community-menu-sources/inbox.json');
  const items = [], excluded = [];
  const stage = (bytes, extension) => {
    const file = path.join(stageRoot, digest(bytes).slice(0, 24) + extension);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    if (!fs.existsSync(file)) fs.writeFileSync(file, bytes);
    return portable(path.relative(ROOT, file));
  };
  if (fs.existsSync(inbox)) for (const game of fs.readdirSync(inbox, { withFileTypes: true }).filter(entry => entry.isDirectory() && !entry.isSymbolicLink() && GAMES.has(entry.name))) {
    const gameRoot = path.join(inbox, game.name);
    for (const menu of fs.readdirSync(gameRoot, { withFileTypes: true }).filter(entry => entry.isDirectory() && !entry.isSymbolicLink() && MENUS.has(entry.name))) {
      const menuRoot = path.join(gameRoot, menu.name);
      for (const category of fs.readdirSync(menuRoot, { withFileTypes: true }).filter(entry => entry.isDirectory() && !entry.isSymbolicLink() && CATEGORIES.has(entry.name))) {
        const categoryRoot = path.join(menuRoot, category.name), siblings = fs.readdirSync(categoryRoot, { withFileTypes: true });
        for (const entry of siblings.filter(entry => !entry.isSymbolicLink() && !entry.name.startsWith('.'))) {
          const source = path.join(categoryRoot, entry.name), relative = portable(path.relative(inbox, source));
          if (game.name === 'redm' && /(?:pm[ _-]*bypass|fast(?:er)?[ _-]*scope)/i.test(relative)) { excluded.push(relative); continue; }
          if (!entry.isFile() && !entry.isDirectory()) continue;
          if (entry.isFile() && !supportedFile(entry.name)) continue;
          if (entry.isFile() && IMAGE.test(entry.name) && siblings.some(other => other.isFile() && other.name !== entry.name && !IMAGE.test(other.name) && path.parse(other.name).name === path.parse(entry.name).name)) continue;
          const metadataPath = path.join(source, 'resource.json');
          const metadata = entry.isDirectory() && fs.existsSync(metadataPath) ? JSON.parse(fs.readFileSync(metadataPath, 'utf8')) : {};
          const label = String(metadata.name || path.parse(entry.name).name).replace(/\s*\(RedM Hub\)\s*by\s+Dadash/ig, '').trim();
          if (game.name === 'redm' && /(?:pm[ _-]*bypass|fast(?:er)?[ _-]*scope)/i.test(label)) { excluded.push(relative); continue; }
          let preview;
          if (entry.isDirectory()) preview = ['preview.png', 'preview.jpg', 'preview.webp', 'preview.gif'].map(name => path.join(source, name)).find(file => fs.existsSync(file) && !fs.lstatSync(file).isSymbolicLink());
          else preview = siblings.filter(other => other.isFile() && !other.isSymbolicLink() && IMAGE.test(other.name) && path.parse(other.name).name === path.parse(entry.name).name).map(other => path.join(categoryRoot, other.name))[0];
          const item = { id: `inbox-${game.name}-${menu.name}-${category.name}-${digest(relative).slice(0, 14)}`, game: game.name, sourceMenu: menu.name,
            category: category.name, name: label, credits: metadata.credits || 'User-provided resource; original package credits retained',
            description: metadata.description || `${label} resource. Keep its supporting files together.`, tags: metadata.tags || [], requirements: metadata.requirements || [],
            license: metadata.license, version: metadata.version, versionBasis: metadata.versionBasis,
            compatibility: metadata.compatibility, supportedMenus: metadata.supportedMenus || [menu.name], listedMenus: metadata.listedMenus,
            changelog: metadata.changelog || [], sourceUrl: metadata.sourceUrl, files: [] };
          if (category.name === 'lua') {
            item.downloadStatus = 'pending';
            if (entry.isFile()) item.sourceFilename = entry.name;
          } else if (entry.isDirectory()) {
            const payloadRoot = fs.existsSync(path.join(source, 'files')) ? path.join(source, 'files') : source;
            const files = collect(payloadRoot).filter(file => file !== metadataPath && file !== preview);
            if (!files.length) continue;
            for (const file of files) {
              if (!supportedFile(file)) throw Error(`Unsupported resource payload: ${portable(path.relative(inbox, file))}`);
              if (path.extname(file).toLowerCase() === '.json') JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
            }
            const bytes = zip(files.map(file => [portable(path.relative(payloadRoot, file)), fs.readFileSync(file)]));
            if (bytes.length >= 100 * 1024 * 1024) throw Error(`Resource bundle is too large for one download: ${relative}. Supply split archives as separate files.`);
            item.files = [{ localPath: stage(bytes, '.zip'), name: `${label}.zip` }];
          } else {
            const bytes = fs.readFileSync(source), extension = source.match(/\.(?:zip|7z)\.\d{3}$/i)?.[0].toLowerCase() || path.extname(source).toLowerCase();
            if (extension === '.json') JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
            if (bytes.length >= 100 * 1024 * 1024) throw Error(`Resource exceeds the per-file download limit: ${relative}`);
            item.files = [{ localPath: stage(bytes, extension), name: /\.(?:zip|7z)\.\d{3}$/i.test(entry.name) ? entry.name : `${label}${extension}` }];
          }
          if (preview) { item.preview = stage(fs.readFileSync(preview), path.extname(preview).toLowerCase()); item.previewVerified = true; item.previewCaption = 'Provided resource image'; }
          items.push(item);
        }
      }
    }
  }
  const manifest = { version: 1, items, coverage: [{ source: 'resource inbox', resources: items.length, excluded }] };
  fs.mkdirSync(path.dirname(output), { recursive: true });
  const bytes = JSON.stringify(manifest, null, 2) + '\n', temporary = `${output}.tmp-${process.pid}`;
  fs.writeFileSync(temporary, bytes); fs.renameSync(temporary, output);
  return manifest;
}
module.exports = { importInbox, collect };
if (require.main === module) {
  const index = process.argv.indexOf('--inbox');
  try { const result = importInbox(index >= 0 ? path.resolve(process.argv[index + 1]) : undefined); console.log(JSON.stringify({ inboxResources: result.items.length, excluded: result.coverage[0].excluded.length })); }
  catch (error) { console.error(error.stack || error.message); process.exitCode = 1; }
}
