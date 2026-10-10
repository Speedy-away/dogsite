/* Generate the release-facing pages from the reviewed catalog snapshot. */
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const {pages: metadata} = require('./seo-metadata');
const catalog = require('../assets/data/rockstar-classics.json');
const source = fs.readFileSync(path.join(root, 'source-games/index.html'), 'utf8');
const nav = source.match(/<nav class="nav"[\s\S]*?<\/nav>/)[0].replace('/guides/source-games/', '/guides/');
const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const released = game => ['beta','released'].includes(game.state) && game.releaseArtifact?.url;
const label = game => released(game) ? 'Released' : 'Coming soon';
const href = game => `/products/${game.id}/`;
function shell(title, route, desc, body, collection = false) {
  return `<!DOCTYPE html><html lang="en" class="source-collection-document"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)} - Scooby</title><meta name="description" content="${escape(desc)}">
<meta name="keywords" content="${escape(metadata[route.slice(1)+"index.html"].keywords)}">
<link rel="canonical" href="https://scoobymenu.cc${route}"><meta name="robots" content="index, follow">
<meta property="og:type" content="website"><meta property="og:title" content="${escape(title)} - Scooby"><meta property="og:description" content="${escape(desc)}"><meta property="og:url" content="https://scoobymenu.cc${route}">
<meta name="twitter:card" content="summary"><meta name="twitter:title" content="${escape(title)} - Scooby"><meta name="twitter:description" content="${escape(desc)}">
<link rel="icon" href="/assets/images/brand/scooby-logo.png">
${['site-brand','product','product-layout','source-games','source-collection','rockstar-classics'].map(css => `<link rel="stylesheet" href="/assets/css/${css}.css">`).join('\n')}
<script src="/assets/js/product-layout.js" defer></script>${collection ? '<script src="/assets/js/source-collection.js" defer></script>' : ''}
</head><body class="product-detail source-page source-collection rockstar-classics"><a class="product-skip-link" href="#main-content">Skip to content</a>${nav}
<main class="main-content" id="main-content">${body}</main><footer class="source-footer"><a href="/rockstar-classics/">Rockstar Classics</a><a href="/source-games/">Source Games</a><a href="/more-games/">More Games</a><a href="/">Home</a><span>Scooby · Make it yours.</span></footer></body></html>\n`;
}
const card = game => `<a class="source-card" href="${href(game)}" data-game="${game.id}" data-engine="${released(game) ? 'released' : 'coming-soon'}" data-search="${escape(game.name)} ${game.id} GTA Grand Theft Auto ${escape(metadata['products/'+game.id+'/index.html'].keywords)}"><div class="source-card-art classics-type-art"><span class="source-availability ${released(game) ? 'is-released' : 'is-upcoming'}">${label(game)}</span><img class="classic-scene" src="/assets/images/rockstar-classics/${game.id}-background.${game.id === 'gta3' ? 'png' : 'jpg'}" alt=""><img class="classic-logo" src="/assets/images/rockstar-classics/${game.id}-logo.png" alt=""></div><div class="source-card-copy"><h3>${escape(game.name)}</h3></div></a>`;
const states = [
  ['released', 'PLAY NOW', 'Released', 'Explore the available Rockstar Classics titles.'],
  ['coming-soon', 'UP NEXT', 'Coming soon', 'More classic worlds are on the way.']
];
const sections = states.map(([state, kicker, title, intro]) => {
  const games = catalog.games.filter(game => (released(game) ? 'released' : 'coming-soon') === state);
  if (!games.length) return '';
  return `<section id="${state}" class="source-catalog-section" data-catalog-section aria-labelledby="${state}-title"><div class="source-section-heading"><div><span class="source-kicker">${kicker}</span><h2 id="${state}-title">${title}</h2><p>${intro}</p></div><span class="source-section-count">${String(games.length).padStart(2,'0')}</span></div><div class="source-grid">${games.map(card).join('\n')}</div></section>`;
}).join('\n');
const body = `<header class="collection-hero"><div class="collection-hero-copy"><div class="collection-brand"><span>THE SCOOBY COLLECTION</span></div><h1>Rockstar Classics</h1><p class="collection-tagline">Familiar worlds.<br>A new chapter starts here.</p><p class="collection-intro">From Los Santos to the frontier. Browse released games and see what is coming next.</p><div class="collection-hero-actions"><a href="#released" class="collection-button">Released games ↓</a><a href="#coming-soon" class="collection-button secondary">Coming soon</a></div></div></header>
<div class="collection-tools" hidden><div class="collection-filters" role="group" aria-label="Filter games by status"><button type="button" data-engine-filter="all" aria-pressed="true">All games</button><button type="button" data-engine-filter="released" aria-pressed="false">Released</button><button type="button" data-engine-filter="coming-soon" aria-pressed="false">Coming soon</button></div><label class="collection-search"><span class="visually-hidden">Search games</span><input id="source-game-search" type="search" placeholder="Search your game…" autocomplete="off"></label></div><p id="collection-results" class="collection-results" role="status" hidden></p>
${sections}<div id="collection-empty" class="collection-empty" hidden><h2>No games found</h2><p>Try another title or show the full collection.</p><button type="button" id="collection-reset">Show all games</button></div>
<section id="requirements" class="source-note classics-requirements" aria-labelledby="requirements-title">
<h2 id="requirements-title">Requirements</h2>
<h3>Download VC Runtimes</h3>
<p>Install the <strong>Visual C++ runtimes</strong> before launching Scooby. Choose the all-in-one package or install both Microsoft packages below, then <strong>restart your PC</strong>.</p>
<p><strong>VC Runtimes (all-in-one package):</strong></p>
<p><a href="https://www.techpowerup.com/download/visual-c-redistributable-runtime-package-all-in-one/">Download the all-in-one VC runtime package</a></p>
<p><strong>Or install both packages directly from Microsoft:</strong></p>
<ul><li><a href="https://aka.ms/vc14/vc_redist.x64.exe">Download VC Runtimes — x64 (64-bit)</a></li><li><a href="https://aka.ms/vc14/vc_redist.x86.exe">Download VC Runtimes — x86 (32-bit)</a></li></ul>
</section>
`;
const outputs = new Map([['rockstar-classics/index.html', shell('Rockstar Classics', '/rockstar-classics/', 'Explore Rockstar Classics. Browse released San Andreas and GTA IV, and upcoming Vice City, GTA III and Red Dead Redemption.', body, true)]]);
const productTemplate = require('./rockstar-product-template.cjs');
for (const game of catalog.games) {
  outputs.set(`products/${game.id}/index.html`, productTemplate.render(game));
  outputs.set(`rockstar-classics/${game.id}/index.html`, `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escape(game.name)} - Scooby</title><link rel="canonical" href="https://scoobymenu.cc${href(game)}"><meta name="robots" content="noindex, follow"><meta http-equiv="refresh" content="0;url=${href(game)}"></head><body><p><a href="${href(game)}">Continue to ${escape(game.name)}</a></p></body></html>\n`);
}
for (const [file, content] of outputs) {
  const target = path.join(root, file);
  if (process.argv.includes('--check')) {
    if (!fs.existsSync(target) || fs.readFileSync(target,'utf8') !== content) throw new Error(`Regenerate ${file}: node tools/build-rockstar-classics.cjs`);
  } else { fs.mkdirSync(path.dirname(target), {recursive:true}); fs.writeFileSync(target,content); }
}
console.log(`${outputs.size} Rockstar Classics pages ${process.argv.includes('--check') ? 'verified' : 'generated'}.`);
