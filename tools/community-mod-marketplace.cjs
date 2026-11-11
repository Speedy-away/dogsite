'use strict';

// Public catalog metadata and limited signature probes only. No mod payload is
// stored, installed or executed. The main importer owns download-repo writes.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const ROOT = path.resolve(__dirname, '..');
const CACHE = path.join(ROOT, 'project/community-marketplace');
const REPOSITORY = 'xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace';
const REPO_URL = `https://github.com/${REPOSITORY}`;
const MODS_ORIGIN = 'https://www.gta5-mods.com';
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/130.0.0.0 Safari/537.36';
const FEEDS = [
  { route: 'vehicles', category: 'addon-vehicles', kind: 'Vehicle model', tags: ['vehicle', 'model', 'addon', 'replacement'] },
  { route: 'player', category: 'addon-peds', kind: 'Player or ped asset', tags: ['ped', 'player', 'model'] },
  { route: 'player/tags/clothing', category: 'addon-clothing', kind: 'Clothing asset', tags: ['clothing', 'wardrobe', 'model', 'texture'] },
  { route: 'maps', category: 'addon-maps', kind: 'Map resource', tags: ['map', 'addon'] },
  { route: 'maps/tags/ymap', category: 'addon-maps', kind: 'YMAP map resource', tags: ['map', 'YMAP', 'addon'] },
  { route: 'maps/tags/menyoo', category: 'maps', kind: 'Menyoo map', tags: ['Menyoo', 'XML', 'Object Spooner'] },
  { route: 'maps/tags/simple-trainer', category: 'maps', kind: 'Simple Trainer map', tags: ['Simple Trainer', 'placement'] },
  { route: 'paintjobs', category: 'liveries', kind: 'Vehicle livery', tags: ['livery', 'paintjob', 'texture'] },
  { route: 'misc/tags/prop', category: 'addon-objects', kind: 'Object or prop asset', tags: ['prop', 'object', 'addon'] },
  { route: 'misc/tags/animation', category: 'addon-animations', kind: 'Animation resource', tags: ['animation', 'motion'] },
  { route: 'scripts/tags/asi', category: 'asi-mods', kind: 'ASI mod', tags: ['ASI', 'Script Hook V', 'plugin'] },
  { route: 'scripts/tags/.net', category: 'dotnet-mods', kind: '.NET mod', tags: ['.NET', 'ScriptHookVDotNet', 'plugin'] },
];
const TOOLS = [
  { route: 'scripts/menyoo-2-0', category: 'asi-mods', name: 'Menyoo 2.0', creator: 'MAFINS, ItsJustCurtis and contributors',
    tags: ['Menyoo', 'trainer', 'Object Spooner', 'XML', 'ASI'], releaseRepository: 'ItsJustCurtis/MenyooSP',
    requirements: ['A compatible current Script Hook V', 'An ASI loader for the selected game edition', 'Follow the author’s Windows 11 and edition-specific instructions'] },
  { route: 'scripts/rampage-trainer', category: 'asi-mods', name: 'Rampage Trainer', creator: 'RampageDev',
    tags: ['Rampage', 'trainer', 'ASI'], requirements: ['Script Hook V and its ASI loader', 'Choose the author’s Legacy or Enhanced package'] },
  { route: 'scripts/simple-trainer-for-gtav', category: 'asi-mods', name: 'Simple Trainer for GTA V', creator: 'sjaak327',
    tags: ['Simple Trainer', 'trainer', 'ASI', 'INI'], requirements: ['The loader and game build required by the author', 'Keep the trainer’s supporting configuration files'] },
  { route: 'tools/script-hook-v', category: 'asi-mods', name: 'Script Hook V + Native Trainer', creator: 'Alexander Blade',
    tags: ['Script Hook V', 'ASI loader', 'Native Trainer', 'dependency'], requirements: ['Match Script Hook V to the installed GTA V build', 'Follow the original developer’s installation instructions'] },
  { route: 'tools/scripthookv-net', category: 'dotnet-mods', name: 'Community Script Hook V .NET', creator: 'crosire and contributors',
    tags: ['ScriptHookVDotNet', '.NET', 'dependency'], releaseRepository: 'scripthookvdotnet/scripthookvdotnet', requirements: ['A compatible Script Hook V installation', 'The .NET and Visual C++ runtime versions listed by the maintainer'] },
  { route: 'tools/script-hook-v-net-enhanced', category: 'dotnet-mods', name: 'Script Hook V .NET Enhanced', creator: 'Chiheb-Bacha and contributors',
    tags: ['ScriptHookVDotNetEnhanced', '.NET', 'Legacy', 'Enhanced', 'dependency'], releaseRepository: 'Chiheb-Bacha/ScriptHookVDotNetEnhanced', requirements: ['A compatible Script Hook V installation', 'Follow the maintainer’s runtime and package dependency instructions'] },
];

