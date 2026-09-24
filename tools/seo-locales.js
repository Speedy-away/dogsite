/* Build translated, crawlable homepages from locale copy and existing UI dictionaries. */
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const locales = require('./search-locales.json');
const { applyMetadata, pages } = require('./seo-metadata');
const ROOT = path.resolve(__dirname, '..');
const apply = process.argv.includes('--apply');
const escape = value => value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const languageLabels = { es:'Idiomas', pt:'Idiomas', 'pt-br':'Idiomas', fr:'Langues', de:'Sprachen', ru:'Языки', tr:'Diller', pl:'Języki', it:'Lingue', zh:'语言', ja:'言語', ko:'언어', th:'ภาษา', vi:'Ngôn ngữ', id:'Bahasa', hi:'भाषाएँ', sr:'Језици', nl:'Talen', ka:'ენები', ar:'اللغات', he:'שפות' };
const games = [
  ['gta5', 'GTA 5', '/features-list/gta-features/'], ['rdr2', 'Red Dead Redemption 2', '/features-list/rdr2-features/'],
  ['fivem', 'FiveM', '/fivem-features/'], ['redm', 'RedM', null], ['cs2', 'Counter-Strike 2', '/features-list/cs2-features/'],
  ['gmod', "Garry's Mod", '/features-list/gmod-features/'], ['l4d', 'Left 4 Dead 1 & 2', '/features-list/l4d-features/'],
  ['sbox', 'S&box', null], ['last-of-us', 'The Last of Us Part I', '/features-list/last-of-us-features/'],
  ['half-life-1', 'Half-Life 1', '/features-list/half-life-1-features/'], ['half-life-2', 'Half-Life 2', null],
  ['half-life-2-deathmatch', 'Half-Life 2: Deathmatch', null], ['spoofer', 'HWID Spoofer + Cleaner', null],
];
const languageLinks = (code = 'en') => [['en', { tag:'en', native:'English' }], ...Object.entries(locales)].map(([key, locale]) =>
  `<a href="${key === 'en' ? '/' : '/' + key + '/'}" lang="${locale.tag}" hreflang="${locale.tag}" data-site-language="${key}"${code === key ? ' aria-current="page"' : ''}>${escape(locale.native)}</a>`).join('\n');
let stale = 0;
function output(file, html) {
  const target = path.join(ROOT, file);
  const old = fs.existsSync(target) ? fs.readFileSync(target, 'utf8').replace(/\r\n/g, '\n') : '';
  if (old === html) return;
  stale++;
  if (apply) { fs.mkdirSync(path.dirname(target), { recursive:true }); fs.writeFileSync(target, html); }
  else console.log('Stale: ' + file);
}
for (const [code, locale] of Object.entries(locales)) {
  const context = { window: { __scoobyI18nQueue: [] } };
  vm.runInNewContext(fs.readFileSync(path.join(ROOT, 'languages', code + '.js'), 'utf8'), context);
  const dictionary = context.window.__scoobyI18nQueue.find(([key]) => key === code)?.[1];
  const t = key => { if (!dictionary?.[key]) throw Error(`Missing ${code} UI translation: ${key}`); return escape(dictionary[key]); };
  const file = code + '/index.html';
  const cards = games.map(([slug, name, features]) => `<article class="game-card"><h3><a href="/products/${slug}/">${escape(name)}</a></h3><div class="game-links"><a href="/products/${slug}/">${t('View Details')}</a>${features ? `<a href="${features}">${t('Features')}</a>` : ''}${fs.existsSync(path.join(ROOT, 'guides', slug, 'index.html')) ? `<a href="/guides/${slug}/">${t('Guides')}</a>` : ''}</div></article>`).join('\n');
  const html = `<!DOCTYPE html>
<html lang="${locale.tag}" dir="${locale.rtl ? 'rtl' : 'ltr'}" data-site-language="${code}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(locale.title)}</title>
<link rel="icon" href="/assets/images/logo.png">
<link rel="stylesheet" href="/assets/css/site-directory.css">
<link rel="stylesheet" href="/assets/css/language-home.css">
<script src="/assets/js/language-home.js" defer></script>
</head>
<body>
<header class="site-header"><a class="brand" href="/${code}/"><img src="/assets/images/logo.png" alt="" width="36" height="36">SCOOBY</a><nav aria-label="${t('Menu')}"><a href="/store/">${t('Store')}</a><a href="/guides/">${t('Guides')}</a><a href="/portal/#dashboard">${t('Portal / Login')}</a></nav></header>
<main id="main-content">
<div class="intro"><p class="eyebrow"><bdi>scoobymenu.cc</bdi> · ${escape(locale.native)}</p><h1><bdi>Scooby Menu</bdi></h1><p>${escape(locale.intro)}</p><div class="home-actions"><a href="/products/free/">${t('Free Version')}</a><a href="/store/">${t('Store')}</a><a href="#products">${t('Products')}</a></div></div>
<section id="products" aria-labelledby="products-title"><h2 id="products-title">${t('Supported Games')}</h2><p class="section-intro">${escape(locale.about)}</p><div class="game-grid">${cards}</div></section>
<section aria-labelledby="resources-title"><h2 id="resources-title">${t('Resources')}</h2><p class="section-intro">${escape(locale.notice)}</p><nav class="resource-links" aria-label="${t('Resources')}"><a href="/guides/">${t('Guides')}</a><a href="/docs/">${t('Docs')}</a><a href="/videos/">${t('Videos')}</a><a href="/changelog/">${t('Changelog')}</a></nav></section>
<section aria-labelledby="support-title"><h2 id="support-title">${t('Support')}</h2><nav class="resource-links" aria-label="${t('Support')}"><a href="/portal/#dashboard">${t('Portal / Login')}</a><a href="https://discord.gg/tGtvzChYQq" rel="noopener">${t('Discord Server')}</a><a href="https://t.me/ScoobyOnTop" rel="noopener">Telegram</a><a href="/tos/">${t('Terms of Service')}</a></nav></section>
<section aria-labelledby="languages-title"><h2 id="languages-title">${escape(languageLabels[code])}</h2><nav class="language-links" aria-labelledby="languages-title">${languageLinks(code)}</nav></section>
</main>
<footer><span><bdi>Scooby Menu · scoobymenu.cc</bdi></span><a href="/" data-site-language="en" lang="en">English</a></footer>
</body>
</html>
`;
  output(file, applyMetadata(file, html, pages[file]));
}
const file = 'index.html';
let home = fs.readFileSync(path.join(ROOT, file), 'utf8').replace(/\r\n/g, '\n');
if (!home.includes('src="/assets/js/language-home.js"')) home = home.replace('</head>', '<script src="/assets/js/language-home.js" defer></script>\n</head>');
const block = '<!-- BEGIN SEARCH LANGUAGES -->\n<details class="footer-languages" data-i18n-skip><summary>Languages</summary><nav class="language-links" aria-label="Languages">' + languageLinks() + '</nav></details>\n<!-- END SEARCH LANGUAGES -->';
if (home.includes('<!-- BEGIN SEARCH LANGUAGES -->')) home = home.replace(/<!-- BEGIN SEARCH LANGUAGES -->[\s\S]*?<!-- END SEARCH LANGUAGES -->/, block);
else home = home.replace('<div class="footer-bottom">', block + '\n    <div class="footer-bottom">');
output(file, applyMetadata(file, home));
console.log(`${Object.keys(locales).length} translated homepages; ${stale} ${apply ? 'updated' : 'stale'}.`);
if (stale && !apply) process.exitCode = 1;
