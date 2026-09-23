/* Preview or submit public page changes. Node 22+; no credentials or packages needed. */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { walk, excluded } = require('./seo-metadata');
const { pageUrl } = require('./seo-structured');
const ROOT = path.resolve(__dirname, '..');
const SITE = 'https://scoobymenu.cc';
const KEY_FILE = 'indexnow-key.txt';
const ENDPOINT = 'https://api.indexnow.org/indexnow';
const git = args => execFileSync('git', args, { cwd: ROOT, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 }).trim();

function publicFiles() {
  return walk(ROOT).map(abs => ({ file: path.relative(ROOT, abs).replace(/\\/g, '/'), html: fs.readFileSync(abs, 'utf8') }))
    .filter(({ html }) => !excluded(html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || ''));
}

function sitemapUrls(xml) {
  return [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(match => match[1].replace(/&amp;/g, '&'));
}

function selectUrls(files, changed, previousUrls = []) {
  const current = new Set(files.map(({ file }) => pageUrl(file)));
  const previous = new Set(previousUrls.filter(url => {
    try { const parsed = new URL(url); return parsed.origin === SITE && !parsed.search && !parsed.hash && !parsed.pathname.startsWith('/portal/'); }
    catch { return false; }
  }));
  const urls = new Set();
  for (const file of changed) {
    const url = pageUrl(file);
    if (file.endsWith('.html') && (current.has(url) || previous.has(url))) urls.add(url);
    // Shared styles, scripts and data can change rendered content across the site.
    if (/^(assets|languages)\/.*\.(?:css|js|json)$/.test(file)) for (const value of current) urls.add(value);
    if (/\.(?:png|jpe?g|webp|gif|svg|avif)$/i.test(file)) {
      for (const entry of files) if (entry.html.includes(file)) urls.add(pageUrl(entry.file));
    }
  }
  return [...urls].sort();
}

async function submit(urls, key, fetcher = fetch) {
  if (!/^[a-zA-Z0-9-]{8,128}$/.test(key)) throw Error('Invalid IndexNow key.');
  if (!urls.length) return null;
  for (const url of urls) {
    const parsed = new URL(url);
    if (parsed.origin !== SITE || parsed.search || parsed.hash || parsed.pathname.startsWith('/portal/')) throw Error('Only public canonical Scooby URLs may be submitted.');
  }
  const keyLocation = SITE + '/' + KEY_FILE;
  const keyResponse = await fetcher(keyLocation, { redirect: 'error', signal: AbortSignal.timeout(30000) });
  if (!keyResponse.ok || (await keyResponse.text()).trim() !== key) throw Error('The IndexNow key is not live yet. Publish first, then retry.');
  const liveSitemap = await fetcher(SITE + '/sitemap.xml', { redirect: 'error', signal: AbortSignal.timeout(30000) });
  if (!liveSitemap.ok) throw Error('The live sitemap could not be fetched.');
  const local = fs.readFileSync(path.join(ROOT, 'sitemap.xml'), 'utf8').replace(/\r\n/g, '\n').trim();
  if ((await liveSitemap.text()).replace(/\r\n/g, '\n').trim() !== local) throw Error('The new sitemap is not live yet. Wait for deployment before submitting.');
  for (let start = 0; start < urls.length; start += 10000) {
    const response = await fetcher(ENDPOINT, {
      method: 'POST', redirect: 'error', signal: AbortSignal.timeout(30000),
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify({ host: new URL(SITE).host, key, keyLocation, urlList: urls.slice(start, start + 10000) }),
    });
    if (![200, 202].includes(response.status)) throw Error(`IndexNow returned HTTP ${response.status}. Check the key and response in the IndexNow documentation before retrying.`);
    console.log(response.status === 202 ? 'IndexNow accepted the URLs; key validation is pending (202).' : 'IndexNow received the URLs (200).');
  }
  console.log('Receipt does not guarantee crawling, indexing, ranking or security clearance.');
}

async function main() {
  const args = process.argv.slice(2);
  const all = args.includes('--all');
  const sinceIndex = args.indexOf('--since');
  const since = sinceIndex === -1 ? null : args[sinceIndex + 1];
  if (all === Boolean(since) || (sinceIndex !== -1 && (!since || since.startsWith('--')))) {
    throw Error('Use --all for an initial submission, or --since <previous-release-commit> for changed URLs. Add --submit to send; otherwise this only previews.');
  }
  const files = publicFiles();
  const current = files.map(({ file }) => pageUrl(file)).sort();
  const sitemap = sitemapUrls(fs.readFileSync(path.join(ROOT, 'sitemap.xml'), 'utf8')).sort();
  if (JSON.stringify(current) !== JSON.stringify(sitemap)) throw Error('Sitemap URLs differ from the public pages. Regenerate sitemap.xml first.');
  let urls = current;
  if (since) {
    const base = git(['rev-parse', '--verify', '--end-of-options', since + '^{commit}']);
    git(['merge-base', '--is-ancestor', base, 'HEAD']);
    const changed = git(['diff', '--name-only', '--no-renames', '-z', base, 'HEAD', '--']).split('\0').filter(Boolean);
    const oldSitemap = git(['show', base + ':sitemap.xml']);
    urls = selectUrls(files, changed, sitemapUrls(oldSitemap));
  }
  console.log(`${args.includes('--submit') ? 'Submitting' : 'Previewing'} ${urls.length} public URLs:`);
  urls.forEach(url => console.log(url));
  if (args.includes('--submit')) await submit(urls, fs.readFileSync(path.join(ROOT, KEY_FILE), 'utf8').trim());
}

if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
module.exports = { selectUrls, sitemapUrls, submit };
