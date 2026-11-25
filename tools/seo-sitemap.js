/*
 * Regenerates sitemap.xml from the pages that actually exist.
 *
 *   node tools/seo-sitemap.js           show what it would write
 *   node tools/seo-sitemap.js --apply   write sitemap.xml
 *
 * lastmod comes from each file's last git commit date, so it is honest rather
 * than a hand-maintained guess that goes stale. Pages carrying a robots
 * "noindex" tag are skipped automatically, as are redirect stubs and anything
 * listed in EXCLUDE.
 */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { walk, excluded, attrs } = require('./seo-metadata');
const { pageUrl } = require('./seo-structured');
const locales = require('./search-locales.json');
const { isPublic } = require('./site-layout.cjs');
const videosByFile = new Map(require('./seo-watch.cjs').videos.map(video => [video.file, video]));

const ROOT = path.resolve(__dirname, '..');
const SITE = 'https://scoobymenu.cc';
const APPLY = process.argv.includes('--apply');

// Never belongs in a public index.
const EXCLUDE = [
  'portal/index.html',        // account area, login-gated
  'discord.html',             // instant redirect stub
  'scoobyontop.html',         // instant redirect stub
];

// Tuning: first match wins.
const RULES = [
  { re: /^$/,                       priority: '1.0', freq: 'weekly'  },  // homepage
  { re: /^best-mod-menu\//,         priority: '0.9', freq: 'weekly'  },
  { re: /^products\/(free|gta5)\//, priority: '0.9', freq: 'weekly'  },
  { re: /^products\/(pubg|r6)\//, priority: '0.5', freq: 'monthly' },
  { re: /^products\//,              priority: '0.8', freq: 'weekly'  },
  { re: /^store\//,                 priority: '0.7', freq: 'weekly'  },
  { re: /^resources\/guides\//,     priority: '0.6', freq: 'monthly' },
  { re: /^resources\//,             priority: '0.7', freq: 'weekly'  },
  { re: /-features\//,              priority: '0.7', freq: 'monthly' },
  { re: /^features-list\//,         priority: '0.6', freq: 'monthly' },
  { re: /^guides\//,                priority: '0.6', freq: 'monthly' },
  { re: /^docs\//,                  priority: '0.6', freq: 'monthly' },
  { re: /_api_reference\.html$/,    priority: '0.5', freq: 'monthly' },
  { re: /^videos\//,                priority: '0.5', freq: 'monthly' },
  { re: /^changelog\//,             priority: '0.5', freq: 'weekly'  },
  { re: /^resellers\//,             priority: '0.5', freq: 'monthly' },
  { re: /^download\//,              priority: '0.7', freq: 'monthly' },
  { re: /^freekey\.html$/,          priority: '0.4', freq: 'monthly' },
  { re: /^tos\//,                   priority: '0.3', freq: 'yearly'  },
];

function gitDate(rel, changedPages, root = ROOT) {
  if (changedPages.has(rel)) return fs.statSync(path.join(root, rel)).mtime.toISOString().slice(0, 10);
  try {
    const d = execFileSync('git', ['log', '-1', '--format=%cs', '--', rel],
                           { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    return d || null;
  } catch (e) { return null; }
}

function changedFiles(root) {
const changedPages = new Set();
try {
  // A local build includes pending source edits and newly generated pages.
  // Their current modification date is more accurate than an older commit.
  const status = execFileSync('git', ['status', '--porcelain=v1', '-z', '--untracked-files=all'], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
  const records = status.split('\0');
  for (let index = 0; index < records.length; index++) {
    const record = records[index];
    if (!record) continue;
    changedPages.add(record.slice(3).replace(/\\/g, '/'));
    if (/^[RC]|^ [RC]/.test(record)) index++;
  }
} catch { /* Commit dates remain available when worktree status is unavailable. */ }
return changedPages;
}

const escapeXml = value => value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');

// Select content images from actual page markup. Logos, decorative backgrounds,
// sprite sheets and files excluded from the deployed site stay out of the sitemap.
const contentImagePath = /^\/(?:assets\/images\/(?:previews|guides|resource-previews|source-games|rockstar-classics|tf2|l4d|mta-sa|bodycam)\/|console\/assets\/images\/)/;

function pageImages(html, loc, root) {
  const markup = html.replace(/<!--[\s\S]*?-->|<script\b[^>]*>[\s\S]*?<\/script>/gi, '');
  const images = new Set();
  for (const [tag] of markup.matchAll(/<img\b[^>]*>/gi)) {
    const image = attrs(tag);
    if (!image.alt?.trim() || !image.src) continue;
    let url, relative;
    try {
      url = new URL(image.src, loc);
      relative = decodeURIComponent(url.pathname.slice(1));
    } catch { continue; }
    if (url.origin !== SITE || url.hash || !contentImagePath.test(url.pathname)) continue;
    if (url.pathname.startsWith('/assets/images/resource-previews/cherax/')) continue;
    if (relative.includes('\\') || path.posix.normalize(relative) !== relative) continue;
    if (!isPublic(relative) || !/\.(?:avif|jpe?g|png|webp)$/i.test(relative)) continue;
    if (!fs.statSync(path.join(root, relative), { throwIfNoEntry: false })?.isFile()) continue;
    images.add(url.href);
  }
  return [...images].slice(0, 1000);
}

function videoEntry({ title, description, player, thumbnail, uploadDate }) {
  const fields = { thumbnail_loc: thumbnail, title, description, player_loc: player, publication_date: uploadDate };
  return '\n    <video:video>' + Object.entries(fields).map(([tag, value]) =>
    '\n      <video:' + tag + '>' + escapeXml(value) + '</video:' + tag + '>'
  ).join('') + '\n    </video:video>';
}

function buildSitemap({ root = ROOT, dateFor } = {}) {
const changedPages = dateFor ? null : changedFiles(root);
const rows = [];

for (const abs of walk(root)) {
  const rel = path.relative(root, abs).split(path.sep).join('/');
  if (EXCLUDE.includes(rel)) continue;

  const html = fs.readFileSync(abs, 'utf8');
  const head = html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || '';
  if (excluded(head)) continue;
  const loc = pageUrl(rel);
  const canonical = [...head.matchAll(/<link\b[^>]*>/gi)].map(match => attrs(match[0])).find(tag => tag.rel?.toLowerCase() === 'canonical');
  // Aliases and off-site canonical pages must not compete in the sitemap.
  if (canonical && new URL(canonical.href, loc).href !== loc) continue;

  // /a/b/index.html -> /a/b/ ; /page.html stays /page.html
  const urlPath = rel.endsWith('/index.html') ? rel.slice(0, -'index.html'.length)
                : rel === 'index.html' ? ''
                : rel;

  const rule = RULES.find(r => r.re.test(urlPath)) || { priority: '0.5', freq: 'monthly' };
  rows.push({
    loc,
    lastmod: dateFor ? dateFor(rel) : gitDate(rel, changedPages, root),
    freq: rule.freq,
    priority: rule.priority,
    images: pageImages(html, loc, root),
    video: videosByFile.get(rel),
  });
}

rows.sort((a, b) => Number(b.priority) - Number(a.priority) || a.loc.localeCompare(b.loc));

const urls = new Set(rows.map(row => row.loc));
const homes = [
  { language: 'en', href: SITE + '/' },
  ...Object.entries(locales).map(([code, locale]) => ({ language: locale.tag, href: SITE + '/lang/' + code + '/' })),
  { language: 'x-default', href: SITE + '/' },
].filter(alternate => urls.has(alternate.href));
const translatedHomes = new Set(homes.map(alternate => alternate.href));
const xml = '<?xml version="1.0" encoding="UTF-8"?>\n' +
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1" xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">\n' +
  rows.map(r => '  <url>\n    <loc>' + escapeXml(r.loc) + '</loc>' +
                (r.lastmod ? '\n    <lastmod>' + escapeXml(r.lastmod) + '</lastmod>' : '') +
                '\n    <changefreq>' + r.freq + '</changefreq>\n    <priority>' + r.priority + '</priority>' +
                (translatedHomes.has(r.loc) ? homes.map(alternate => '\n    <xhtml:link rel="alternate" hreflang="' + escapeXml(alternate.language) + '" href="' + escapeXml(alternate.href) + '" />').join('') : '') +
                r.images.map(image => '\n    <image:image><image:loc>' + escapeXml(image) + '</image:loc></image:image>').join('') +
                (r.video ? videoEntry(r.video) : '') +
                '\n  </url>').join('\n') +
  '\n</urlset>\n';
return { rows, xml };
}

if (require.main === module) {
const { rows, xml } = buildSitemap();
const target = path.join(ROOT, 'sitemap.xml');
const existing = fs.existsSync(target) ? fs.readFileSync(target, 'utf8').replace(/\r\n/g, '\n') : '';

console.log('pages in sitemap:', rows.length);
console.log('image references:', rows.reduce((count, row) => count + row.images.length, 0), '| watch pages:', rows.filter(row => row.video).length);
if (process.argv.includes('--verbose')) rows.forEach(r => console.log('  ' + r.priority + '  ' + r.lastmod + '  ' + r.loc));

if (APPLY) {
  require('./generated-file.cjs').writeIfChanged(target, xml);
  console.log('\nsitemap.xml written' + (existing === xml ? ' (unchanged)' : ''));
} else {
  console.log('\n' + (existing === xml ? 'sitemap.xml is already up to date.'
                                       : 'sitemap.xml is OUT OF DATE - re-run with --apply'));
  process.exit(existing === xml ? 0 : 1);
}
}
module.exports = { buildSitemap, escapeXml };
