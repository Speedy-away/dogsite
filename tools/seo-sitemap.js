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

const ROOT = path.resolve(__dirname, '..');
const SITE = 'https://scoobymenu.cc';
const APPLY = process.argv.includes('--apply');
const SKIP_DIRS = ['.git', '.claude', 'backup', 'node_modules', 'revolution', 'tools', 'languages'];

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
  { re: /^products\/(pubg|r6|sbox)\//, priority: '0.5', freq: 'monthly' },
  { re: /^products\//,              priority: '0.8', freq: 'weekly'  },
  { re: /^store\//,                 priority: '0.7', freq: 'weekly'  },
  { re: /-features\//,              priority: '0.7', freq: 'monthly' },
  { re: /^features-list\//,         priority: '0.6', freq: 'monthly' },
  { re: /^guides\//,                priority: '0.6', freq: 'monthly' },
  { re: /^docs\//,                  priority: '0.6', freq: 'monthly' },
  { re: /_api_reference\.html$/,    priority: '0.5', freq: 'monthly' },
  { re: /^videos\//,                priority: '0.5', freq: 'monthly' },
  { re: /^changelog\//,             priority: '0.5', freq: 'weekly'  },
  { re: /^resellers\//,             priority: '0.5', freq: 'monthly' },
  { re: /^freekey\.html$/,          priority: '0.4', freq: 'monthly' },
  { re: /^tos\//,                   priority: '0.3', freq: 'yearly'  },
];

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (SKIP_DIRS.includes(e.name)) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.html')) out.push(p);
  }
  return out;
}

function gitDate(rel) {
  try {
    const d = execFileSync('git', ['log', '-1', '--format=%cs', '--', rel],
                           { cwd: ROOT, encoding: 'utf8' }).trim();
    return d || null;
  } catch (e) { return null; }
}

const today = new Date().toISOString().slice(0, 10);
const rows = [];

for (const abs of walk(ROOT)) {
  const rel = path.relative(ROOT, abs).split(path.sep).join('/');
  if (EXCLUDE.includes(rel)) continue;

  const html = fs.readFileSync(abs, 'utf8');
  if (/<meta[^>]+name=["']robots["'][^>]*noindex/i.test(html)) continue;
  if (/http-equiv=["']Refresh["']/i.test(html)) continue;      // redirect stub

  // /a/b/index.html -> /a/b/ ; /page.html stays /page.html
  const urlPath = rel.endsWith('/index.html') ? rel.slice(0, -'index.html'.length)
                : rel === 'index.html' ? ''
                : rel;

  const rule = RULES.find(r => r.re.test(urlPath)) || { priority: '0.5', freq: 'monthly' };
  rows.push({
    loc: SITE + '/' + urlPath,
    lastmod: gitDate(rel) || today,
    freq: rule.freq,
    priority: rule.priority,
  });
}

rows.sort((a, b) => Number(b.priority) - Number(a.priority) || a.loc.localeCompare(b.loc));

const xml = '<?xml version="1.0" encoding="UTF-8"?>\n' +
  '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
  rows.map(r => '  <url><loc>' + r.loc + '</loc><lastmod>' + r.lastmod +
                '</lastmod><changefreq>' + r.freq + '</changefreq><priority>' +
                r.priority + '</priority></url>').join('\n') +
  '\n</urlset>\n';

const target = path.join(ROOT, 'sitemap.xml');
const existing = fs.existsSync(target) ? fs.readFileSync(target, 'utf8') : '';

console.log('pages in sitemap:', rows.length);
rows.forEach(r => console.log('  ' + r.priority + '  ' + r.lastmod + '  ' + r.loc));

if (APPLY) {
  fs.writeFileSync(target, xml, 'utf8');
  console.log('\nsitemap.xml written' + (existing === xml ? ' (unchanged)' : ''));
} else {
  console.log('\n' + (existing === xml ? 'sitemap.xml is already up to date.'
                                       : 'sitemap.xml is OUT OF DATE - re-run with --apply'));
  process.exit(existing === xml ? 0 : 1);
}
