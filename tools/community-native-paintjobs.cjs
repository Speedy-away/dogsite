'use strict';

// Read only the explicitly requested native LSC preset library. Paintjobs are
// saved colour data; livery images and game-wide/user account configs are excluded.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const DEFAULT_ROOT = 'C:\\scooby\\GTA5\\LSC\\PaintJobs';
const TOP_LEVEL = new Set(['format', 'version', 'name', 'model', 'vehicle_name', 'category', 'source', 'hex', 'secondary_hex', 'pearl_hex', 'archive_id', 'creator', 'colours', 'alpha']);
const SECTIONS = new Set(['primary', 'secondary', 'neon', 'tyre_smoke', 'headlights']);
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const plain = value => value && typeof value === 'object' && !Array.isArray(value);
const integer = (value, low, high) => Number.isInteger(value) && value >= low && value <= high;

function validateNativePaintjob(document, context = 'paintjob') {
  const fail = message => { throw Error(`${context}: ${message}`); };
  if (!plain(document) || document.format !== 'scooby.paintjob' || ![1, 2].includes(document.version)) fail('Unsupported native paintjob format/version');
  for (const key of Object.keys(document)) if (!TOP_LEVEL.has(key)) fail(`Unsupported field ${key}; unrelated config data is not imported`);
  if (document.name !== undefined && (typeof document.name !== 'string' || !document.name.trim())) fail('Invalid preset name');
  if (document.model !== undefined && !integer(document.model, -2147483648, 0xffffffff)) fail('Invalid vehicle model');
  if (document.alpha !== undefined && !integer(document.alpha, 0, 255)) fail('Invalid alpha');
  for (const key of ['vehicle_name', 'category', 'source', 'creator', 'archive_id']) {
    if (document[key] !== undefined && !['string', 'number'].includes(typeof document[key])) fail(`Invalid ${key}`);
  }
  for (const key of ['hex', 'secondary_hex', 'pearl_hex']) if (document[key] !== undefined && !/^#[a-f0-9]{6}(?:[a-f0-9]{2})?$/i.test(document[key])) fail(`Invalid ${key}`);
  if (!plain(document.colours) || !Object.keys(document.colours).length) fail('Missing native colour sections');
  const rgb = (value, key) => {
    if (!Array.isArray(value) || value.length !== 3 || value.some(channel => !integer(channel, 0, 255))) fail(`Invalid RGB in ${key}`);
  };
  for (const [key, section] of Object.entries(document.colours)) {
    if (!SECTIONS.has(key) || !plain(section)) fail(`Unsupported colour section ${key}`);
    const allowed = key === 'primary' ? ['base', 'custom', 'rgb', 'pearl', 'paint_type']
      : key === 'secondary' ? ['base', 'custom', 'rgb', 'paint_type']
        : key === 'neon' || key === 'tyre_smoke' ? ['enabled', 'rgb'] : ['enabled', 'colour'];
    for (const field of Object.keys(section)) if (!allowed.includes(field)) fail(`Unsupported colour field ${key}.${field}`);
    if (section.rgb !== undefined) rgb(section.rgb, key);
    if (section.base !== undefined && !integer(section.base, 0, 255)) fail(`Invalid base in ${key}`);
    if (section.paint_type !== undefined && !integer(section.paint_type, 0, 5)) fail(`Invalid paint type in ${key}`);
    if (section.custom !== undefined && typeof section.custom !== 'boolean') fail(`Invalid custom flag in ${key}`);
    if (section.colour !== undefined && !integer(section.colour, -1, 255)) fail(`Invalid colour index in ${key}`);
    if (section.enabled !== undefined) {
      if (key === 'neon') {
        if (!Array.isArray(section.enabled) || section.enabled.length !== 4 || section.enabled.some(flag => typeof flag !== 'boolean')) fail('Invalid neon flags');
      } else if (typeof section.enabled !== 'boolean') fail(`Invalid enabled flag in ${key}`);
    }
    if (section.pearl !== undefined) {
      if (!plain(section.pearl) || Object.keys(section.pearl).some(field => !['enabled', 'colour', 'rgb'].includes(field))) fail('Invalid pearl section');
      if (section.pearl.enabled !== undefined && typeof section.pearl.enabled !== 'boolean') fail('Invalid pearl enabled flag');
      if (section.pearl.colour !== undefined && !integer(section.pearl.colour, 0, 160)) fail('Invalid pearl colour');
      if (section.pearl.rgb !== undefined) rgb(section.pearl.rgb, 'pearl');
    }
  }
  return document;
}

function readNativePaintjobs(root = DEFAULT_ROOT) {
  const directory = path.resolve(root), entries = [];
  if (!fs.existsSync(directory)) throw Error(`Native PaintJobs folder is unavailable: ${directory}`);
  function walk(folder) {
    for (const entry of fs.readdirSync(folder, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
      if (entry.isSymbolicLink() || entry.name.startsWith('.')) continue;
      const file = path.join(folder, entry.name);
      if (entry.isDirectory()) { walk(file); continue; }
      if (!entry.isFile() || path.extname(entry.name).toLowerCase() !== '.json') continue;
      const relative = path.relative(directory, file).split(path.sep).join('/');
      if (!relative || relative.split('/').some(part => part === '.' || part === '..')) throw Error('Paintjob escapes the requested folder');
      const data = fs.readFileSync(file);
      const document = validateNativePaintjob(JSON.parse(data.toString('utf8').replace(/^\uFEFF/, '')), relative);
      entries.push({ relative, folder: path.posix.dirname(relative), filename: entry.name, data, document, size: data.length, sha256: digest(data) });
    }
  }
  walk(directory);
  return entries;
}

module.exports = { DEFAULT_ROOT, validateNativePaintjob, readNativePaintjobs };

if (require.main === module) {
  if (process.argv.includes('--self-test')) {
    const assert = require('node:assert/strict');
    const valid = { format: 'scooby.paintjob', version: 2, name: 'Arctic Blue', colours: { primary: { custom: true, base: 0, rgb: [141, 220, 255], pearl: { enabled: false, colour: 0 } } } };
    assert.deepEqual(validateNativePaintjob(valid), valid);
    assert.throws(() => validateNativePaintjob({ ...valid, account_token: 'excluded' }), /Unsupported field/);
    assert.throws(() => validateNativePaintjob({ ...valid, colours: { primary: { rgb: [300, 0, 0] } } }), /Invalid RGB/);
    assert.throws(() => validateNativePaintjob({ ...valid, format: 'livery' }), /Unsupported native/);
    process.stdout.write('Native paintjob validator self-test passed.\n');
  } else {
    const entries = readNativePaintjobs(process.argv[2]);
    process.stdout.write(`${JSON.stringify({ items: entries.length, bytes: entries.reduce((sum, item) => sum + item.size, 0), folders: new Set(entries.map(item => item.folder)).size }, null, 2)}\n`);
  }
}
