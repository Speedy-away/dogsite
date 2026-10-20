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
for (const [slug, [first, second, accent]] of Object.entries(games)) {
  const id = 'game-' + slug;
  cards[id] = { id, label: 'SCOOBY GAMES & TOOLS', lines: [first, second].filter(Boolean),
    subtitle: 'Explore the Scooby collection', detail: 'Product details, availability and related resources.', accent, icon: 'game' };
}

// Wiki previews have their own revision so other site embeds keep their assets.
const wikiCard = (id, label, lines, subtitle, detail, visual, extra = {}) => ({
 id, label, lines, subtitle, detail, visual, layout:'wiki', version:GUIDE_VERSION,
 accent:'#9aafff', icon:'book', ...extra
});
cards.guides = wikiCard('guides','GAME GUIDES',['Your game.','Made simple.'],'Setup, menu controls & fixes.','Pick a game. Follow the guide.','library');
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

function cardFor(file) {
  file = file.replace(/\\/g, '/');
  if (file === 'products/mta-sa/index.html') return { ...cards['game-mta-sa'], path: '/assets/images/mta-sa/launch-artwork.png', width: 1672, height: 941, alt: 'Multi Theft Auto logo over Los Santos at sunset. Free and Premium editions in user testing.' };
  let id = 'home';
  if (file.startsWith('guides/')) {
    const parts=file.split('/'), group=parts[1], topic=parts[2];
    if(group==='general') id='wiki-'+({ 'free-key':'free-key',faq:'antivirus',connection:'connection',crashing:'crashing',hwid:'hwid','linux-mac':'platforms',universal:'troubleshooting' }[topic]||'help');
    else if(group==='loading')id='wiki-loading';
    else if(group==='gta5'&&topic==='plus-setup')id='wiki-plus';
    else if(group==='gta5'&&topic==='hypervisor-vbs')id='wiki-vbs';
    else if(group==='source-games')id='wiki-source';
    else id=wikiGames.includes(group)?'wiki-game-'+group:'guides';
  }
  else if (/^(docs|api)\//.test(file)) id = 'docs';
  else if (/^(features-list|fivem-features|scooby-features)\//.test(file)) id = 'features';
  else if (file === 'products/free/index.html' || file === 'freekey.html') id = 'free';
  else if (file.startsWith('products/')) id = 'game-' + file.split('/')[1];
  else id = { store: 'store', 'source-games': 'source', 'more-games': 'more-games', changelog: 'changelog', download: 'download',
    videos: 'videos', resellers: 'resellers', sitemap: 'directory', 'best-mod-menu': 'compare', tos: 'terms' }[file.split('/')[0]] || id;
  if (!cards[id]) throw new Error('Missing social card for ' + file);
  return { ...cards[id], path: `/assets/images/social/${id}-${cards[id].version || VERSION}.png`, width: WIDTH, height: HEIGHT,
    alt: `${cards[id].label}: ${cards[id].lines.join(' ')} ${cards[id].subtitle}.` };
}

module.exports = { cards, cardFor, VERSION, GUIDE_VERSION, WIDTH, HEIGHT };
