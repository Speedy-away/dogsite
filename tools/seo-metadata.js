/* Search metadata: node tools/seo-metadata.js [--apply]. */
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..'), SITE = 'https://scoobymenu.cc';
const pages = {};
function add(file, title, description, keywords) { pages[file] = {title, description, keywords: 'Scooby Menu, ' + keywords}; }
const rows = `
index.html|Scooby Mod Menu: GTA 5, RDR2, FiveM, RedM, CS2 & GMOD|Explore Scooby mod menus for GTA 5, RDR2, FiveM, RedM, CS2 and Garry’s Mod. Compare free and premium editions, browse features and find setup guides.|Scooby mod menu, GTA 5 mod menu, RDR2 mod menu, FiveM mod menu, RedM mod menu, CS2 mod menu, GMOD mod menu
store/index.html|Scooby Store: Free & Premium Mod Menu Editions|Compare Scooby mod menu editions for GTA 5, RDR2, FiveM and RedM. Browse free products, lifetime plans, feature lists and available payment options.|Scooby store, buy Scooby menu, mod menu pricing, GTA 5 Premium Plus, lifetime mod menu
best-mod-menu/index.html|Choosing a Mod Menu: Features, Pricing & FAQs - Scooby|Compare Scooby mod menu features, free and premium options, compatibility and setup. Read answers about pricing, updates and game-ban risks.|mod menu comparison, best mod menu questions, Scooby pricing, free vs premium mod menu
changelog/index.html|Scooby Mod Menu Changelog & Release Notes|Read Scooby release notes for GTA 5, RDR2, FiveM, RedM and the loader. Track new features, improvements and fixes by version.|Scooby changelog, Scooby updates, mod menu release notes, Scooby loader updates
freekey.html|Get a Scooby Free Key - Mod Menu Access|Get a Scooby free key through the official key page. Follow the access steps, copy your key and use it with the Scooby loader.|Scooby free key, Scooby key page, free mod menu key, Scooby loader
resellers/index.html|Official Scooby Resellers & Payment Options|Find official Scooby mod menu resellers and their payment options. Browse regional stores and choose a reseller for your Scooby license.|official Scooby resellers, buy Scooby license, Scooby payment options
videos/index.html|Scooby Mod Menu Videos: Showcases & Setup Tutorials|Watch Scooby mod menu showcases and setup tutorials for GTA 5, RDR2, FiveM, RedM and CS2. Browse videos by game, topic and language.|Scooby videos, mod menu showcase, GTA 5 mod menu tutorial, FiveM setup video
 tos/index.html|Scooby Terms of Service: Purchases, Refunds & Usage|Read the Scooby terms of service for product access, payments, refunds, updates and support before purchasing or using a mod menu license.|Scooby terms of service, Scooby refund policy, Scooby purchase terms
products/gta5/index.html|GTA 5 Mod Menu for Legacy & Enhanced - Scooby|Explore the Scooby GTA 5 mod menu for Legacy and Enhanced. Compare free and premium editions with heist tools, vehicles, outfits and Lua scripting.|GTA 5 mod menu, GTA V mod menu, GTA 5 Legacy, GTA 5 Enhanced, GTA Online mod menu, heist editor
products/rdr2/index.html|RDR2 Mod Menu: Red Dead Redemption 2 - Scooby|Explore Scooby for Red Dead Redemption 2: player tools, horse spawners, teleports, recovery options and Lua scripting. See features and setup.|RDR2 mod menu, Red Dead Redemption 2 mod menu, Red Dead Online menu, RDR2 horse spawner
products/fivem/index.html|FiveM Mod Menu & Lua Executor - Scooby|Browse Scooby FiveM features including ESP, player tools, Lua execution and resource management. View screenshots, setup guides and lifetime access.|FiveM mod menu, Scooby FiveM, FiveM Lua executor, FiveM ESP, FiveM resource manager
products/redm/index.html|RedM Mod Menu & Lua Executor - Scooby|Explore Scooby RedM with player tools, ESP, Lua scripting and resource management. Browse screenshots, setup guides and premium access options.|RedM mod menu, Scooby RedM, RedM Lua executor, RedM ESP, RedM resource manager
products/cs2/index.html|Free CS2 Mod Menu & Skin Changer - Scooby|Explore the free Scooby Counter-Strike 2 menu with ESP, aim tools, skin, knife and glove changers. Browse screenshots, feature details and setup guides.|CS2 mod menu, free CS2 menu, Counter-Strike 2 skin changer, CS2 ESP, Scooby CS2
products/gmod/index.html|Free GMOD Mod Menu: Garry’s Mod - Scooby|Explore the free Scooby GMOD menu: Rage and Legit aim controls, ESP, chams, movement, radar and Lua tools. View screenshots and browse all features.|GMOD mod menu, Garry’s Mod menu, free GMOD menu, GMOD ESP, Scooby GMOD
products/free/index.html|Free Scooby Mod Menu: Supported Games & Key Access|See which Scooby products include free access, how the free-key system works and what limitations apply. Find the loader and setup instructions.|free Scooby mod menu, free GTA 5 mod menu, free RDR2 menu, Scooby free version, Scooby free key
products/spoofer/index.html|Scooby HWID Spoofer & Cleaner: Features & Access|Explore the Scooby HWID Spoofer and Cleaner for FiveM, RedM and GTA Online. Review supported uses, product details and free access instructions.|Scooby spoofer, HWID spoofer, FiveM cleaner, RedM cleaner, GTA Online cleaner
products/pubg/index.html|PUBG Mod Menu Preview: Coming Soon - Scooby|Preview the upcoming Scooby PUBG mod menu and its planned features. Check the product page for availability and development updates.|Scooby PUBG, PUBG mod menu preview, upcoming PUBG menu
products/r6/index.html|Rainbow Six Siege Mod Menu: Coming Soon - Scooby|Preview the upcoming Scooby Rainbow Six Siege mod menu. Explore planned features and check back for product availability and development updates.|Scooby R6, Rainbow Six Siege mod menu, R6 menu preview
products/sbox/index.html|S&box Mod Menu Preview: Coming Soon - Scooby|Preview the upcoming Scooby S&box mod menu for Source 2. Browse planned features and follow the product page for availability updates.|Scooby S&box, S&box mod menu, Source 2 menu preview
docs/index.html|Scooby Developer Docs: Lua APIs & Native References|Browse Scooby Lua API documentation for GTA 5, FiveM and RedM, plus searchable native references for game scripting and custom menu development.|Scooby documentation, Scooby Lua API, GTA 5 scripting, FiveM natives, RedM natives
features-list/gta-features/index.html|GTA 5 Mod Menu Feature List - Scooby|Browse the Scooby GTA 5 feature library: vehicles, heists, recovery, world options and player tools. Search feature names, descriptions and settings.|GTA 5 mod menu features, Scooby GTA 5 features, GTA 5 vehicle tools, GTA 5 recovery
features-list/gmod-features/index.html|GMOD Mod Menu Feature List - Scooby|Browse Scooby Garry's Mod features: Rage, Legit, ESP, chams, movement, gamemode tools, Lua, profiles and interface settings. Search the full feature library.|GMOD features, Garry’s Mod menu features, Scooby GMOD, GMOD ESP, GMOD Lua
features-list/rdr2-features/index.html|RDR2 Mod Menu Feature List - Scooby|Search the Scooby Red Dead Redemption 2 feature library for player options, weapons, horses, world settings, teleports and recovery tools.|RDR2 mod menu features, Scooby RDR2 features, Red Dead Redemption 2 tools
fivem-features/index.html|FiveM Mod Menu Feature List - Scooby|Explore Scooby FiveM features and settings for visuals, combat, movement, local player options and server tools in the searchable feature library.|FiveM mod menu features, Scooby FiveM features, FiveM visuals, FiveM server tools
scooby-features/index.html|GTA 5 Mod Menu Highlights & Overview - Scooby|Explore Scooby GTA 5 feature highlights, including outfit and vehicle options, world controls, special powers and player tools. Browse the overview by topic.|Scooby GTA 5 overview, GTA 5 mod menu highlights, GTA 5 special powers
guides/index.html|Scooby Setup Guides: Installation & Troubleshooting|Find Scooby setup guides for GTA 5, RDR2, FiveM, RedM and CS2, plus loader downloads, free-key help, account support and troubleshooting.|Scooby guides, Scooby setup, mod menu installation, Scooby troubleshooting
`;
for (const row of rows.trim().split('\n')) add(...row.trim().split('|'));
for (const [slug, game] of [['gta5','GTA 5'],['fivem','FiveM'],['redm','RedM']]) add(`${slug}_api_reference.html`, `${game} Lua API Reference - Scooby Developer Docs`, `Read the Scooby ${game} Lua API reference. Look up scripting functions, parameters, return values and examples for building scripts and custom interfaces.`, `${game} Lua API, Scooby ${game} scripting, ${game} Lua functions`);
for (const [slug, game, base] of [['fivem','FiveM','GTA V'],['redm','RedM','RDR2']]) add(`docs/${slug}/index.html`, `${game} Native Reference: ${base} & Scooby Functions`, `Search ${game} and ${base} native functions by namespace. Browse signatures, parameters and custom Scooby natives for scripting, memory and HTTP requests.`, `${game} native reference, ${base} natives, Scooby natives`);
const groups = [
 ['gta5','GTA 5','Set up Scooby for GTA 5 Legacy or Enhanced. Find first-time installation, free-version limits, outfits, vehicles, money tools and troubleshooting guides.'],
 ['rdr2','RDR2','Set up Scooby for Red Dead Redemption 2. Find launch requirements, injection instructions, DirectX 12 crash fixes and support resources.'],
 ['fivem','FiveM','Set up Scooby for FiveM with runtime requirements and injection instructions. Read about server events, feature limitations and troubleshooting.'],
 ['redm','RedM','Set up Scooby for RedM with runtime requirements and injection instructions. Find server-event guidance, feature limitations and troubleshooting.'],
 ['cs2','CS2','Set up Scooby for Counter-Strike 2. Find required runtimes, injection instructions, and help when features stop working after game updates.'],
 ['general','Loader','Find help with the Scooby loader, downloads, free keys, HWID resets and account access. Browse crash fixes, connection errors and compatibility guides.']
];
for (const [slug, game, desc] of groups) add(`guides/${slug}/index.html`, `${game} Setup & Troubleshooting Guides - Scooby`, desc, `Scooby ${game} setup, ${game} installation guide, Scooby ${game} troubleshooting`);
function guide(group, slug, title, desc, keywords) { add(`guides/${group}/${slug}/index.html`, title + ' - Scooby Guide', desc, keywords); }
for (const [slug, game] of [['cs2','CS2'],['fivem','FiveM'],['redm','RedM']]) {
 guide(slug,`${slug}-requirements`,`${game} Menu Requirements & VC Runtimes`, `Check the Visual C++ runtime requirements for Scooby ${game}. Find the x86 and x64 runtime links and related setup troubleshooting guides.`, `${game} menu requirements, ${game} VC runtimes, Scooby ${game} setup`);
 guide(slug,`${slug}-inject`,`How to Load Scooby in ${game}`, slug === 'cs2' ? 'Learn how to load Scooby into Counter-Strike 2 using automatic loading or manual injection from the main menu, with links to troubleshooting.' : `Learn when and how to inject Scooby into ${game}, from the main menu or resource loading screen, with step-by-step instructions and troubleshooting links.`, `Scooby ${game} injection, how to load Scooby ${game}, ${game} menu setup`);
}
guide('cs2','cs2-updates','CS2 Menu Features Not Working After an Update','Find out why Scooby CS2 features may stop working after a game patch, where to check update status and when to update your loader.','CS2 features not working, Scooby CS2 update, CS2 menu troubleshooting');
for (const [slug, game] of [['fivem','FiveM'],['redm','RedM']]) guide(slug,'money-items-weapons',`${game} Money, Items & Weapons: Server Limits`, `Understand ${game} server events for money, items and weapons, including server-side requirements, restrictions, kick or ban risks and Scooby support limits.`, `${game} server events, ${game} money items weapons, ${game} event restrictions`);
const topics = `
general|connection|Scooby Connection & SSL Error Help|Troubleshoot Scooby website and loader connection or SSL errors. Read the connection guidance and find links to related setup and account help.|Scooby connection error, Scooby SSL error, Scooby loader connection
general|crashing|Scooby Crashing: Settings, Runtimes & Drivers|Troubleshoot Scooby crashes with checks for old settings, required runtimes, graphics drivers, system time and Windows account permissions.|Scooby crashing, Scooby crash fix, Scooby runtimes
general|faq|Scooby Download & Antivirus FAQ|Read answers about Scooby loader downloads, antivirus warnings and files removed by Windows Security, with links to setup and troubleshooting guides.|Scooby download help, Scooby antivirus warning, Scooby loader deleted
general|free-key|How to Get & Use a Scooby Free Key|Follow the Scooby free-key guide to obtain and enter your key. Learn about key resets, official download links and free-version session limits.|how to get Scooby free key, Scooby key reset, Scooby free key guide
general|hwid|How to Reset Your Scooby HWID|Reset your Scooby hardware ID from your portal profile after hardware changes or an HWID mismatch. Learn where to find the reset and how cooldowns work.|Scooby HWID reset, Scooby hardware ID mismatch, Scooby portal profile
general|linux-mac|Scooby on Linux & Mac: Compatibility Setup|Read Scooby compatibility guidance for Linux and Mac using Lutris, Wine or CrossOver. Learn about shared prefixes, fonts and performance limitations.|Scooby Linux, Scooby Mac, Scooby Wine, Scooby Lutris, Scooby CrossOver
general|universal|Scooby Loader & Injection Troubleshooting|Find Scooby troubleshooting help for injection failures, loader errors, crashes and Windows permissions. Browse fixes by the error you encounter.|Scooby injection failed, Scooby loader error, Scooby not injecting
gta5|first-time|GTA 5 Mod Menu: First-Time Setup|Install and launch Scooby for GTA 5. Follow the first-time guide for downloading the loader, installing runtimes, injecting and opening the menu.|GTA 5 mod menu installation, Scooby GTA 5 setup, open Scooby menu
gta5|free-setup|Free GTA 5 Menu Setup: Legacy & Enhanced|Set up the free Scooby menu for GTA 5 Legacy and Enhanced. Follow the launch sequence and understand invite-only sessions and free-version limits.|free GTA 5 mod menu setup, GTA 5 Legacy free menu, GTA 5 Enhanced free menu
gta5|host-public|GTA Online Session Hosting: NAT & Matchmaking|Read Scooby’s GTA Online hosting guide covering NAT type, aim settings, region and timing, with explanations of connectivity and matchmaking limits.|GTA Online session hosting, GTA Online NAT type, GTA Online matchmaking
gta5|introduction|GTA 5 Mod Menu Guide: Getting Started|Start with the Scooby GTA 5 guide. Find the recommended reading order for setup, outfits, vehicles, online sessions and common troubleshooting topics.|Scooby GTA 5 introduction, GTA 5 mod menu guide, getting started Scooby
gta5|money|GTA 5 Money Tools: Heists, Casino & Businesses|Read the Scooby GTA 5 money tools guide covering heist settings, casino options and business supplies, with menu locations for each method.|Scooby GTA 5 money tools, GTA 5 heist editor guide, GTA 5 business supplies
gta5|outfits|GTA 5 Outfit Editor: Import & Save Outfits|Use the Scooby GTA 5 outfit editor to create and save outfits. Learn where to place shared outfit files and how to find them in the menu.|GTA 5 outfit editor, Scooby modded outfits, GTA 5 import outfits
gta5|vehicles|GTA 5 Modded Vehicles: Import & Customize|Read the Scooby GTA 5 vehicle guide to use shared vehicles and customize your own. Find vehicle file locations and the relevant menu options.|GTA 5 modded vehicles, Scooby vehicle guide, GTA 5 vehicle customization
gta5|troubleshooting|GTA 5 Menu Errors & Injection Troubleshooting|Troubleshoot Scooby GTA 5 injection errors, black screens and launch problems. Find explanations for common messages and links to further support.|Scooby GTA 5 errors, GTA 5 failed to allocate memory, Scooby GTA 5 black screen
rdr2|rdr2-before|RDR2 Mod Menu: Before You Launch|Check the Scooby Red Dead Redemption 2 preparation guide before launching. Review the setup steps and continue to the menu launch instructions.|RDR2 mod menu preparation, Scooby RDR2 requirements, RDR2 before launching
rdr2|rdr2-crashing|RDR2 Menu Crashing? DirectX 12 Setup|Follow the Scooby RDR2 crash guide to change the game’s graphics API to DirectX 12. Find the graphics setting and related troubleshooting resources.|Scooby RDR2 crashing, RDR2 DirectX 12, RDR2 graphics API
rdr2|rdr2-launch|How to Launch the Scooby RDR2 Menu|Follow the launch instructions for Scooby Red Dead Redemption 2. Learn the loading sequence and find links to preparation and crash troubleshooting.|launch Scooby RDR2, RDR2 menu setup, Scooby Red Dead Redemption 2 guide
rdr2|rdr2-more-help|RDR2 Mod Menu Support & Troubleshooting Help|Find further help for Scooby Red Dead Redemption 2 when setup or crash fixes do not resolve your issue. Open the support resources from the guide.|Scooby RDR2 support, RDR2 menu troubleshooting, Scooby RDR2 help
`;
for (const row of topics.trim().split('\n')) guide(...row.split('|'));
const escape = s => s.replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
const decode = s => s.replace(/&quot;/g,'"').replace(/&#39;|&apos;/g,"'").replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
function attrs(tag) { return Object.fromEntries([...tag.matchAll(/([\w:-]+)\s*=\s*(["'])([\s\S]*?)\2/g)].map(m=>[m[1].toLowerCase(),decode(m[3])])); }
function excluded(head) { return [...head.matchAll(/<meta\b[^>]*>/gi)].some(m=>{const a=attrs(m[0]);return a.name?.toLowerCase()==='robots' && /noindex/i.test(a.content) || a['http-equiv']?.toLowerCase()==='refresh';}); }
function applyMetadata(file, html) {
 file=file.replace(/\\/g,'/'); const meta=pages[file]; if(!meta) return html;
 return html.replace(/<head\b[^>]*>[\s\S]*?<\/head>/i, head=>{
  if(excluded(head))return head;
  const nl=head.includes('\r\n')?'\r\n':'\n';
  const url=SITE+'/'+(file==='index.html'?'':file.replace(/index\.html$/,''));
  const append=tag=>{head=head.replace(/<\/head>/i,tag+nl+'</head>');};
  function set(key,value,property=false){let found=false;const tag=`<meta ${property?'property':'name'}="${key}" content="${escape(value)}">`;head=head.replace(/<meta\b[^>]*>/gi,old=>{const a=attrs(old);if((a.name||a.property||'').toLowerCase()!==key)return old;if(found)return '';found=true;return tag;});if(!found)append(tag);}
  head=head.replace(/<title\b[^>]*>[\s\S]*?<\/title>/i,`<title>${escape(meta.title)}</title>`);
  set('description',meta.description);set('keywords',meta.keywords);set('robots','index, follow, max-image-preview:large');
  for(const prefix of ['og','twitter']) for(const [key,value] of [['title',meta.title],['description',meta.description],['url',url]])set(`${prefix}:${key}`,value,prefix==='og');
  set('og:type','website',true);set('og:site_name','Scooby Menu',true);
  const image=[...head.matchAll(/<meta\b[^>]*>/gi)].map(m=>attrs(m[0])).find(a=>a.property==='og:image')?.content || SITE+'/background-home.jpg';
  set('og:image',image,true);set('twitter:image',image);set('twitter:card','summary_large_image');
  let found=false;head=head.replace(/<link\b[^>]*>/gi,old=>{if(attrs(old).rel!=='canonical')return old;if(found)return '';found=true;return `<link rel="canonical" href="${url}">`;});if(!found)append(`<link rel="canonical" href="${url}">`);
  head=head.replace(/(<script\b[^>]*type=["']application\/ld\+json["'][^>]*>)([\s\S]*?)(<\/script>)/gi,(whole,start,json,end)=>{
   const data=JSON.parse(json);let changed=false;
   function visit(v){if(!v||typeof v!=='object')return;if(['SoftwareApplication','WebPage','CollectionPage'].includes(v['@type']) && v.description && v.description!==meta.description){v.description=meta.description;changed=true;}for(const child of Object.values(v))if(typeof child==='object')visit(child);}
   visit(data);return changed?start+nl+JSON.stringify(data,null,2).replace(/</g,'\\u003c').replace(/\n/g,nl)+nl+end:whole;
  });
  return head;
 });
}
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>{if(['.git','.claude','node_modules','revolution','tools','languages'].includes(e.name))return [];const p=path.join(dir,e.name);return e.isDirectory()?walk(p):e.name.endsWith('.html')?[p]:[];});}
if(require.main===module){let changed=0,skipped=0;const errors=[],titles=new Set(),descriptions=new Set();
 for(const abs of walk(ROOT)){const file=path.relative(ROOT,abs).replace(/\\/g,'/'),html=fs.readFileSync(abs,'utf8'),head=html.match(/<head\b[^>]*>[\s\S]*?<\/head>/i)?.[0]||'';if(excluded(head)){skipped++;continue;}if(!pages[file]){errors.push('Missing metadata: '+file);continue;}const meta=pages[file];if(titles.has(meta.title)||descriptions.has(meta.description))errors.push('Duplicate metadata: '+file);titles.add(meta.title);descriptions.add(meta.description);const updated=applyMetadata(file,html);if(updated!==html){changed++;if(process.argv.includes('--apply'))fs.writeFileSync(abs,updated);else console.log('Stale: '+file);}}
 console.log(`${titles.size} indexable pages; ${skipped} excluded pages preserved; ${changed} ${process.argv.includes('--apply')?'updated':'stale'}.`);errors.forEach(e=>console.error(e));if(errors.length||changed&&!process.argv.includes('--apply'))process.exitCode=1;
}
module.exports={applyMetadata,pages};
