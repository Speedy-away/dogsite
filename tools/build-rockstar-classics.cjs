/* Generate the release-facing pages from the reviewed catalog snapshot. */
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const catalog = require('../assets/data/rockstar-classics.json');
const source = fs.readFileSync(path.join(root, 'source-games/index.html'), 'utf8');
const nav = source.match(/<nav class="nav"[\s\S]*?<\/nav>/)[0].replace('/guides/source-games/', '/guides/');
const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const released = game => game.state === 'beta' && game.releaseArtifact?.url;
const label = game => released(game) ? 'Online · Free beta' : game.state === 'development' ? 'In development' : 'Queued';
const href = game => `/products/${game.id}/`;
const description = game => released(game) ? 'Scooby for classic San Andreas is Online as a free beta. Download the release; live gameplay and performance acceptance remain pending.' : `${game.name} is ${game.state === 'development' ? 'a development port' : 'queued'} in Rockstar Classics. No release download or verified compatibility is available.`;
const notes = {
  'gta-sa': 'The San Andreas port retains its own SA settings and feature identifiers. Shared development with GTA III and Vice City does not make saved profiles interchangeable.',
  'gta-vc': 'Vice City is a separate development port with its own game adapter, compatibility profiles, settings and scripts.',
  'gta3': 'GTA III is a separate development port with its own game adapter, compatibility profiles, settings and scripts.',
  'gta4': 'GTA IV is queued. Separate current and downgraded profiles are planned when development resumes; neither is verified for release.',
  'rdr1': 'Red Dead Redemption is queued as an independent port. Only common interface and API conventions are planned to partially sync.'
};
function shell(title, route, desc, body, collection = false) {
  return `<!DOCTYPE html><html lang="en" class="source-collection-document"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)} - Scooby</title><meta name="description" content="${escape(desc)}">
<link rel="canonical" href="https://scoobymenu.cc${route}"><meta name="robots" content="index, follow">
<meta property="og:type" content="website"><meta property="og:title" content="${escape(title)} - Scooby"><meta property="og:description" content="${escape(desc)}"><meta property="og:url" content="https://scoobymenu.cc${route}">
<meta name="twitter:card" content="summary"><meta name="twitter:title" content="${escape(title)} - Scooby"><meta name="twitter:description" content="${escape(desc)}">
<link rel="icon" href="/assets/images/brand/scooby-logo.png">
${['site-brand','product','product-layout','source-games','source-collection','rockstar-classics'].map(css => `<link rel="stylesheet" href="/assets/css/${css}.css">`).join('\n')}
<script src="/assets/js/product-layout.js" defer></script>${collection ? '<script src="/assets/js/source-collection.js" defer></script>' : ''}
</head><body class="product-detail source-page source-collection rockstar-classics"><a class="product-skip-link" href="#main-content">Skip to content</a>${nav}
<main class="main-content" id="main-content">${body}</main><footer class="source-footer"><a href="/rockstar-classics/">Rockstar Classics</a><a href="/source-games/">Source Games</a><a href="/more-games/">More Games</a><a href="/">Home</a><span>Scooby · Make it yours.</span></footer></body></html>\n`;
}
const card = game => `<a class="source-card" href="${href(game)}" data-game="${game.id}" data-engine="${game.state}" data-search="${escape(game.name)} ${game.id} GTA Grand Theft Auto ${game.id === 'rdr1' ? 'RDR1' : ''}"><div class="source-card-art classics-type-art" aria-hidden="true"><span>${escape(game.name)}</span></div><div class="source-card-copy"><span class="source-kicker">${label(game)}</span><h3>${escape(game.name)}</h3><p>${escape(notes[game.id])}</p><span class="source-card-link">Game details &amp; status <span aria-hidden="true">↗</span></span></div></a>`;
const states = [
  ['beta', 'AVAILABLE NOW', 'Online · Free beta', 'Released for classic single-player San Andreas. Live gameplay and performance acceptance remain pending.'],
  ['development', 'THE GTA CLASSICS', 'Development ports', 'Shared development conventions. Separate game settings and scripts.'],
  ['queued', 'ON THE ROADMAP', 'Queued titles', 'Not currently supported for launch or download.']
];
const sections = states.map(([state, kicker, title, intro]) => {
  const games = catalog.games.filter(game => game.state === state);
  if (!games.length) return '';
  return `<section id="${state}" class="source-catalog-section" data-catalog-section aria-labelledby="${state}-title"><div class="source-section-heading"><div><span class="source-kicker">${kicker}</span><h2 id="${state}-title">${title}</h2><p>${intro}</p></div><span class="source-section-count">${String(games.length).padStart(2,'0')}</span></div><div class="source-grid">${games.map(card).join('\n')}</div></section>`;
}).join('\n');
const body = `<header class="collection-hero"><div class="collection-hero-copy"><div class="collection-brand"><span>THE SCOOBY COLLECTION</span></div><h1>Rockstar Classics</h1><p class="collection-tagline">Familiar worlds.<br>A new chapter starts here.</p><p class="collection-intro">San Andreas is Online as a free beta. Explore its release, follow the other classic GTA ports, and see the titles queued next.</p><div class="collection-hero-actions"><a href="#beta" class="collection-button">San Andreas free beta ↓</a><a href="#queued" class="collection-button secondary">Queued titles</a></div></div><span class="collection-hero-caption">1 free beta · 2 development ports · 2 queued titles</span></header>
<div class="collection-tools" hidden><div class="collection-filters" role="group" aria-label="Filter games by status"><button type="button" data-engine-filter="all" aria-pressed="true">All games</button><button type="button" data-engine-filter="beta" aria-pressed="false">Online · Free beta</button><button type="button" data-engine-filter="development" aria-pressed="false">In development</button><button type="button" data-engine-filter="queued" aria-pressed="false">Queued</button></div><label class="collection-search"><span class="visually-hidden">Search games</span><input id="source-game-search" type="search" placeholder="Search your game…" autocomplete="off"></label></div><p id="collection-results" class="collection-results" role="status" hidden></p>
${sections}<div id="collection-empty" class="collection-empty" hidden><h2>No games found</h2><p>Try another title or show the full collection.</p><button type="button" id="collection-reset">Show all games</button></div>
<section class="source-note"><h2>One family, separate games</h2><p>San Andreas, Vice City and GTA III share development conventions for common behavior, interface structure and script contracts. Each title owns its game-specific implementation, settings, scripts and capabilities. Shared development is not a claim of released feature parity.</p><p>GTA IV and Red Dead Redemption are queued and only partially share conventions. <a href="/products/mta-sa/">MTA:SA</a> remains separate and does not sync gameplay, settings or APIs with this family.</p><p>Catalog updated <time datetime="${catalog.updated}">${catalog.updated}</time>. San Andreas has a free beta release; live gameplay and performance acceptance remain pending. The other four titles have no release artifact.</p></section>`;
const outputs = new Map([['rockstar-classics/index.html', shell('Rockstar Classics', '/rockstar-classics/', 'Explore Rockstar Classics: San Andreas Online as a free beta, Vice City and GTA III development ports, plus queued GTA IV and Red Dead Redemption.', body, true)]]);
function releaseDetails(game) {
  const release = game.releaseArtifact;
  if (!/^https:\/\/raw\.githubusercontent\.com\/Rendererrr\/Rendererrr\.github\.io\/main\/scooby\/rockstar-classics\/GTA\/SA\/Scooby-SA-[\w.-]+\.zip$/.test(release.url) || !/^[a-f0-9]{64}$/.test(release.sha256) || !(release.bytes > 0)) throw new Error('Invalid reviewed release artifact');
  return `<dl class="classics-facts"><div><dt>Availability</dt><dd>Online</dd></div><div><dt>Access</dt><dd>Free beta</dd></div><div><dt>Release</dt><dd>${escape(release.version)}</dd></div><div><dt>Runtime verification</dt><dd>Live gameplay and performance acceptance pending</dd></div></dl><p>For classic single-player San Andreas on Windows x86. Only the executable build identified in the <a href="${escape(new URL(release.manifest, release.url).href)}">release manifest</a> is supported. Definitive Edition, MTA and SA-MP are unsupported. Use a valid free access key in the updated Scooby Launcher.</p><p><a class="collection-button" href="${escape(release.url)}">Download SA free beta (ZIP)</a></p><p>In Scooby Launcher, select Rockstar Classics → San Andreas → Classic and choose <code>gta-sa.exe</code>. Start the game before loading. Press Insert or F1 to open the menu after authentication. Keep the assets folder beside the DLL.</p><p>This is a beta release. Live gameplay and performance acceptance are pending; a successful load does not certify every feature.</p><p>Download size: ${(release.bytes / 1048576).toFixed(1)} MiB.<br>SHA-256: <code>${escape(release.sha256)}</code></p>`;
}
for (const game of catalog.games) {
  const availability = released(game) ? releaseDetails(game) : `<dl class="classics-facts"><div><dt>Port status</dt><dd>${label(game)}</dd></div><div><dt>Runtime verification</dt><dd>Not accepted</dd></div><div><dt>Release artifact</dt><dd>None available</dd></div><div><dt>Launch / download</dt><dd>Unavailable</dd></div></dl><p>No supported build or tested compatibility is claimed. ${game.state === 'queued' ? 'This title is queued, not a currently supported download.' : 'This port is in development and is not a released download.'}</p>`;
  outputs.set(`products/${game.id}/index.html`, shell(`${game.name} — ${label(game)}`, href(game), description(game), `<nav class="source-breadcrumb" aria-label="Breadcrumb"><a href="/rockstar-classics/">Rockstar Classics</a> / ${escape(game.name)}</nav><header class="classics-detail-heading"><span class="source-kicker">${label(game)}</span><h1>${escape(game.name)}</h1><p>${escape(notes[game.id])}</p></header><section class="source-note"><h2>Availability</h2>${availability}</section><section class="source-note"><h2>Separate settings &amp; scripts</h2><p>Settings directory: <code>${escape(game.settingsDirectory)}</code></p><p>${game.sync === 'full' ? 'Part of the full-sync GTA classics development group. Shared defaults must not load another title’s saved profiles, hotkeys or scripts.' : 'Partial sync of common conventions only; this title retains its own implementation and settings.'}</p><p>Game-specific capabilities require implementation and verification for this title. MTA:SA is outside this sync family.</p></section><a class="collection-button secondary classics-back" href="/rockstar-classics/">Back to Rockstar Classics</a>`));
}
for (const [file, content] of outputs) {
  const target = path.join(root, file);
  if (process.argv.includes('--check')) {
    if (!fs.existsSync(target) || fs.readFileSync(target,'utf8') !== content) throw new Error(`Regenerate ${file}: node tools/build-rockstar-classics.cjs`);
  } else { fs.mkdirSync(path.dirname(target), {recursive:true}); fs.writeFileSync(target,content); }
}
console.log(`${outputs.size} Rockstar Classics pages ${process.argv.includes('--check') ? 'verified' : 'generated'}.`);
