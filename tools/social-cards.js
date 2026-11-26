/* Shared social-card catalog. Render with node tools/build-social-cards.js. */
const VERSION = 'v2';
const WIDTH = 1200;
const HEIGHT = 630;
const GUIDE_VERSION = 'v3';
const sections = {
  home: ['SCOOBY MENU', ['Your games.', 'Your Scooby.'], 'Cheats, mod menus & tools', 'Explore games, features and setup guides.', '#75adff', 'grid'],
  guides: ['SCOOBY WIKI', ['Setup guides.', 'Answers here.'], 'Installation · Settings · Troubleshooting', 'Find your game. Get up and running.', '#75adff', 'book'],
  support: ['SCOOBY SUPPORT', ['A little help.', 'A better start.'], 'Loader · Account · Troubleshooting', 'Find answers to common setup questions.', '#75adff', 'help'],
  docs: ['SCOOBY DEVELOPERS', ['Build something', 'of your own.'], 'Lua APIs · Examples · Native references', 'Documentation for your next script.', '#9c99ff', 'code'],
  store: ['SCOOBY STORE', ['Find your', 'next game.'], 'Free & premium access', 'Explore products, editions and plans.', '#75adff', 'grid'],
  'more-games': ['MORE GAMES', ['The Last of Us.', 'Megabonk.'], 'The Scooby More Games collection', 'Choose your game. Get a free key.', '#ffb16f', 'grid'],
  source: ['SOURCE & GOLDSRC', ['Classics.', 'New possibilities.'], 'The Scooby Source Games collection', 'Explore games, editions and availability.', '#ffb16f', 'grid'],
  features: ['SCOOBY FEATURES', ['Get to know', 'your tools.'], 'Features · Settings · Game controls', 'Explore what Scooby can do in your game.', '#75d4c1', 'sliders'],
  changelog: ['SCOOBY CHANGELOG', ['See what’s', 'new.'], 'Release notes · Improvements · Fixes', 'Follow the latest Scooby changes.', '#75d4c1', 'history'],
  download: ['SCOOBY LOADER', ['Your starting', 'point.'], 'Downloads & required runtimes', 'Get started with the Scooby loader.', '#75adff', 'download'],
  videos: ['SCOOBY VIDEOS', ['See Scooby', 'in action.'], 'Showcases & tutorials', 'Explore videos from across the collection.', '#f4a0c9', 'play'],
  resellers: ['SCOOBY RESELLERS', ['Find your', 'way to play.'], 'Official resellers & payment options', 'Explore regional stores for Scooby access.', '#75d4c1', 'globe'],
  directory: ['SCOOBY DIRECTORY', ['Everything.', 'One place.'], 'Games · Guides · Developer docs', 'Find your way around Scooby.', '#75adff', 'grid'],
  free: ['SCOOBY FREE ACCESS', ['Start exploring', 'for free.'], 'Products · Setup · Key access', 'Find free Scooby products and access steps.', '#75d4c1', 'key'],
  compare: ['EXPLORE SCOOBY', ['Find the tools', 'that fit.'], 'Features · Editions · Compatibility', 'Compare Scooby products and access options.', '#75adff', 'sliders'],
  terms: ['SCOOBY TERMS', ['Know the', 'details.'], 'Terms & conditions', 'Read the terms for using Scooby.', '#75adff', 'book'],
};
const games = {
  'mta-sa': ['MTA:SA', 'Free & Premium · Testing', '#e9bd80'],
  gta5: ['GTA 5', 'Legacy & Enhanced', '#75adff'],
  rdr2: ['Red Dead', 'Redemption 2', '#f39582'],
  fivem: ['FiveM', '', '#ffb16f'],
  redm: ['RedM', '', '#f39582'],
  cs2: ['Counter-Strike 2', '', '#ffb16f'],
  gmod: ['Garry’s Mod', '', '#75adff'],
  l4d: ['Left 4 Dead', '1 & 2', '#75d4c1'],
  sbox: ['S&box', '', '#f4a0c9'],
  megabonk: ['Megabonk', '', '#ffb16f'],
  'last-of-us': ['The Last of Us', 'Part I', '#75d4c1'],
  'half-life-1': ['Half-Life 1', '', '#ffb16f'],
  'half-life-2': ['Half-Life 2', '', '#ffb16f'],
  'half-life-2-deathmatch': ['Half-Life 2', 'Deathmatch', '#ffb16f'],
  tf2: ['Team Fortress 2', '& TF2 Classified', '#ffb16f'],
  css: ['Counter-Strike', 'Source', '#ffb16f'],
  portal: ['Portal 1 & 2', '', '#75adff'],
  'day-of-defeat-source': ['Day of Defeat', 'Source', '#75d4c1'],
  'black-mesa': ['Black Mesa', '', '#ffb16f'],
  'team-fortress-classic': ['Team Fortress', 'Classic', '#ffb16f'],
  'counter-strike': ['Counter-Strike', '1.6', '#ffb16f'],
  'day-of-defeat': ['Day of Defeat', '', '#75d4c1'],
  bodycam: ['Bodycam', '', '#75adff'],
  pubg: ['PUBG', '', '#ffb16f'],
  r6: ['Rainbow Six', 'Siege', '#75adff'],
  spoofer: ['HWID Spoofer', '& Cleaner', '#9c99ff'],
};
const cards = Object.fromEntries(Object.entries(sections).map(([id, [label, lines, subtitle, detail, accent, icon]]) =>
  [id, { id, label, lines, subtitle, detail, accent, icon }]));
