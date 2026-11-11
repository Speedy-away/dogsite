'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { zip } = require('./build-reseller-media.cjs');

const site = path.resolve(__dirname, '..');
const sources = path.join(site, 'project/community-menu-sources');
const staging = path.join(sources, 'gta5-addon-payloads');
const sourceURL = 'https://github.com/Rendererrr/Rendererrr.github.io/tree/main/scooby/GTA5/addons';
const defaultBundle = 'C:/scooby/GTA5/Addons/Downloads/Scooby-GTA-V-Addons-20261027';
const names = {
  'Black Knight': 'Black Knight', deadpool: 'Deadpool', sonic: 'Sonic',
  '00spid': '00spid', amggtsmansory: 'Mercedes-AMG GT S Mansory',
  'Chrysler 300 Redeye': 'Chrysler 300 Redeye', lrsv27: '2027 Lamborghini Revuelto SV',
  r820: 'Audi R8', r820_enhanced: 'Audi R8', rs7: 'Audi RS7'
};
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const slug = name => name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

function build(bundle = defaultBundle) {
  const root = fs.realpathSync(bundle);
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'bundle-manifest.json'), 'utf8'));
  if (manifest.schema !== 1 || !Array.isArray(manifest.files)) throw Error('Unexpected GTA 5 addon bundle manifest');
  const groups = new Map();
  for (const file of manifest.files) {
    const parts = file.path.split('/');
    const ped = parts[0] === 'addons' && parts[1] === 'peds' && parts.length >= 4;
    const vehicle = parts[0] === 'addons' && parts[1] === 'vehicles' && ['Legacy', 'Enhanced'].includes(parts[2]) && parts.length >= 5;
    if (!ped && !vehicle) continue;
    if (parts.some(part => !part || part === '.' || part === '..' || /[\\:]/.test(part))) throw Error('Unsafe bundle path');
    const scope = parts.slice(0, ped ? 3 : 4).join('/');
    if (!groups.has(scope)) groups.set(scope, []);
    groups.get(scope).push(file);
  }
  if (!groups.size) throw Error('No ped or vehicle packages found');
  function readVerified(file) {
    const real = fs.realpathSync(path.resolve(root, file.path));
    if (path.relative(root, real).split(path.sep).join('/') !== file.path) throw Error('Bundle member escaped its recorded path: ' + file.path);
    const bytes = fs.readFileSync(real);
    if (bytes.length !== file.bytes || digest(bytes) !== file.sha256) throw Error('Bundle member differs from its checksum: ' + file.path);
    return bytes;
  }
  const items = [];
  fs.mkdirSync(staging, { recursive: true });
  for (const [scope, files] of groups) {
    const [, family, editionOrName, folder] = scope.split('/');
    const vehicle = family === 'vehicles';
    if (vehicle && !files.some(file => /\/dlc\.rpf$/i.test(file.path))) continue;
    if (!vehicle && !['.ydd', '.yft', '.ymt', '.ytd'].every(ext => files.some(file => file.path.toLowerCase().endsWith(ext)))) continue;
    const original = vehicle ? folder : editionOrName;
    const name = names[original] || original;
    const edition = vehicle ? editionOrName.toLowerCase() : undefined;
    const id = `gta5-scooby-addon-${family}-${edition ? edition + '-' : ''}${slug(original)}`;
    const entries = files.map(file => [file.path.slice(scope.lastIndexOf('/') + 1), readVerified(file)]);
    if (vehicle && original === 'lrsv27') {
      const notes = manifest.files.find(file => file.path === `addons/vehicles/${editionOrName}/2027 Lamborghini Revuelto SV.txt`);
      if (notes) entries.push(['2027 Lamborghini Revuelto SV.txt', readVerified(notes)]);
    }
    entries.push(['SCOOBY-ADDON.txt', Buffer.from([
      'Source: ' + sourceURL,
      'Original model assets from the Scooby GTA V addon collection. Original author credits and terms apply.',
      vehicle ? `Edition: GTA V ${editionOrName}. Import the complete ${original} folder in Addons/Replacements.`
        : `Import the complete ${original} folder as a loose ped in Addons/Replacements. Check edition support before importing.`,
      'Keep the source folder and its supporting files together.'
    ].join('\n') + '\n')]);
    const data = zip(entries);
    if (data.length >= 100 * 1024 * 1024) throw Error('Addon exceeds the single download size limit: ' + scope);
    const file = path.join(staging, id + '.zip');
    fs.writeFileSync(file, data);
    items.push({
      id, game: 'gta5', category: vehicle ? 'addon-vehicles' : 'addon-peds',
      sourceMenu: 'scooby', supportedMenus: ['scooby', 'nenyoo'], name,
      ...(vehicle ? { editionSupport: edition, editionSource: sourceURL } : {}),
      description: vehicle ? `Individual ${editionOrName} vehicle package from the Scooby addon collection.`
        : 'Individual loose ped package from the Scooby addon collection.',
      tags: [original, vehicle ? 'DLC RPF' : 'loose ped', ...(vehicle ? [editionOrName] : [])],
      credits: 'Original model authors. Package from the Scooby GTA V addon collection.',
      sourceUrl: sourceURL,
      requirements: [vehicle ? `GTA V ${editionOrName} and a compatible Scooby addon importer` : 'A compatible Scooby loose-ped importer. The source bundle does not identify the supported edition.'],
      files: [{ localPath: path.relative(site, file).split(path.sep).join('/'), name: `${slug(name)}${edition ? '-' + edition : ''}.zip` }]
    });
  }
  const output = path.join(sources, 'gta5-addon-packs.json');
  const temp = output + '.tmp-' + process.pid;
  fs.writeFileSync(temp, JSON.stringify({ version: 1, items, summary: { verifiedPackages: items.length } }, null, 2) + '\n');
  fs.renameSync(temp, output);
  return items;
}

if (require.main === module) {
  const items = build(process.argv[2]);
  console.log(JSON.stringify({ peds: items.filter(item => item.category === 'addon-peds').length,
    vehicles: items.filter(item => item.category === 'addon-vehicles').length }));
}
