'use strict';

// Asset-only exports from the explicitly requested native RDR2 addon library.
// Keep installed runtime resources and credits; omit editing projects, backups,
// disabled replacements, executables and unrelated application/account data.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const DEFAULT_ROOT = 'C:\\scooby\\RDR2\\Addons';
const PUBLIC_CACHE = path.resolve(__dirname, '../project/community-rdr2-addons/redm-object-sources.json');
const PUBLIC_REPOSITORY = 'Rexshack-RedM/rsg-farming';
const RUNTIME_TYPES = new Set(['.ydd', '.ytd', '.yft', '.ymt', '.ydr', '.ycd', '.ymap', '.ytyp', '.ybn', '.xml', '.txt', '.md']);
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const text = (xml, tag) => xml.match(new RegExp(`<${tag}[^>]*>([^<]+)</${tag}>`, 'i'))?.[1]?.trim() || '';
const slug = value => value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

function collectRdrAddonPacks(root = DEFAULT_ROOT) {
  if (!fs.existsSync(root)) return [];
  const packs = [];
  for (const directory of fs.readdirSync(root, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    if (!directory.isDirectory() || directory.isSymbolicLink() || directory.name.startsWith('.')) continue;
    const folder = path.join(root, directory.name), installFile = path.join(folder, 'install.xml');
    if (!fs.existsSync(installFile)) continue;
    const install = fs.readFileSync(installFile, 'utf8');
    if (!/<EasyInstall(?:\s|>)/i.test(install) || /<!DOCTYPE|<!ENTITY/i.test(install)) throw Error(`Unsupported addon install manifest: ${directory.name}`);
    const files = [], excluded = [];
    function walk(current) {
      for (const entry of fs.readdirSync(current, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
        const file = path.join(current, entry.name), relative = path.relative(folder, file).split(path.sep).join('/');
        if (entry.isSymbolicLink() || entry.name.startsWith('.') || relative.split('/').some(part => /^_KAYNAK$/i.test(part))) { excluded.push(relative); continue; }
        if (entry.isDirectory()) { walk(file); continue; }
        if (!entry.isFile() || !RUNTIME_TYPES.has(path.extname(entry.name).toLowerCase())) { excluded.push(relative); continue; }
        const data = fs.readFileSync(file);
        files.push({ name: `${directory.name}/${relative}`, data, relative, size: data.length, sha256: digest(data) });
      }
    }
    walk(folder);
    const names = new Set(files.map(file => file.relative));
    for (const match of install.matchAll(/<DataFile\b[^>]*>([^<]+)<\/DataFile>/gi)) {
      const relative = match[1].trim().replace(/\\/g, '/');
      if (!relative || relative.startsWith('/') || relative.split('/').includes('..') || !names.has(relative)) throw Error(`Missing declared RDR2 addon dependency: ${directory.name}/${relative}`);
    }
    const has = extension => files.some(file => path.posix.extname(file.relative).toLowerCase() === extension);
    const categories = [];
    if (/PED_METADATA_FILE/i.test(install) || has('.ydd')) categories.push('addon-peds');
    if (has('.ydr')) categories.push('addon-objects');
    if (has('.ycd')) categories.push('addon-animations');
    if (has('.ymap')) categories.push('addon-maps');
    if (!categories.length) continue;
    if (!files.some(file => ['.ydd', '.ydr', '.ycd', '.ymap'].includes(path.posix.extname(file.relative).toLowerCase()))) throw Error(`Addon has no model/animation/map payload: ${directory.name}`);
    packs.push({ id: slug(directory.name), name: text(install, 'Name') || directory.name, folder: directory.name,
      author: text(install, 'Author') || 'Original package authors', version: text(install, 'Version') || undefined,
      categories, files, excluded, bytes: files.reduce((sum, file) => sum + file.size, 0) });
  }
  return packs;
}

async function refreshPublicObjects() {
  const headers = { 'User-Agent': 'Scooby-Community-Catalog' };
  const getJSON = async url => {
    const response = await fetch(url, { headers, signal: AbortSignal.timeout(20000) });
    if (!response.ok) throw Error(`Public addon metadata HTTP ${response.status}`);
    return response.json();
  };
  const commit = await getJSON(`https://api.github.com/repos/${PUBLIC_REPOSITORY}/commits/main`);
  if (!/^[a-f0-9]{40}$/.test(commit.sha)) throw Error('Public addon source revision is invalid');
  const tree = await getJSON(`https://api.github.com/repos/${PUBLIC_REPOSITORY}/git/trees/${commit.sha}?recursive=1`);
  const selected = tree.tree.filter(item => /^stream\/[^/]+\.(ydr|ytd|ytyp)$/i.test(item.path));
  if (selected.filter(item => item.path.endsWith('.ydr')).length !== 6) throw Error('Unexpected public object model count');
  const files = await Promise.all(selected.map(async item => {
    const url = `https://raw.githubusercontent.com/${PUBLIC_REPOSITORY}/${commit.sha}/${item.path}`;
    const response = await fetch(url, { headers, signal: AbortSignal.timeout(20000) });
    if (!response.ok) throw Error(`Public object download HTTP ${response.status}`);
    const bytes = Buffer.from(await response.arrayBuffer());
    const gitBlob = crypto.createHash('sha1').update(`blob ${bytes.length}\0`).update(bytes).digest('hex');
    if (bytes.length !== item.size || gitBlob !== item.sha) throw Error(`Public object source hash mismatch: ${item.path}`);
    return { path: item.path, name: path.posix.basename(item.path), url, size: bytes.length, sha256: digest(bytes), gitBlobSha: gitBlob };
  }));
  const result = { version: 1, repository: PUBLIC_REPOSITORY, revision: commit.sha, verifiedAt: new Date().toISOString(), sourceUrl: `https://github.com/${PUBLIC_REPOSITORY}/tree/${commit.sha}/stream`,
    license: 'No redistribution license was established; these original public files are linked without mirroring.', files };
  fs.mkdirSync(path.dirname(PUBLIC_CACHE), { recursive: true });
  fs.writeFileSync(PUBLIC_CACHE, JSON.stringify(result, null, 2) + '\n');
  return result;
}

function collectPublicRedmObjects() {
  if (!fs.existsSync(PUBLIC_CACHE)) return { items: [], source: null };
  const source = JSON.parse(fs.readFileSync(PUBLIC_CACHE, 'utf8'));
  if (source.repository !== PUBLIC_REPOSITORY || !/^[a-f0-9]{40}$/.test(source.revision)) throw Error('Invalid cached public RedM object source');
  const files = source.files.map(file => {
    const expected = `https://raw.githubusercontent.com/${PUBLIC_REPOSITORY}/${source.revision}/${file.path}`;
    if (file.url !== expected || !/^stream\/[^/]+\.(ydr|ytd|ytyp)$/i.test(file.path) || !/^[a-f0-9]{64}$/.test(file.sha256)) throw Error('Invalid cached public RedM object file');
    return { url: file.url, name: file.name, size: file.size, sha256: file.sha256 };
  });
  const items = source.files.filter(file => file.path.endsWith('.ydr')).map(file => ({
    id: `redm-public-object-rsg-${path.posix.basename(file.name, '.ydr')}`, game: 'redm', category: 'addon-objects',
    name: `RSG farming prop ${file.name.match(/_(\d+)\.ydr$/)?.[1] || file.name}`,
    description: 'Native RedM prop from the original public RSG collection. Download the complete model, texture and archetype resource set together.',
    files, sourceUrl: source.sourceUrl, sourceFormat: 'RedM YDR/YTD/YTYP streaming resources', source: PUBLIC_REPOSITORY,
    credits: 'RexShack / RSG source collection; original author files linked directly.', license: source.license,
    model: path.posix.basename(file.name, '.ydr'), tags: ['RedM', 'object', 'prop', 'farming', 'plant', file.name, 'YDR', 'YTD', 'YTYP'],
    requirements: ['A compatible RedM server resource', 'Keep all supplied model/texture/archetype files in its stream folder', 'Register stream/prop_weed_ytyp.ytyp with the source resource’s DLC_ITYP_REQUEST data-file declaration'],
    compatibility: 'RedM streaming resource files verified against the public Git revision. Native single-player Scooby RDR2 import compatibility is not established.',
    guide: '/resources/guides/?game=redm&category=addon-objects',
  }));
  return { items, source };
}

module.exports = { DEFAULT_ROOT, collectRdrAddonPacks, collectPublicRedmObjects, refreshPublicObjects };
if (require.main === module) {
  if (process.argv.includes('--refresh-public')) {
    refreshPublicObjects().then(source => process.stdout.write(`${JSON.stringify({ repository: source.repository, revision: source.revision, files: source.files.length, bytes: source.files.reduce((sum, file) => sum + file.size, 0) }, null, 2)}\n`)).catch(error => { process.stderr.write(`${error.stack}\n`); process.exitCode = 1; });
  } else {
    const packs = collectRdrAddonPacks(process.argv[2]);
    process.stdout.write(`${JSON.stringify({ packs: packs.map(pack => ({ id: pack.id, name: pack.name, categories: pack.categories, files: pack.files.length, bytes: pack.bytes, excluded: pack.excluded })) }, null, 2)}\n`);
  }
}
