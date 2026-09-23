/* Generate a crawlable, JavaScript-free directory from the public page catalog. */
const fs = require('fs');
const path = require('path');
const { pages, excluded, applyMetadata } = require('./seo-metadata');
const { pageUrl } = require('./seo-structured');
const ROOT = path.resolve(__dirname, '..');
const FILE = 'sitemap/index.html';
const escape = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const sections = [
  ['languages', 'Languages', file => Boolean(pages[file].language)],
  ['games', 'Games & editions', file => file.startsWith('products/') || file === 'source-games/index.html'],
  ['features', 'Feature libraries', file => file.includes('features/')],
  ['guides', 'Setup & troubleshooting', file => file.startsWith('guides/')],
  ['developers', 'Developer documentation', file => file.startsWith('docs/') || file.endsWith('_api_reference.html')],
  ['resources', 'Store, community & resources', () => true],
];
const groups = new Map(sections.map(([id]) => [id, []]));
for (const [file, meta] of Object.entries(pages)) {
  if (file === FILE) continue;
  const html = fs.readFileSync(path.join(ROOT, file), 'utf8');
  const head = html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0] || '';
  if (excluded(head)) continue;
  const [id] = sections.find(([, , match]) => match(file));
  groups.get(id).push({ file, ...meta });
}
const sectionsHtml = sections.map(([id, name]) => {
  const links = groups.get(id).sort((a, b) => a.title.localeCompare(b.title, 'en'));
  return `<section id="${id}" aria-labelledby="${id}-title"><div class="section-heading"><h2 id="${id}-title">${name}</h2><span>${links.length} pages</span></div><ul class="directory-list">\n` +
    links.map(meta => `  <li><a href="${new URL(pageUrl(meta.file)).pathname}">${escape(meta.title)}</a></li>`).join('\n') + '\n</ul></section>';
}).join('\n');
let html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(pages[FILE].title)}</title>
<link rel="icon" href="/assets/images/logo.png">
<link rel="stylesheet" href="/assets/css/site-directory.css">
</head>
<body>
<a class="skip-link" href="#main-content">Skip to directory</a>
<header class="site-header"><a class="brand" href="/"><img src="/assets/images/logo.png" alt="" width="36" height="36">SCOOBY</a><nav aria-label="Main navigation"><a href="/store/">Store</a><a href="/guides/">Guides</a><a href="/portal/#dashboard">Dashboard</a></nav></header>
<main id="main-content">
<nav class="breadcrumbs" aria-label="Breadcrumb"><a href="/">Home</a><span aria-hidden="true"> / </span><span>Site directory</span></nav>
<div class="intro"><p class="eyebrow">EXPLORE SCOOBY</p><h1>Find your game.<br>Find your guide.</h1><p>Browse game editions, feature libraries and step-by-step help. Each link takes you straight to the official page on scoobymenu.cc.</p></div>
<nav class="section-nav" aria-label="Directory sections">${sections.map(([id, name]) => `<a href="#${id}">${name}</a>`).join('')}</nav>
${sectionsHtml}
</main>
<footer><span>Scooby Mod Menu · Official site directory</span><a href="/">Back to homepage <span aria-hidden="true">↗</span></a></footer>
</body>
</html>
`;
html = applyMetadata(FILE, html);
const target = path.join(ROOT, FILE);
const existing = fs.existsSync(target) ? fs.readFileSync(target, 'utf8').replace(/\r\n/g, '\n') : '';
if (process.argv.includes('--apply')) {
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, html);
  console.log(`Site directory: ${[...groups.values()].flat().length} links generated.`);
} else {
  console.log(existing === html ? 'Site directory is current.' : 'Site directory is stale; run with --apply.');
  process.exitCode = existing === html ? 0 : 1;
}
