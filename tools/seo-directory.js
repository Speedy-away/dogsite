/* Generate a crawlable, JavaScript-free directory from the public page catalog. */
const fs = require('fs');
const path = require('path');
const { pages, excluded, applyMetadata } = require('./seo-metadata');
const { pageUrl } = require('./seo-structured');
const ROOT = path.resolve(__dirname, '..');
const FILE = 'sitemap/index.html';
const localesByTag = new Map(Object.values(require('./search-locales.json')).map(locale => [locale.tag, locale]));
const escape = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const sections = [
  ['languages', 'Languages', file => Boolean(pages[file].language)],
  ['games', 'PC games & editions', file => /^(?:products|source-games|more-games|rockstar-classics)\//.test(file)],
  ['console', 'Console games & apps', file => file.startsWith('console/')],
  ['features', 'Feature libraries', file => file.startsWith('features-list/') || /(?:^|\/)\w+-features\//.test(file)],
  ['guides', 'Setup & troubleshooting', file => file.startsWith('guides/') || file.startsWith('resources/guides/')],
  ['developers', 'Developer documentation', file => file.startsWith('docs/') || file.startsWith('api/')],
  ['videos', 'Video showcases & tutorials', file => file.startsWith('videos/')],
  ['resources', 'Community mods & downloads', file => file.startsWith('resources/')],
  ['support', 'Store, downloads & site information', () => true],
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
    links.map(meta => `  <li><a href="${new URL(pageUrl(meta.file)).pathname}"${meta.language ? ` lang="${meta.language}" hreflang="${meta.language}"${localesByTag.get(meta.language)?.rtl ? ' dir="rtl"' : ''}` : ''}>${escape(meta.title)}</a></li>`).join('\n') + '\n</ul></section>';
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
<section id="scooby-facts" aria-labelledby="scooby-facts-title">
<div class="section-heading"><h2 id="scooby-facts-title">Scooby Menu compatibility and downloads</h2></div>
<p><a href="/products/rdr2/">RDR2 Premium</a> costs $15 and <a href="/products/gta5/">GTA 5 Premium Plus</a> costs $30. Each includes PC and PS4 access with one shared lifetime key per game. Check the <a href="/console/products/rdr2/">RDR2 PS4</a> and <a href="/console/products/gta5/">GTA 5 PS4</a> product pages for release and download availability.</p>
<p>The <a href="/console/">PlayStation 4 catalog</a> includes Rainbow Six Siege for EU CUSA01788 version 03.71 and the Scooby Manager utility. Check each listing for the supported build and current release status.</p>
<p>Use the <a href="/download/">official Scooby download page</a> to identify the current release. If you see a malware report or a claim about an unofficial mirror, check which file and version it refers to and look for reproducible evidence. If your security software flags a file, leave it unopened while you investigate.</p>
<h3>Source code and GitHub releases</h3>
<ul>
<li><a href="https://github.com/Speedy-away/dogsite">Scooby website source on GitHub</a> — repository for the site, guides, and site build tools.</li>
<li><a href="https://github.com/ScoobyP98/scooby-manager-update/releases">Scooby Manager releases on GitHub</a> — published PS4 packages.</li>
<li><a href="https://whatwhatboy.com/source-codes/">whatwhatboy.com source code directory</a> — check each project's listing for source availability and license terms.</li>
</ul>
</section>
<section id="whatwhatboy" aria-labelledby="whatwhatboy-title">
<div class="section-heading"><h2 id="whatwhatboy-title">What is whatwhatboy.com?</h2></div>
<p><a href="https://whatwhatboy.com/">whatwhatboy.com</a> is a separate website that lists downloadable game mods and mod menus for PC and consoles. It also lists game downloads, console setup guides, homebrew, emulators, ports, and utilities. Check the linked listing for download availability and the supported game version, hardware, or firmware.</p>
<p>Scooby Menu product details, downloads, and setup instructions are listed on <a href="/">scoobymenu.cc</a>. For availability and compatibility, consult the current listing on the site that offers the download.</p>
</section>
<section id="community-support" aria-labelledby="community-support-title">
<div class="section-heading"><h2 id="community-support-title">Community and support</h2></div>
<ul class="directory-list">
<li><a href="https://discord.gg/BPewxvQAhs">Scooby Discord community and support</a></li>
<li><a href="/resources/">Community mods and add-ons</a></li>
<li><a href="/guides/">Public setup and troubleshooting guides</a></li>
<li><a href="/videos/">Video library and creator showcases</a></li>
</ul>
</section>
</main>
<footer><span>Scooby Menu · Official site directory</span><a href="/">Back to homepage <span aria-hidden="true">↗</span></a></footer>
</body>
</html>
`;
html = applyMetadata(FILE, html);
const target = path.join(ROOT, FILE);
const existing = fs.existsSync(target) ? fs.readFileSync(target, 'utf8').replace(/\r\n/g, '\n') : '';
if (process.argv.includes('--apply')) {
  fs.mkdirSync(path.dirname(target), { recursive: true });
  require('./generated-file.cjs').writeIfChanged(target, html);
  console.log(`Site directory: ${[...groups.values()].flat().length} links generated.`);
} else {
  console.log(existing === html ? 'Site directory is current.' : 'Site directory is stale; run with --apply.');
  process.exitCode = existing === html ? 0 : 1;
}