// Homepage previews use a quiet brand image; keep other sections on their own revisions.
Object.assign(cards.home, { layout: 'brand', version: 'v3',
  alt: 'White Scooby dog outline centered on a subtly textured black background.' });
for (const [slug, [first, second, accent]] of Object.entries(games)) {
  const id = 'game-' + slug;
  cards[id] = { id, label: 'SCOOBY GAMES & TOOLS', lines: [first, second].filter(Boolean),
    subtitle: 'Explore the Scooby collection', detail: 'Product details, availability and related resources.', accent, icon: 'game' };
}

const resourceCovers = {
  resources: [['Game mods', '& downloads'], 'GTA 5 · RDR2 · CS2 · FiveM · RedM · L4D'],
  'resources-guides': [['Mod installation', 'guides'], 'Formats, compatibility and setup by game'],
  'resources-gta5': [['GTA 5', 'Resources'], 'Vehicles, outfits, Menyoo maps and addons', 'gta5'],
  'resources-rdr2': [['RDR2', 'Resources'], 'Outfits, addon peds and menu themes', 'rdr2'],
  'resources-cs2': [['Counter-Strike 2', 'Resources'], 'Custom models, skyboxes and textures', 'cs2'],
  'resources-fivem': [['FiveM', 'Resources'], 'Graphics packs, ReShade and textures', 'fivem'],
  'resources-redm': [['RedM', 'Resources'], 'Graphics, weapon skins, audio and UI presets', 'redm'],
  'resources-redm-graphics': [['RedM', 'Graphics packs'], 'PvP skies, RP presets and cinematic packs', 'redm'],
  'resources-l4d': [['Left 4 Dead', 'Resources'], 'Campaigns, survivor models and sound packs', 'l4d']
};
for (const [id, [lines, subtitle, game]] of Object.entries(resourceCovers)) {
  cards[id] = { id, label: 'SCOOBY RESOURCES', lines, subtitle, game,
    detail: id === 'resources-guides' ? 'Installation steps for all six games.' : 'Browse the collection and installation guides.',
    accent: game ? games[game][2] : '#cbb3ff', icon: 'download', version: 'v1' };
}

