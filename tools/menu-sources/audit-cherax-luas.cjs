/* Metadata-only local audit. Reads bytes/text; never loads or evaluates Lua. */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const ROOT = path.resolve(__dirname, '../..');
const SOURCE = process.argv[2] || path.resolve(ROOT, '../cherax-luas');
const LUA = path.join(SOURCE, 'luas');
const OUT = path.join(ROOT, 'project/community-menu-sources/cherax-lua-audit.json');
const slash = x => x.replace(/\\/g, '/');
const walk = dir => fs.readdirSync(dir, {withFileTypes:true}).flatMap(e => e.isDirectory() ? walk(path.join(dir,e.name)) : [path.join(dir,e.name)]);
const all = walk(LUA).filter(f => f.endsWith('.lua'));
const records = all.map(file => {
  const bytes = fs.readFileSync(file), rel = slash(path.relative(SOURCE,file));
  return { path:rel, size:bytes.length, sha256:crypto.createHash('sha256').update(bytes).digest('hex'), bytecode:bytes[0]===27, text:bytes[0]===27?'':bytes.toString('utf8') };
});
const main = records.filter(r => !/\/(?:Sources|K-Script-main)\//.test(r.path));
// Versions below come from identity declarations or explicit release headers.
// Filenames that disagree with declarations are recorded separately.
const defs = [
  ['auto-translator','Auto Translator','Auto-Translator.lua',null,null,['Translation','Utility']],
  ['body-accessories','Body Accessories','Body-Accessories.lua',null,null,['Outfits','Props']],
  ['bunnyscript','BunnyScript','BunnyScript LE & EE v2.5.lua','2.5',null,['Utility','Legacy','Enhanced']],
  ['chat-commands','Chat Commands','Chat Commands v2.0.lua','2.0','MMmitch',['Chat','Utility']],
  ['cherax-doom','Cherax Doom','Cherax-Doom.lua','1.0.0',null,['Minigame','DOOM']],
  ['codax','Codax','Codax.lua',null,null,['Heists','Compiled']],
  ['daivekit','DaiveKit','DaiveKit-v2.7.1.lua','2.7.1',null,['Utility','Compiled']],
  ['driftgod','DriftGod','DriftGod v1.0.7.lua','1.0.7','Public_Urinal / Animus',['Vehicles','Drift']],
  ['earplugs','Earplugs','Earplugs.lua','1.0.1',null,['Audio','Utility']],
  ['elloscript','ElloScript','ElloScript-v1.5.lua','1.5','elloeu',['Utility']],
  ['extended-constructor','Extended Constructor','Extended-Constructor.lua',null,'Elfish-beaker',['Constructor','Props']],
  ['host-tools','Host Tools','Host-Tools-v1.7.2.lua','1.7.2','Plynko',['Session','Utility']],
  ['hulk-mode','Hulk Mode','HULK MODE v3.1 .lua','vBETA',null,['Player','Effects']],
  ['hustlemeter','HustleMeter','HustleMeter-v1.0.9.lua','1.0.9','Public_Urinal',['HUD','Ledger']],
  ['gun-van','Ji9sw Gun Van','J19sw-Gun-Van.lua',null,'Ji9sw',['Vehicles','Utility']],
  ['kortz-heist','Kortz Heist Helper','Kortz-Heist-Helper.lua',null,'Forlax',['Heists']],
  ['liquidfit','LiquidFit','LiquidFit-Outfit-manager.lua','1.1.1',null,['Outfits','Editor']],
  ['minigames','Minigames','Minigames-1.0.0.lua','1.0.0','Animus',['Minigame']],
  ['modverse','ModVerse','MODVERSE-1.0.0.lua','1.0.0','Public_Urinal',['Marketplace','Vehicles','Outfits']],
  ['optimized-bodyguards','Optimized Bodyguards','OptimizedBodyguards.lua',null,null,['Bodyguards']],
  ['outfit-editor','Outfit Editor','Outfit-Editor.lua',null,null,['Outfits','Editor']],
  ['outfitforge','OutfitForge','OutfitForge.lua',null,null,['Outfits','Editor']],
  ['paintlabs','PaintLabs','PaintLabs-1.02.lua','1.0.0','Public_Urinal',['Vehicles','Paint']],
  ['pvp-helper','PVP Helper','PvP-helper-v3.lua','1.1.3',null,['Player','Utility']],
  ['silent-night','Silent Night','Silent-Night-v1.13.3.lua','1.13.3',null,['Heists','GTA 1.73']],
  ['smart-console','Smart Console','Smart-Console.lua','1.0.1',null,['Console','Utility']],
  ['sovereign','Sovereign','Sovereign2.lua',null,null,['Utility']],
  ['startup','Startup','Startup v1.0.18.lua','1.0.18','Public_Urinal',['Session','HUD']],
  ['trackmatic','Trackmatic','TRACKMATIC v1.0.1.lua','1.0.1','Public_Urinal',['Tracks','Constructor']],
  ['vehicle-forge','Vehicle Forge','Vehicle-Forge.lua','1.0.1',null,['Vehicles','Editor']],
  ['vibescript','VibeScript','Vibescript v2.5.0 .lua','2.2.1',null,['Utility']],
  ['aerials','Aerials','pointless/Aerials.lua',null,null,['Vehicles','Protected']],
  ['bodyguards','Bodyguards','pointless/BetterBodyguards.lua','4.0',null,['Bodyguards']],
  ['chairhax','Chairhax','Sources/Chairhax-Lua-main/lua/Chairhax E&E.lua','3.0.5','SATTY91',['Utility','Source package']],
  ['cheems-translator','CheemsTranslator','pointless/CheemsTranslator.lua','2.1.7',null,['Translation','Chat']],
  ['cherax-chat','Cherax Chat','pointless/Cherax-chat.lua',null,null,['Chat']],
  ['crimson-vehicles','Crimson Vehicles','pointless/Crimson-Vehicles.lua',null,null,['Vehicles']],
  ['cyberpilot-hud','CyberPilot HUD','pointless/CyberPliot-Hud.lua',null,'Elfish-beaker',['HUD']],
  ['discord-rpc-reborn','Discord RPC Reborn','pointless/Discord-RPC-Reborn.lua','1.2.4','nightkitty',['Rich Presence','Utility']],
  ['fireworks-menu','Fireworks Menu','pointless/Fireworks-menu.lua',null,null,['Effects']],
  ['flying-cars-sa','Flying Cars SA','pointless/Flying-Cars.lua','1.0.1 Alpha',null,['Vehicles','Flight','Alpha']],
  ['racing-lines','Ji9sw Racing Lines','pointless/Ji9sw-Racing-Lines.lua',null,'Ji9sw',['Vehicles','Racing']],
  ['meow-party-emotes','Meow Party Emotes','pointless/MeowPartyEmotes.lua',null,'daniela_xo',['Animations','Emotes']],
  ['spooner','Cherax Spooner','pointless/Sponner.lua',null,'Alsdrouf',['Constructor','XML']],
  ['trolley','Trolley','pointless/Trolley.lua',null,null,['Utility','Compiled']],
  ['vroom','VROOM','pointless/VROOM.lua',null,'bigd / itsWiggity (integration credit)',['Vehicles']],
  ['x-script','X-Script','pointless/X-Script.lua','Public 1 / Test 94.7','GODX7PRIME',['Utility','Personal use']],
];
const patterns = {
 'bunnyscript':/bunnyscript/i,'body-accessories':/body-accessories/i,'codax':/codax/i,'daivekit':/daivekit/i,
 'driftgod':/driftgod/i,'elloscript':/elloscript/i,'host-tools':/host-?tools/i,'hustlemeter':/hustlemeter/i,
 'gun-van':/(?:j[1i]9sw.*gun.?van|gunvan)/i,'kortz-heist':/kortz/i,'liquidfit':/liquidfit/i,
 'minigames':/minigames/i,'paintlabs':/paintlabs/i,'pvp-helper':/pvp-helper/i,'silent-night':/silent[ -]?night/i,
 'sovereign':/sovereign/i,'startup':/startup/i,'vehicle-forge':/vehicle-?forge/i,'vibescript':/vibescript|vibeScript/i,
 'crimson-vehicles':/crimson-vehicles/i,'cyberpilot-hud':/cyberp[il]+ot[ -]hud/i,'racing-lines':/racing-lines/i,
};
const repos = {
 'auto-translator':'https://github.com/Do6563/Cherax-Translation-Hub',
 'bunnyscript':'https://github.com/FlixzySus/BunnyScript',
 'cherax-doom':'https://github.com/RealToasterBoi/Cherax-Doom',
 'spooner':'https://github.com/Alsdrouf/CheraxSpooner',
 'cheems-translator':'https://github.com/dev-cheemlord/CheemsTranslator',
 'extended-constructor':'https://github.com/Elfish-beaker/object-list',
 'cyberpilot-hud':'https://github.com/Elfish-beaker/object-list',
 'liquidfit':'https://github.com/imoliverokay/LiquidFit',
 'modverse':'https://github.com/xReVoLTiThemeDev/GTAV-Cherax-ModVerse-Marketplace',
};
for(const id of ['driftgod','minigames','startup','hustlemeter','trackmatic'])repos[id]='https://github.com/xReVoLTiThemeDev/GTAV-Cherax';
const conflicts = {
 'hulk-mode':'Filename says v3.1; identity declaration says Hulk Mode vBETA. Public release version unverified.',
 'host-tools':'Header retains 0.28b (v85), while HTV.VERSION and loaded banner report 1.7.2.',
 'paintlabs':'Filename says 1.02; SCRIPT_VERSION is 1.0.0. Uses the declared identity.',
 'pvp-helper':'Filename says v3; SCRIPT_VERSION is 1.1.3. Uses the declared identity.',
 'vibescript':'Files labelled v2.5.0 and 2.2.1 have identical SHA256; VIBE_VERSION is 2.2.1.',
 'sovereign':'Sovereign-1.0.0.lua and Sovereign2.lua differ; visible 2.3.0-local-r56 belongs to an internal module, not a verified public release. Version left unknown.',
 'chairhax':'Version 3.0.5 is from the source-package CHANGELOG.md. No claim that the separate compiled ChairHax.lua is this version.',
 'daivekit':'Version 2.7.1 is filename evidence only; compiled Lua contents were not interpreted.',
 'bunnyscript':'Version 2.5 is filename evidence; not asserted as the current author release.',
};
const dated = {
 'startup':[{date:'2026-10-02',version:'1.0.18',changes:['Adds browser event notifications and an expanded minimap HUD adapter.','Persists retaliation settings and fixes the disabled auto-bounty setting after reload.'],dateBasis:'startup.build_date and production header'}],
 'hustlemeter':[{date:'2026-08-14',version:'1.0.9',changes:['Removes Smart Heists integration and its controls for other scripts.'],dateBasis:'script_build = 2026.08.14.061 and versioned header changelog'}],
 'minigames':[{date:'2026-08-02',version:'1.0.0',changes:['Introduces the production Minigames release.'],dateBasis:'script_release_date and initial production changelog'}],
};
const used = new Set();
const items = defs.map(([id,name,preferred,version,author,tags]) => {
 const first = records.find(r=>r.path==='luas/'+preferred); if(!first)throw Error('Missing '+preferred);
 let copies=main.filter(r => r.path===first.path || (patterns[id]&&patterns[id].test(path.basename(r.path))) || r.sha256===first.sha256);
 if(id==='chairhax')copies=[first,...main.filter(r=>/\/ChairHax\.lua$/i.test(r.path))];
 if(id==='vibescript')copies.push(...main.filter(r=>r.text.includes('VIBE_VERSION =')&&!copies.includes(r)));
 copies=[...new Map(copies.map(r=>[r.path,r])).values()]; copies.forEach(r=>used.add(r.path));
 const metadata=[];
 for(const [i,line] of first.text.split(/\r?\n/).entries()){
  if(line.length<260&&/^(?:\s*(?:--)?\s*(?:local )?(?:SCRIPT_VERSION|SCRIPT_BUILD|VIBE_VERSION|VERSION|HTV.VERSION|startup.version|startup.build_date|startup.developer|script_version|script_release_date|script_build|TG_VERSION)\s*=)|^\s*(?:--)?\s*(?:Version:|developed by:|Credits:|--Credit:)/i.test(line))metadata.push({line:i+1,text:line.trim()});
  if(metadata.length===12)break;
 }
 const proven={type:'local-source-audit',localRoot:'../cherax-luas',localPaths:copies.map(r=>({path:r.path,sha256:r.sha256,size:r.size,encoding:r.bytecode?'lua-bytecode':'text',collection:r.path.includes('/random/old/')?'archival':'unclassified'})),identityEvidence:metadata};
 if(repos[id])proven.authorSource={url:repos[id],basis:'Referenced by local script or project documentation; current release status not verified'};
 if(conflicts[id])proven.notes=[conflicts[id]];
 return {id:'cherax-lua-'+id,game:'gta5',category:'lua',sourceChannelCategory:'lua-scripts',name,sourceMenu:'Cherax',supportedMenus:['Cherax'],downloadStatus:'pending',files:[],tags:['Cherax',...tags],version,author:author||'Author unverified',collectionStatus:'unclassified',description:name+' for the Cherax Lua host. Download preparation is pending.',compatibility:'Requires the original Cherax Lua API and any script-specific assets or game build. Scooby, Nenyoo and Stand Lua compatibility has not been verified.',validationStatus:first.bytecode?'bytecode-not-interpreted':/protected_pack_b64/.test(first.text)?'protected-source-not-decoded':'metadata-only-not-runtime-validated',changelog:dated[id]||[],provenance:proven};
});
const exclusions=main.filter(r=>!used.has(r.path)).map(r=>({path:r.path,sha256:r.sha256,reason:/ELE Orbits\s*=/.test(r.text)?'Invalid Lua identifier declaration: local ELE Orbits; excluded as visibly broken source.':r.path.endsWith('Davikitsoo.lua')?'Compiled file with unresolved project identity; excluded rather than conflating it with DaiveKit.':/^-- Cherax Startup Script/.test(r.text)?'Anonymous default startup sample; excluded with the previously disabled imported examples.':'Unclassified source; requires individual identity review before listing.'}));
const reconstructed=records.filter(r=>r.path.includes('/K-Script-main/'));
const unrelated=records.filter(r=>r.path.includes('/Sources/Milk-luas/'));
const chair=records.filter(r=>r.path.includes('/Sources/Chairhax-Lua-main/'));
const result={schemaVersion:1,menu:'Cherax',auditedAt:'2026-11-11',method:'Filesystem inventory, text identity/header checks and SHA256 only. No Lua executed, required, loaded, decoded or decompiled. No Discord client, credentials, account databases or private APIs accessed.',coverage:{directLuaFiles:main.filter(r=>r.path.split('/').length===2).length,pointlessLuaFiles:main.filter(r=>r.path.startsWith('luas/pointless/')).length,archivalRandomLuaFiles:main.filter(r=>r.path.startsWith('luas/random/')).length,namedCards:items.length,representedLocalCopies:used.size,excludedMainCopies:exclusions.length,chairhaxPackageLuaFiles:chair.length,reconstructionLuaFilesExcluded:reconstructed.length,unrelatedMilkSourceLuaFilesNotReviewed:unrelated.length,totalLuaFilesInventoried:records.length},items,exclusions,excludedCollections:[{path:'luas/K-Script-main',luaFiles:reconstructed.length,reason:'AI-cleaned/decompiled reconstruction and fragments, not an original verified author release.'},{path:'luas/Sources/Milk-luas',luaFiles:unrelated.length,reason:'Other-menu/FiveM archives outside Cherax scope; filenames counted, contents not audited.'}],publicSourceChecks:[{url:'https://github.com/Alsdrouf/CheraxSpooner',observedAt:'2026-11-11',result:'Public author repository identifies Spooner mode for Cherax. No published release listed.'},{url:'https://github.com/xReVoLTiThemeDev/GTAV-Cherax',observedAt:'2026-11-11',result:'Public author archive identifies Animus / xReVoLTiThemeDev and distinguishes experimental, release and archived builds. This does not verify any local copy is current.'},{url:'https://github.com/FlixzySus/BunnyScript',observedAt:'2026-11-11',result:'Browser retrieval failed; local referenced source URL retained as evidence only.'},{url:'https://github.com/dev-cheemlord/CheemsTranslator',observedAt:'2026-11-11',result:'Browser retrieval failed; local referenced source URL retained as evidence only.'}],acquisitionGaps:['Current and old Discord Lua channels were not inspected in this audit; no claim of exhaustive share coverage.','All Lua downloads remain pending with empty file arrays. These cards do not re-enable previously removed payloads.','Undated changelog text is omitted from dated changelog arrays; file modification times are never used as release dates.','Preview screenshots were not verified for these local scripts. Dependency logos are not treated as screenshots.','Many authors and public release versions remain unverified. Version discrepancies are retained in provenance.','Source text inspection does not establish current host/game compatibility or runtime correctness.'],localInventory:records.map(({path,size,sha256,bytecode})=>({path,size,sha256,encoding:bytecode?'lua-bytecode':'text'}))};
fs.mkdirSync(path.dirname(OUT),{recursive:true});fs.writeFileSync(OUT,JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({output:OUT,coverage:result.coverage,excluded:exclusions.map(x=>({path:x.path,reason:x.reason}))},null,2));