function decode(value = '') {
  return String(value).replace(/&#(x[\da-f]+|\d+);/gi, (_, number) => {
    const code = /^x/i.test(number) ? parseInt(number.slice(1), 16) : Number(number);
    return code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : '';
  }).replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&apos;|&#39;/g, "'")
    .replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}
function plain(value) { return decode(String(value || '').replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim(); }
function attributes(tag) {
  return Object.fromEntries([...tag.matchAll(/([\w:-]+)\s*=\s*(["'])(.*?)\2/g)].map(match => [match[1].toLowerCase(), decode(match[3])]));
}
function https(value, base) {
  if (!value) return undefined;
  const url = new URL(value, base);
  if (url.protocol !== 'https:' || url.username || url.password) throw Error(`Unsafe public metadata URL: ${value}`);
  return url.href;
}
function slug(value) {
  return String(value).normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'resource';
}
function hash(value) { return crypto.createHash('sha256').update(value).digest('hex'); }

function parseListing(html, feed) {
  const cards = html.split(/<div\s+class=["']file-list-obj["']\s*>/i).slice(1);
  const items = [];
  for (const card of cards) {
    const previewTag = [...card.matchAll(/<a\b[^>]*>/gi)].map(match => attributes(match[0]))
      .find(tag => /\bpreview\b/.test(tag.class || ''));
    if (!previewTag?.href || !previewTag.title) continue;
    const url = new URL(previewTag.href, MODS_ORIGIN);
    if (url.origin !== MODS_ORIGIN || !/^\/(vehicles|player|maps|paintjobs|scripts|misc)\/[^/]+$/.test(url.pathname)) continue;
    const preview = attributes(card.match(/<img\b[^>]*>/i)?.[0] || '');
    const author = card.match(/<a\b[^>]*href=["'](\/users\/[^"']+)["'][^>]*>([\s\S]*?)<\/a>/i);
    const tagsBlock = card.match(/<ul\b[^>]*class=["']categories["'][^>]*>([\s\S]*?)<\/ul>/i)?.[1] || '';
    const tags = [...tagsBlock.matchAll(/<li\b[^>]*>([\s\S]*?)<\/li>/gi)].map(match => plain(match[1]));
    if (tags.some(tag => /^(?:lua|gtalua)$/i.test(tag))) continue;
    const version = plain(card.match(/<div\b[^>]*class=["']version["'][^>]*>([\s\S]*?)<\/div>/i)?.[1]);
    items.push({ name: plain(previewTag.title), sourceUrl: url.href, creator: author ? plain(author[2]) : 'See source author',
      authorUrl: author ? https(author[1], MODS_ORIGIN) : undefined,
      preview: preview.src ? https(preview.src, MODS_ORIGIN) : undefined,
      tags: [...new Set([...feed.tags, ...tags])], category: feed.category, kind: feed.kind, version,
      edition: tags.some(tag => /enhanced/i.test(tag)) ? 'Enhanced listed by author; check package variant' : 'Check the author’s supported edition and game build',
      listingUrl: feed.url });
  }
  return items;
}

function parseTool(html, tool) {
  const meta = [...html.matchAll(/<meta\b[^>]*>/gi)].map(match => attributes(match[0]));
  const get = name => meta.find(tag => (tag.property || tag.name) === name)?.content;
  const headings = [...html.matchAll(/<h1\b[^>]*>([\s\S]*?)<\/h1>/gi)].map(match => plain(match[1]));
  const title = plain(get('og:title')) || headings.find(heading => !/welcome to/i.test(heading)) || tool.name;
  if (!html.includes('file-title') && !get('og:title') && !/<h1/i.test(html)) throw Error(`Missing mod detail metadata: ${tool.route}`);
  return { ...tool, name: title.replace(/\s*-\s*GTA5-Mods\.com$/i, ''), sourceUrl: `${MODS_ORIGIN}/${tool.route}`,
    preview: get('og:image') ? https(get('og:image'), MODS_ORIGIN) : undefined,
    kind: /Trainer/.test(tool.name) ? 'Story Mode trainer' : 'Mod loader',
    edition: /Enhanced|Legacy/i.test(title) ? 'Edition variants listed by the author; choose the matching package' : 'Check the author’s supported edition and game build' };
}

async function fetchText(url) {
  const requested = new URL(https(url));
  const allowed = new Set(['api.github.com', 'raw.githubusercontent.com', 'www.gta5-mods.com']);
  if (!allowed.has(requested.hostname)) throw Error(`Unexpected metadata source: ${requested.hostname}`);
  const response = await fetch(requested, { signal: AbortSignal.timeout(25000), headers: {
    'User-Agent': USER_AGENT, Accept: 'application/json,text/html;q=0.9,*/*;q=0.1',
  } });
  if (!response.ok) throw Error(`Public metadata request failed (${response.status}): ${url}`);
  if (!allowed.has(new URL(response.url).hostname)) throw Error(`Unexpected metadata redirect: ${response.url}`);
  const text = await response.text();
  if (Buffer.byteLength(text) > 12 * 1024 * 1024) throw Error(`Metadata response is unexpectedly large: ${url}`);
  return text;
}
async function mapLimited(values, callback, concurrency = 3) {
  const output = new Array(values.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(concurrency, values.length) }, async () => {
    for (;;) {
      const index = next++;
      if (index >= values.length) return;
      output[index] = await callback(values[index], index);
    }
  }));
  return output;
}

const DIRECT_HOSTS = new Set(['files.gta5-mods.com', 'github.com', 'release-assets.githubusercontent.com', 'objects.githubusercontent.com']);
const PUBLIC_FLOW_HOSTS = new Set(['www.gta5-mods.com', 'api.github.com', ...DIRECT_HOSTS]);
const ARCHIVE_MIME = /^(?:application\/(?:zip|x-zip-compressed|x-rar-compressed|vnd\.rar|x-7z-compressed|octet-stream|binary)|binary\/octet-stream)(?:;|$)/i;
let nextAuthorRequest = 0;
let authorRequestInterval = 2800;
const pause = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

async function paceAuthorRequests(host) {
  if (host !== 'www.gta5-mods.com') return;
  const start = Math.max(Date.now(), nextAuthorRequest);
  nextAuthorRequest = start + authorRequestInterval;
  if (start > Date.now()) await pause(start - Date.now());
}

function packageKind(prefix) {
  if (prefix.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x03, 0x04])) ||
      prefix.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x05, 0x06])) ||
      prefix.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x07, 0x08]))) return 'zip';
  if (prefix.subarray(0, 6).equals(Buffer.from([0x52, 0x61, 0x72, 0x21, 0x1a, 0x07]))) return 'rar';
  if (prefix.subarray(0, 6).equals(Buffer.from([0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c]))) return '7z';
  if (prefix[0] === 0x4d && prefix[1] === 0x5a) return 'native-plugin';
  return '';
}

function cookieValues(headers) {
  const values = headers.getSetCookie ? headers.getSetCookie() : [headers.get('set-cookie')].filter(Boolean);
  return values.map(value => value.split(';', 1)[0]).filter(value => value.includes('='));
}

async function publicRequest(url, { method = 'GET', referer, jar = new Map(), range } = {}) {
  let current = https(url);
  for (let hop = 0; hop < 7; hop++) {
    const parsed = new URL(current);
    if (!PUBLIC_FLOW_HOSTS.has(parsed.hostname)) throw Error(`Download host is not permitted: ${parsed.hostname}`);
    const headers = { 'User-Agent': USER_AGENT, Accept: 'text/html,application/octet-stream,application/json;q=0.9,*/*;q=0.8' };
    if (referer) headers.Referer = referer;
    if (range) headers.Range = range;
    if (parsed.hostname === 'www.gta5-mods.com' && jar.size) headers.Cookie = [...jar.values()].join('; ');
    await paceAuthorRequests(parsed.hostname);
    const response = await fetch(current, { method, headers, redirect: 'manual', signal: AbortSignal.timeout(25000) });
    if (parsed.hostname === 'www.gta5-mods.com') for (const cookie of cookieValues(response.headers)) jar.set(cookie.slice(0, cookie.indexOf('=')), cookie);
    if ([301, 302, 303, 307, 308].includes(response.status)) {
      const location = response.headers.get('location');
      if (!location) throw Error('Public redirect has no destination');
      await response.body?.cancel();
      current = https(location, current);
      continue;
    }
    return { response, url: current };
  }
  throw Error('Too many public download redirects');
}

async function textResponse(result, context) {
  if (result.response.status !== 200) {
    const retryAfter = result.response.headers.get('retry-after');
    await result.response.body?.cancel();
    const error = Error(`${context}: HTTP ${result.response.status}`);
    if (result.response.status === 429) {
      const seconds = /^\d+$/.test(retryAfter || '') ? Number(retryAfter) : Math.ceil((Date.parse(retryAfter) - Date.now()) / 1000);
      error.rateLimited = true;
      error.retryAfterMs = Math.max(60000, Number.isFinite(seconds) ? seconds * 1000 : 0);
    }
    throw error;
  }
  const body = await result.response.text();
  if (Buffer.byteLength(body) > 4 * 1024 * 1024) throw Error(`${context}: unexpectedly large HTML response`);
  if (/cf-chl-|g-recaptcha|hcaptcha|verify you are human|captcha-container/i.test(body)) throw Error(`${context}: human verification required`);
  return body;
}

function directLinks(html) {
  return [...html.replace(/\\\//g, '/').matchAll(/https:\/\/(?:files\.gta5-mods\.com|github\.com)\/[^\s<>"']+/gi)]
    .map(match => decode(match[0]).replace(/[),;]+$/, ''))
    .filter(url => new URL(url).hostname === 'files.gta5-mods.com' || /\/releases\/download\//.test(url));
}

async function verifyDirectDownload(url, { referer, jar } = {}) {
  if (!DIRECT_HOSTS.has(new URL(https(url)).hostname)) throw Error('Not a permitted public file host');
  const head = await publicRequest(url, { method: 'HEAD', referer, jar });
  const contentType = (head.response.headers.get('content-type') || '').toLowerCase();
  if (head.response.status !== 200 || !ARCHIVE_MIME.test(contentType)) {
    throw Error(`File HEAD is not an archive response: HTTP ${head.response.status}, ${contentType || 'no MIME'}`);
  }
  const probe = await publicRequest(url, { referer, jar, range: 'bytes=0-15' });
  if (![200, 206].includes(probe.response.status)) throw Error(`File range probe failed: HTTP ${probe.response.status}`);
  if (!ARCHIVE_MIME.test(probe.response.headers.get('content-type') || '')) {
    await probe.response.body?.cancel();
    throw Error('File range probe returned a non-archive MIME type');
  }
  const reader = probe.response.body.getReader();
  let prefix;
  try { prefix = Buffer.from((await reader.read()).value || []); }
  finally { await reader.cancel(); }
  const kind = packageKind(prefix);
  if (!kind) throw Error('File response does not have a ZIP, RAR, 7z or native-plugin header');
  const disposition = head.response.headers.get('content-disposition') || '';
  const encoded = disposition.match(/filename\*=UTF-8''([^;]+)/i)?.[1];
  const simple = disposition.match(/filename\s*=\s*"([^"]+)"|filename\s*=\s*([^;]+)/i);
  let name = encoded ? decodeURIComponent(encoded) : simple ? (simple[1] || simple[2]).trim() : decodeURIComponent(new URL(head.url).pathname.split('/').pop());
  name = name.replace(/[\\/\x00-\x1f]/g, '_');
  if (!/\.(?:zip|rar|7z|oiv|asi|dll)$/i.test(name)) throw Error('Verified file has no supported archive/plugin filename');
  if (kind === 'native-plugin' && !/\.(?:asi|dll)$/i.test(name)) throw Error('An executable response is not an ASI or .NET plugin');
  const length = Number(head.response.headers.get('content-length'));
  const final = new URL(head.url);
  // GitHub release CDN URLs contain expiring signatures. Keep the stable public
  // releases/download URL, after verifying the redirected binary response.
  const stable = new URL(url).hostname === 'github.com' ? https(url) : https(head.url);
  return { status: 'verified', url: stable, name, ...(Number.isSafeInteger(length) && length > 0 ? { size: length } : {}),
    contentType, contentDisposition: disposition, attachmentDisposition: /\battachment\b/i.test(disposition),
    packageKind: kind, resolvedHost: final.hostname, responseStatus: head.response.status,
    probeStatus: probe.response.status, verifiedAt: new Date().toISOString() };
}

async function resolveAuthorDownload(item) {
  const sourceUrl = https(item.sourceUrl);
  if (new URL(sourceUrl).origin !== MODS_ORIGIN) throw Error('Unexpected public author page');
  const releaseRepository = item.releaseRepository || TOOLS.find(tool => `${MODS_ORIGIN}/${tool.route}` === sourceUrl)?.releaseRepository;
  const errors = [];
  // These are the trainers' documented original-maintainer release feeds, not
  // mirrors of a rate-limited author page. Prefer their stable release assets.
  if (releaseRepository && /^[\w.-]+\/[\w.-]+$/.test(releaseRepository)) {
    try {
      const data = JSON.parse(await textResponse(await publicRequest(`https://api.github.com/repos/${releaseRepository}/releases/latest`), 'Public GitHub release'));
      const assets = (data.assets || []).filter(asset => /\.(?:zip|rar|7z)$/i.test(asset.name));
      for (const asset of assets) {
        try { return await verifyDirectDownload(asset.browser_download_url, { referer: sourceUrl }); }
        catch (error) { errors.push(error.message); }
      }
    } catch (error) { errors.push(error.message); }
  }
  const jar = new Map();
  const detail = await textResponse(await publicRequest(sourceUrl, { jar }), 'Author page');
  const button = [...detail.matchAll(/<a\b[^>]*>/gi)].map(match => attributes(match[0]))
    .find(tag => /\bbtn-download\b/.test(tag.class || '') && tag.href);
  const links = directLinks(detail);
  if (button) {
    const handoffUrl = https(button.href, sourceUrl);
    if (DIRECT_HOSTS.has(new URL(handoffUrl).hostname)) links.unshift(handoffUrl);
    else if (new URL(handoffUrl).origin === MODS_ORIGIN) {
      const handoff = await publicRequest(handoffUrl, { jar, referer: sourceUrl });
      if (DIRECT_HOSTS.has(new URL(handoff.url).hostname)) {
        await handoff.response.body?.cancel();
        links.unshift(handoff.url);
      } else links.unshift(...directLinks(await textResponse(handoff, 'Public download handoff')));
    }
  }
  for (const candidate of [...new Set(links)]) {
    try { return await verifyDirectDownload(candidate, { jar, referer: sourceUrl }); }
    catch (error) { errors.push(error.message); }
  }
  throw Error(errors[0] || 'No directly downloadable public archive was available');
}

async function resolveDirectDownloads({ cacheDirectory = CACHE, force = false, limit = 80 } = {}) {
  const snapshot = JSON.parse(fs.readFileSync(path.join(cacheDirectory, 'gta5-mods.json'), 'utf8'));
  const cacheFile = path.join(cacheDirectory, 'direct-downloads.json');
  const previous = fs.existsSync(cacheFile) ? JSON.parse(fs.readFileSync(cacheFile, 'utf8')) : {};
  const entries = { ...(previous.entries || {}) }, failures = { ...(previous.failures || {}) };
  const listed = new Map();
  for (const feed of snapshot.feeds) for (const item of feed.items) if (!listed.has(item.sourceUrl)) listed.set(item.sourceUrl, item);
  for (const item of snapshot.tools) listed.set(item.sourceUrl, { ...listed.get(item.sourceUrl), ...item });
  if (!Number.isSafeInteger(limit) || limit < 1) throw Error('Download resolution limit must be a positive integer');
  let completed = 0, attempted = 0, rateLimited = false;
  const persist = () => {
    const temporary = `${cacheFile}.tmp`;
    fs.writeFileSync(temporary, JSON.stringify({ version: 1, updatedAt: new Date().toISOString(), entries, failures }));
    fs.renameSync(temporary, cacheFile);
  };
  const grouped = new Map();
  for (const item of listed.values()) {
    const key = item.category;
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(item);
  }
  const ordered = [...snapshot.tools];
  const seen = new Set(ordered.map(item => item.sourceUrl));
  for (let row = 0; [...grouped.values()].some(group => row < group.length); row++) {
    for (const group of grouped.values()) if (group[row] && !seen.has(group[row].sourceUrl)) {
      ordered.push(group[row]); seen.add(group[row].sourceUrl);
    }
  }
  await mapLimited(ordered, async item => {
    if (!force && entries[item.sourceUrl]?.status === 'verified') { completed++; return; }
    if (!force && failures[item.sourceUrl] && !/HTTP 429|timeout|fetch failed|not been verified/i.test(failures[item.sourceUrl].reason)) { completed++; return; }
    if (rateLimited || attempted >= limit) return;
    attempted++;
    try {
      for (let attempt = 0; ; attempt++) {
        try { entries[item.sourceUrl] = await resolveAuthorDownload(item); delete failures[item.sourceUrl]; break; }
        catch (error) {
          if (!error.rateLimited || attempt >= 2) throw error;
          authorRequestInterval = Math.min(10000, authorRequestInterval * 2);
          persist();
          process.stdout.write(`Author host requested a pause; waiting ${Math.ceil(error.retryAfterMs / 1000)} seconds before a paced retry.\n`);
          await pause(error.retryAfterMs);
        }
      }
    } catch (error) {
      delete entries[item.sourceUrl];
      failures[item.sourceUrl] = { reason: error.message, checkedAt: new Date().toISOString() };
      if (error.rateLimited) {
        rateLimited = true;
        process.stdout.write('Author host remains rate limited; stopping requests and preserving the resumable cache.\n');
      }
    }
    completed++;
    persist();
    if (completed % 20 === 0) {
      process.stdout.write(`Resolved ${completed}/${listed.size}: ${Object.keys(entries).length} verified, ${Object.keys(failures).length} unavailable.\n`);
    }
  }, 1);
  persist();
  return { listed: listed.size, attempted, verified: [...listed.keys()].filter(url => entries[url]?.status === 'verified').length, rateLimited,
    failures: [...listed.keys()].filter(url => failures[url]).map(url => ({ sourceUrl: url, ...failures[url] })) };
}

async function refreshMarketplace(cacheDirectory = CACHE) {
  const commit = JSON.parse(await fetchText(`https://api.github.com/repos/${REPOSITORY}/commits/main`));
  if (!/^[a-f0-9]{40}$/.test(commit.sha)) throw Error('Missing public repository revision');
  const tree = JSON.parse(await fetchText(`https://api.github.com/repos/${REPOSITORY}/git/trees/${commit.sha}?recursive=1`));
  if (tree.truncated) throw Error('Marketplace file tree is truncated');
  const paths = tree.tree.filter(entry => entry.type === 'blob').map(entry => entry.path);
  const catalogPaths = paths.filter(file => /^marketplace\/(vehicles|outfits|dlcs|themes)\/catalog(?:-\d+)?\.json$/.test(file)).sort();
  const catalogs = await mapLimited(catalogPaths, async file => ({ path: file,
    url: `https://raw.githubusercontent.com/${REPOSITORY}/${commit.sha}/${file}`,
    data: JSON.parse(await fetchText(`https://raw.githubusercontent.com/${REPOSITORY}/${commit.sha}/${file}`)),
  }));
  const modverse = { version: 1, repository: REPOSITORY, revision: commit.sha, fetchedAt: new Date().toISOString(),
    paths: paths.filter(file => /^marketplace\/(vehicles|outfits|dlcs)\/(?:files|thumbnails)\//.test(file) || /^[\d-]+\.jpg$/.test(file)), catalogs };
  const feeds = FEEDS.flatMap(feed => ['most-downloaded', 'latest-uploads'].map(sort => ({ ...feed, sort, url: `${MODS_ORIGIN}/${feed.route}/${sort}` })));
  const feedResults = await mapLimited(feeds, async feed => {
    const items = parseListing(await fetchText(feed.url), feed);
    if (!items.length) throw Error(`No public listing cards found at ${feed.url}; refusing to publish an empty refresh`);
    return { url: feed.url, route: feed.route, category: feed.category, items };
  });
  const tools = await mapLimited(TOOLS, async tool => parseTool(await fetchText(`${MODS_ORIGIN}/${tool.route}`), tool));
  const gta5mods = { version: 1, fetchedAt: new Date().toISOString(), feeds: feedResults, tools };
  fs.mkdirSync(cacheDirectory, { recursive: true });
  fs.writeFileSync(path.join(cacheDirectory, 'modverse.json'), JSON.stringify(modverse));
  fs.writeFileSync(path.join(cacheDirectory, 'gta5-mods.json'), JSON.stringify(gta5mods));
  return buildMarketplaceItems({ cacheDirectory });
}

function buildMarketplaceItems({ cacheDirectory = CACHE } = {}) {
  const modverse = JSON.parse(fs.readFileSync(path.join(cacheDirectory, 'modverse.json'), 'utf8'));
  const gta5mods = JSON.parse(fs.readFileSync(path.join(cacheDirectory, 'gta5-mods.json'), 'utf8'));
  const directFile = path.join(cacheDirectory, 'direct-downloads.json');
  const direct = fs.existsSync(directFile) ? JSON.parse(fs.readFileSync(directFile, 'utf8')) : { entries: {}, failures: {} };
  // GTA5-Mods calls its livery feed "paintjobs". Keep that source route intact,
  // while separating these texture assets from Scooby's native LSC paint presets.
  for (const feed of gta5mods.feeds) {
    const sourceCategories = { paintjobs: 'liveries', 'player/tags/clothing': 'addon-clothing', maps: 'addon-maps', 'maps/tags/ymap': 'addon-maps', 'misc/tags/prop': 'addon-objects', 'misc/tags/animation': 'addon-animations' };
    if (sourceCategories[feed.route]) feed.category = sourceCategories[feed.route];
    for (const item of feed.items) {
      if (sourceCategories[feed.route]) item.category = sourceCategories[feed.route];
      if (new URL(item.sourceUrl).pathname.startsWith('/paintjobs/')) {
        item.category = 'liveries';
        item.kind = 'Vehicle livery';
      }
    }
  }
  if (modverse.repository !== REPOSITORY || !/^[a-f0-9]{40}$/.test(modverse.revision)) throw Error('Invalid marketplace snapshot provenance');
  const paths = new Set(modverse.paths);
  const raw = `https://raw.githubusercontent.com/${REPOSITORY}/${modverse.revision}/`;
  const items = [], ids = new Set(), excluded = [];
  function add(item) {
    if (ids.has(item.id)) throw Error(`Duplicate marketplace identity: ${item.id}`);
    if (item.category === 'lua' || /\.lua(?:$|[?#])/i.test(item.sourceUrl || '')) throw Error('Lua imports are disabled');
    ids.add(item.id);
    items.push({ game: 'gta5', menu: 'Scooby', files: [], guide: '/resources/guides/?game=gta5', ...item });
  }
  const sourceCounts = {};
  for (const catalog of modverse.catalogs) {
    const kind = catalog.path.split('/')[1];
    sourceCounts[kind] = (sourceCounts[kind] || 0) + (catalog.data.items || []).length;
    // Cherax ClickGUI themes are not Scooby themes. Preserve their source metadata
    // in the catalog snapshot without advertising them as native downloads.
    if (kind === 'themes') continue;
    if (!catalog.data.published || !Array.isArray(catalog.data.items)) throw Error(`Unpublished or invalid source catalog: ${catalog.path}`);
    for (const item of catalog.data.items) {
      if (!item.id || !/^[a-f0-9]{64}$/.test(item.sha256) || !Number.isSafeInteger(item.size_bytes)) throw Error(`Invalid public catalog entry in ${catalog.path}`);
      if (!plain(item.name)) { excluded.push({ id: item.id, reason: 'Source display name is empty' }); continue; }
      const possible = [`marketplace/${kind}/files/${item.id}.json`, `marketplace/${kind}/files/${item.filename}`];
      const asset = possible.find(file => paths.has(file));
      let download = item.download_url;
      if (!download && item.release_tag && item.asset_name) download = `${REPO_URL}/releases/download/${encodeURIComponent(item.release_tag)}/${encodeURIComponent(item.asset_name)}`;
      if (!download && asset) download = raw + asset;
      if (!download) throw Error(`No public asset URL for ${kind}/${item.id}`);
      let preview = item.thumbnail_url;
      if (!preview) {
        const candidates = [item.thumbnail, ...['jpg', 'png', 'webp'].map(ext => `marketplace/${kind}/thumbnails/${item.id}.${ext}`), `${item.id}.jpg`].filter(Boolean);
        const file = candidates.find(candidate => paths.has(candidate));
        if (file) preview = raw + file;
      }
      const category = kind === 'vehicles' ? 'vehicles' : kind === 'outfits' ? 'outfits' : 'misc';
      const author = item.creator || 'Original creator unverified';
      const uploader = item.shared_by;
      const format = kind === 'vehicles' ? 'Cherax vehicle JSON' : kind === 'outfits' ? 'Cherax outfit JSON' : 'RPF7 addon package';
      const sourceUrl = asset ? `${REPO_URL}/blob/${modverse.revision}/${asset}` : `${REPO_URL}/releases/tag/${encodeURIComponent(item.release_tag)}`;
      add({ id: `gta5-modverse-${kind}-${item.id}`, category, name: plain(item.name),
        description: `${format} from the public ModVerse catalog. Keep the original format and use a matching supported importer.`,
        // Several published JSON files have Git-normalized line endings and no
        // longer match the publisher's byte checksum. Keep that source claim
        // separate from the actual download contract rather than advertising it
        // as a verified checksum for the URL served by GitHub.
        status: 'download', downloadsOnScooby: true,
        files: [{ url: https(download), name: item.filename || item.asset_name || path.posix.basename(new URL(download).pathname) }],
        publisherChecksum: { sha256: item.sha256, size: item.size_bytes, verification: 'Publisher metadata; not independently verified for the served URL' },
        preview: preview ? https(preview) : undefined, sourceUrl: https(sourceUrl),
        source: 'ModVerse public catalog', format, sourceFormat: format,
        credits: `${author}${uploader && uploader !== author ? `; shared by ${uploader}` : ''}`,
        compatibility: kind === 'dlcs' ? 'RPF7 header checked by publisher; game runtime unverified. Follow the source package and edition requirements.' : `${format}; use Scooby only where its matching importer supports this structure. Game runtime compatibility is not independently verified.`,
        sourceCompatibility: item.compatibility_status,
        requirements: kind === 'dlcs' ? ['An edition-compatible addon loader', 'The original package instructions'] : ['A compatible saved-resource importer', 'The intended character or vehicle model'],
        edition: 'Not established by the source catalog; check the package and importer',
        license: 'Original author terms apply; linked to the publisher’s files without mirroring them.',
        permissionBasis: item.permission_basis || catalog.data.license_policy || 'See source catalog',
        creatorCreditBasis: item.creator_credit_basis || 'See source catalog',
        tags: ['ModVerse', format, kind === 'dlcs' ? 'DLC' : 'preset', author, uploader, item.model && String(item.model)].filter(Boolean),
        guide: `/resources/guides/?game=gta5&category=${category}` });
    }
  }
  const listed = new Map();
  for (const feed of gta5mods.feeds) for (const item of feed.items) {
    if (listed.has(item.sourceUrl)) {
      const previous = listed.get(item.sourceUrl);
      previous.tags = [...new Set([...previous.tags, ...item.tags])];
      continue;
    }
    listed.set(item.sourceUrl, item);
  }
  for (const tool of gta5mods.tools) listed.set(tool.sourceUrl, { ...listed.get(tool.sourceUrl), ...tool });
  for (const item of listed.values()) {
    const sourceUrl = https(item.sourceUrl);
    if (new URL(sourceUrl).origin !== MODS_ORIGIN) throw Error(`Unexpected GTA5-Mods source ${sourceUrl}`);
    const download = direct.entries[sourceUrl];
    if (download?.status !== 'verified') {
      excluded.push({ sourceUrl, reason: direct.failures[sourceUrl]?.reason || 'Public direct download has not been verified' });
      continue;
    }
    const itemTags = item.tags || [];
    const clothing = itemTags.some(tag => /^(?:clothing|shoes|mask|helmet|hair|eyes|tattoo|watch|jewellery|wardrobe)$/i.test(tag));
    const placement = itemTags.some(tag => /^(?:Menyoo|Simple Trainer|XML|INI|Object Spooner)$/i.test(tag));
    const addonMap = itemTags.some(tag => /^(?:YMAP|MLO)$/i.test(tag));
    let category = new URL(sourceUrl).pathname.startsWith('/paintjobs/') ? 'liveries' : item.category;
    if (new URL(sourceUrl).pathname.startsWith('/player/') && clothing) category = 'addon-clothing';
    if (new URL(sourceUrl).pathname.startsWith('/maps/')) category = placement ? 'maps' : 'addon-maps';
    const requirements = item.requirements || (category === 'asi-mods'
      ? ['The author’s matching ASI loader and Script Hook V requirements', 'A supported GTA V game build']
      : category === 'dotnet-mods' ? ['The author’s required .NET script host and runtime', 'A compatible Script Hook V installation']
        : category === 'liveries' ? ['The exact target vehicle model specified by the author', 'The author’s texture or livery installation workflow']
        : ['The loader or importer specified by the author', 'The target model, dependencies and game edition']);
    add({ id: `gta5-mods-${slug(new URL(sourceUrl).pathname)}-${hash(sourceUrl).slice(0, 8)}`, category, name: item.name,
      status: 'download', downloadsOnScooby: true, sourceUrl, source: 'GTA5-Mods', preview: item.preview ? https(item.preview) : undefined,
      files: [{ url: https(download.url), name: download.name, ...(download.size ? { size: download.size } : {}), downloadMethod: 'direct', contentType: download.contentType, packageKind: download.packageKind }],
      format: `${download.packageKind.toUpperCase()} package`, sourceFormat: `${download.packageKind.toUpperCase()} package`,
      downloadVerification: { responseStatus: download.responseStatus, probeStatus: download.probeStatus, resolvedHost: download.resolvedHost, verifiedAt: download.verifiedAt, attachmentDisposition: download.attachmentDisposition },
      ...(category === 'maps' && addonMap ? { categories: ['maps', 'addon-maps'] } : {}),
      description: `${item.kind || 'GTA V resource'} by ${item.creator}. Includes the original package; follow its installation instructions and edition requirements.`,
      credits: item.creator, authorUrl: item.authorUrl, edition: item.edition, version: item.version,
      requirements, compatibility: category === 'liveries'
        ? 'Vehicle texture or livery artwork. Follow the target vehicle and author’s installation instructions; these are separate from Scooby LSC PaintJobs presets.'
        : 'Third-party GTA V resource. Match the edition and loader on the author page; availability here does not establish native Scooby compatibility.',
      tags: [...new Set(['GTA5-Mods', ...(item.tags || []), item.creator])],
      license: 'Original author terms apply. The original package is delivered by the publisher’s public file host.',
      guide: `/resources/guides/?game=gta5&category=${category}` });
  }
  return { items, sourceCounts, excluded, sources: [
    { path: 'catalog/marketplace/modverse-source.json', data: fs.readFileSync(path.join(cacheDirectory, 'modverse.json')) },
    { path: 'catalog/marketplace/gta5-mods-source.json', data: Buffer.from(JSON.stringify(gta5mods)) },
    ...(fs.existsSync(directFile) ? [{ path: 'catalog/marketplace/direct-downloads-source.json', data: fs.readFileSync(directFile) }] : []),
  ], summary: { items: items.length, modverse: items.filter(item => item.id.startsWith('gta5-modverse-')).length,
    gta5mods: items.filter(item => item.id.startsWith('gta5-mods-')).length, excluded: excluded.length,
    byCategory: items.reduce((out, item) => (out[item.category] = (out[item.category] || 0) + 1, out), {}) } };
}

module.exports = { refreshMarketplace, buildMarketplaceItems, resolveDirectDownloads, resolveAuthorDownload, verifyDirectDownload, parseListing, parseTool, FEEDS, TOOLS };
if (require.main === module) {
  (async () => {
    if (process.argv.includes('--refresh')) await refreshMarketplace();
    if (process.argv.includes('--resolve')) {
      const argument = process.argv.find(value => value.startsWith('--limit='));
      const resolved = await resolveDirectDownloads({ force: process.argv.includes('--force'), ...(argument ? { limit: Number(argument.slice(8)) } : {}) });
      const reasons = resolved.failures.reduce((out, item) => (out[item.reason] = (out[item.reason] || 0) + 1, out), {});
      process.stdout.write(`${JSON.stringify({ listed: resolved.listed, attempted: resolved.attempted, verified: resolved.verified, rateLimited: resolved.rateLimited, unavailable: resolved.failures.length, reasons }, null, 2)}\n`);
    }
    const result = buildMarketplaceItems();
    process.stdout.write(`${JSON.stringify({ ...result.summary, sourceCounts: result.sourceCounts }, null, 2)}\n`);
  })().catch(error => { process.stderr.write(`${error.stack || error.message}\n`); process.exitCode = 1; });
}