// Wiki previews have their own revision so other site embeds keep their assets.
const wikiCard = (id, label, lines, subtitle, detail, visual, extra = {}) => ({
 id, label, lines, subtitle, detail, visual, layout:'wiki', version:GUIDE_VERSION,
 accent:'#9aafff', icon:'book', ...extra
});
cards.guides = wikiCard('guides','PC & CONSOLE GUIDES',['Scooby Wiki'],'Setup, menu controls & fixes.','Pick a game. Follow the guide.','library');
const wikiTopics = {
 help: ['GENERAL HELP',['A clearer path.','A better start.'],'Downloads, accounts & troubleshooting.',['Download help','Account access','Common fixes']],
 loading: ['LOADING GUIDES',['Sign in.','Load. Play.'],'From your first login to the final step.',['Free or Premium','Choose your game','Check completion']],
 'free-key': ['FREE KEY GUIDE',['One free key.','All Free versions.'],'Get a new key every 24 hours.',['Get your key','Use Free login','Choose any Free game']],
 antivirus: ['DOWNLOAD & ANTIVIRUS HELP',['Find the block.','Follow the fix.'],'Clear screenshots. Settings explained.',['Find your antivirus','Check the alert','Follow the guide']],
 connection: ['CONNECTION HELP',['Connection lost?','Find the cause.'],'Website, loader & backend connection help.',['Check the error','Try another network','Backend & hosting']],
 crashing: ['CRASH & LOADING HELP',['Back up.','Start fresh.'],'Settings, runtimes & graphics drivers.',['Save your settings','Check the basics','Try the matching fix']],
 hwid: ['HARDWARE ID HELP',['New hardware?','Reset your HWID.'],'Reset through your Scooby account.',['Open the portal','Choose Reset HWID','7-day cooldown']],
 platforms: ['COMPATIBILITY GUIDE',['Your system.','Your setup.'],'Windows, Linux, Steam Deck & Mac.',['Check compatibility','Find your platform','Follow the setup']],
 troubleshooting: ['LOADER TROUBLESHOOTING',['Read the error.','Find the fix.'],'Sign-in, game detection & loading help.',['Match the message','Follow the checks','Try loading again']],
 plus: ['GTA 5 PLUS SETUP',['Plus setup.','Step by step.'],'UEFI, BIOS & bootloader guidance.',['Check your setup','Follow BIOS pictures','Load at next boot']],
 vbs: ['GTA 5 PLUS DIAGNOSTICS',['Hypervisor / VBS?','Check the status.'],'Read the result. Follow the matching help.',['Download check_vbs.bat','Read the verdict','Find the next step']],
 source: ['SOURCE GAME GUIDES',['Classic games.','Clear instructions.'],'Half-Life & the Source collection.',['Choose your game','Check requirements','Follow the guide']]
};
for (const [id,[label,lines,subtitle,steps]] of Object.entries(wikiTopics)) {
 cards['wiki-'+id]=wikiCard('wiki-'+id,label,lines,subtitle,'Scooby Wiki · Guides & support',id==='free-key'?'key':'steps',{steps});
}
const wikiGames = ['gta5','rdr2','fivem','redm','cs2','l4d','gmod','sbox','half-life-1','megabonk','tf2','last-of-us','mta-sa'];
for (const slug of wikiGames) {
 const [first,second]=games[slug];
 cards['wiki-game-'+slug]=wikiCard('wiki-game-'+slug,'GAME GUIDE',[first,slug==='mta-sa'?'Setup & status':second||'Setup & help'],
  slug==='mta-sa'?'Requirements & current loading status.':'Loading, menu controls & troubleshooting.',
  slug==='gta5'?'Free · Premium · Plus':slug==='mta-sa'?'Testing · Check availability':'Find your steps in the Scooby Wiki.',
  'game',{game:slug,steps:slug==='mta-sa'?['Requirements','Testing status','General help']:['Requirements','Loading steps','Menu & fixes']});
}

const additionalCards = {
  console: ['Console', 'PlayStation 4 catalog'],
  'console-gta5': ['GTA 5', 'PlayStation 4 · Coming soon'],
  'console-rdr2': ['Red Dead Redemption 2', 'Scooby PS4 v1.0.0 · Free + Premium'],
  'console-r6': ['Rainbow Six Siege', 'Scooby PS4 v1.0.3 · Released'],
  'console-scooby-manager': ['Scooby Manager', 'File and download manager · PS4'],
  'console-fortnite': ['Fortnite', 'PlayStation 4 · Coming soon'],
  'console-overwatch': ['Overwatch', 'PlayStation 4 · Coming soon'],
  'wiki-spoofer': ['Spoofer + Cleaner', 'Access, downloads and support'],
  'account-portal': ['Account portal', 'Sign in or register'],
  community: ['Community', 'Scooby community and resources'],
  'rockstar-classics': ['Rockstar Classics', 'Browse classic games'],
  'game-gta-sa': ['San Andreas', 'Rockstar Classics'],
  'game-gta-vc': ['Vice City', 'Rockstar Classics'],
  'game-gta3': ['GTA III', 'Rockstar Classics'],
  'game-gta4': ['GTA IV', 'Rockstar Classics'],
  'game-rdr1': ['Red Dead Redemption', 'Rockstar Classics'],
};
for (const [id, [title, subtitle]] of Object.entries(additionalCards)) {
  cards[id] = { id, label: id.startsWith('console') ? 'SCOOBY CONSOLE' : id.startsWith('wiki') ? 'SCOOBY WIKI' : 'SCOOBY MENU',
    lines: [title], subtitle, accent: '#c3a8fa' };
}
const featureGames = {
  gta: 'GTA 5', gta4: 'GTA IV', 'gta-sa': 'San Andreas', fivem: 'FiveM',
  rdr2: 'Red Dead Redemption 2', cs2: 'Counter-Strike 2', gmod: "Garry’s Mod",
  l4d: 'Left 4 Dead', tf2: 'Team Fortress 2', 'mta-sa': 'Multi Theft Auto',
  'half-life-1': 'Half-Life', 'last-of-us': 'The Last of Us', megabonk: 'Megabonk',
};
const guideGames = {
  gta5: 'GTA 5', rdr2: 'Red Dead Redemption 2', cs2: 'Counter-Strike 2',
  fivem: 'FiveM', redm: 'RedM', l4d: 'Left 4 Dead',
};
for (const [slug, title] of Object.entries(featureGames)) {
  const id = 'features-' + slug;
  cards[id] = { id, label: 'SCOOBY FEATURES', lines: [title], subtitle: 'Feature list', accent: '#a5c6ff' };
}
for (const [slug, title] of Object.entries({ ...guideGames, tf2: 'Team Fortress 2' })) {
  const id = 'docs-' + slug;
  cards[id] = { id, label: 'SCOOBY DEVELOPER DOCS', lines: [title], subtitle: 'Lua API reference', accent: '#c3a8fa' };
}
for (const [slug, title] of Object.entries(guideGames)) {
  const id = 'resources-guide-' + slug;
  cards[id] = { id, label: 'SCOOBY RESOURCE GUIDES', lines: [title], subtitle: 'Resource installation and setup', accent: '#96d8bc' };
}
for (const card of Object.values(cards)) {
  card.version = ['console-r6', 'console-scooby-manager'].includes(card.id) ? 'brand-v2' : 'brand-v1';
  card.alt = card.id === 'home' ? 'White Scooby outline on a dark textured background.' :
    card.label + ': ' + card.lines.join(' ') + ' ' + card.subtitle;
}

cards['console-r6'].version = 'v1.0.3';
cards['console-rdr2'].version = 'v1.0.0';

function cardFor(file) {
  file = file.replace(/\\/g, '/');
  let id = 'home';
  if (file === 'console/products/call-of-duty/index.html') id = 'console';
  else if (file.startsWith('console/')) id = file.startsWith('console/products/') ? 'console-' + file.split('/')[2] : 'console';
  else if (file.startsWith('guides/')) {
    const parts=file.split('/'), group=parts[1], topic=parts[2];
    if(group==='spoofer') id='wiki-spoofer';
    else if(group==='general') id='wiki-'+({ 'free-key':'free-key',faq:'antivirus',connection:'connection',crashing:'crashing',hwid:'hwid','linux-mac':'platforms',universal:'troubleshooting' }[topic]||'help');
    else if(group==='loading')id='wiki-loading';
    else if(group==='gta5'&&topic==='plus-setup')id='wiki-plus';
    else if(group==='gta5'&&topic==='hypervisor-vbs')id='wiki-vbs';
    else if(group==='source-games')id='wiki-source';
    else id=wikiGames.includes(group)?'wiki-game-'+group:'guides';
  }
  else if (file.startsWith('resources/')) {
    const game = file.split('/')[1];
    const guide = file.startsWith('resources/guides/') && 'resources-guide-' + file.split('/')[2];
    id = cards[guide] ? guide : file.startsWith('resources/redm/graphics-packs/') ? 'resources-redm-graphics' :
      Object.hasOwn(resourceCovers, 'resources-' + game) ? 'resources-' + game : 'resources';
  }
  else if (/^(docs|api)\//.test(file)) {
    const section = file.split('/')[1].replace(/_api_reference\.html$/, '');
    id = cards['docs-' + section] ? 'docs-' + section : 'docs';
  }
  else if (/^(features-list|fivem-features|scooby-features)\//.test(file)) {
    const slug = file.startsWith('fivem-features/') ? 'fivem' : file.split('/')[1].replace(/-features$/, '');
    id = cards['features-' + slug] ? 'features-' + slug : 'features';
  }
  else if (file === 'products/free/index.html' || file === 'freekey.html') id = 'free';
  else if (file.startsWith('products/')) id = 'game-' + file.split('/')[1];
  else if (/^rockstar-classics\/(gta-sa|gta-vc|gta3|gta4|rdr1)\//.test(file)) id = 'game-' + file.split('/')[1];
  else id = { portal: 'account-portal', community: 'community', 'rockstar-classics': 'rockstar-classics', store: 'store', 'source-games': 'source', 'more-games': 'more-games', changelog: 'changelog', download: 'download',
    videos: 'videos', resellers: 'resellers', sitemap: 'directory', 'best-mod-menu': 'compare', tos: 'terms' }[file.split('/')[0]] || id;
  if (!cards[id]) throw new Error('Missing social card for ' + file);
  return { ...cards[id], path: `/assets/images/social/${id}-${cards[id].version || VERSION}.png`, width: WIDTH, height: HEIGHT,
    alt: cards[id].alt || `${cards[id].label}: ${cards[id].lines.join(' ')} ${cards[id].subtitle}.` };
}

module.exports = { cards, cardFor, VERSION, GUIDE_VERSION, WIDTH, HEIGHT };
