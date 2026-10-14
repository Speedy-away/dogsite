/* Recover menu ownership from AddItem links, rather than the last nearby heading. */
const path=require('node:path');
const clean=s=>s.replace(/([a-z0-9])([A-Z])/g,'$1 $2').replace(/[_-]+/g,' ').replace(/\s+/g,' ').trim();
const generic=s=>/^(Main|General|More|Features|Controls)$/i.test(s);
function expression(text,start){let depth=1,quote=false,escape=false;for(let i=start;i<text.length;i++){const c=text[i];if(quote){if(escape)escape=false;else if(c==='\\')escape=true;else if(c==='"')quote=false;continue;}if(c==='"'){quote=true;continue;}if(c==='(')depth++;if(c===')'&&!--depth)return text.slice(start,i);}return '';}
function menuPaths(menus){const placements=new Map();for(const {file,text}of menus){const nodes=[];
 for(const m of text.matchAll(/\b(\w+)\s*=\s*std::make_shared<(Category|TabItem|TabBarItem|Group)>\(\s*"([^"\n]+)"/g))nodes.push({variable:m[1],type:m[2],name:m[3],index:m.index,parent:null,ids:[]});
 const at=(name,index)=>nodes.filter(n=>n.variable===name&&n.index<index).at(-1);
 for(const m of text.matchAll(/\b(\w+)->Add(?:Item|Tab|Group)\(/g)){const owner=at(m[1],m.index);if(!owner)continue;const arg=expression(text,m.index+m[0].length);
  for(const id of arg.matchAll(/"(\w+)"_J/g))owner.ids.push(id[1]);
  if(!arg.includes('make_shared')){for(const token of arg.replace(/(?:\w+::)+(?:move|Only|Free|Paid)/g,'').matchAll(/\b\w+\b/g)){const child=at(token[0],m.index);if(child&&child!==owner){child.parent=owner;break;}}}
 }
 for(const node of nodes){const ancestry=[],seen=new Set();let current=node;while(current&&!seen.has(current)){seen.add(current);if(current.type!=='TabBarItem')ancestry.unshift(current.name);current=current.parent;}
  for(const id of node.ids){const candidate={file,path:ancestry};const prior=placements.get(id);if(!prior||candidate.path.length>prior.path.length)placements.set(id,candidate);}
 }
}return placements;}
const ORDER=['Self','Weapons','Visuals','Vehicles','Teleport','Players','Network','Protections','World','Recovery','Silent Night','Minigames','Media & Browser','Settings','Developer Tools','Other Menus'];
function sectionFor(file,menuPath=[]){const f=file.replace(/\\/g,'/').toLowerCase();
 if(/\/esp\//.test(f)||/\/self\/(hitmarkers|projectiletrails)\./.test(f)||menuPath.some(n=>/^(ESP|Visuals|Crosshair)$/.test(n)))return 'Visuals';
 if(/\/self\/(weapons?|aimbot|triggerbot|pvp)/.test(f))return 'Weapons';
 if(/\/protections?\//.test(f))return 'Protections';
 if(/\/night(?:\/|\.)/.test(f))return 'Silent Night';
 if(/\/minigames?\//.test(f))return 'Minigames';
 if(/\/devtools\//.test(f))return 'Developer Tools';
 if(/(mediaplayer|gamebrowser|browserprotocol)/.test(f))return 'Media & Browser';
 if(/\/frontend\/(manager|styles)\//.test(f)||/\/core\//.test(f))return 'Settings';
 for(const [re,name]of [[/\/self(?:\/|\.)/,'Self'],[/\/vehicle(?:\/|\.)/,'Vehicles'],[/\/teleport(?:\/|\.)/,'Teleport'],[/\/players?(?:\/|\.)/,'Players'],[/\/(network|session)(?:\/|\.)/,'Network'],[/\/world(?:\/|\.)/,'World'],[/\/recovery(?:\/|\.)/,'Recovery'],[/\/(settings|system)(?:\/|\.)/,'Settings'],[/\/othermenus\//,'Other Menus']])if(re.test(f))return name;
 return 'Settings';}

const RULES={
 Self:[['Health & Survival','health|heal|armor|adrenaline|invinc|god|parachute'],['Movement','movement|jump|run|sprint|jetpack|rewind'],['Appearance & Outfits','outfit|face|model|visibility|invisib|huge|tiny|size|clown|accessories'],['Animations','animation|playback'],['Powers','power|force|telekinesis|thrower|magnet|burn'],['Camera & HUD','camera|vision|hud|lsd'],['Wanted & Abilities','wanted|special ability']],
 Weapons:[['Aiming & Combat','aim|pvp|target|magic bullet|one hit'],['Ammo & Firing','ammo|clip|reload|rapid|shotgun|recoil|spread|tracer|explosive head'],['Loadout & Inventory','library|locker|give.*weapon|weapon on back|wheel|preview'],['Weapon Modifiers','modifier|melee|laser'],['Custom Weapons','custom|projectile|support gun|teleport gun']],
 Vehicles:[['Spawning & Saved Vehicles','spawn|new vehicle|saved|preset|personal|last vehicle'],['Appearance & Lighting','appearance|light|signal|skid|tire|fitment|suspension'],['Driving & Handling','driv|drift|dynamic|boost|speed|pilot|movement|horn'],['Flight & Tricks','fly|flight|trick|parachute'],['Combat & Abilities','weapon|combat|countermeasure|special abil'],['Health & Maintenance','health|repair']],
 Players:[['Friendly Actions','friendly|heal|armor|revive|parachute|clear wanted|give'],['Vehicle Actions','vehicle|tires|engine'],['Removal & Session Tools','kick|session|player list|spectate|saved player'],['Teleport','teleport|send to|sky dive'],['All Players',' all$|all players'],['Trolling','troll|kill|blame|spawn|loop|freeze|fire|nuke|ragdoll|launch|swarm|drunk|anvil']],
 Network:[['Session & Matchmaking','session|join|bail|matchmaking|crew'],['Advertising','magnet'],['Spoofing','spoof'],['Services','service']],
 Protections:[['Detection & Evidence','detect|evidence|overview'],['Entity Protection','entit|spawn'],['Event Protection','event|crash|backup'],['Session Defense','session|spam|troll|reaction|runtime|advanced']],
 World:[['Weather & Time','weather|time|cloud|fog|sun|moon|star|sky|thunder|lightning|snow'],['Water & Ocean','water|ocean|liquid|puddle'],['Visual Effects','vfx|visual|light|smoke|fire|footstep|glow|surface'],['Population & Police','ped|cop|dispatch|prostitute'],['Traffic & Vehicles','traffic|vehicle|plane'],['Randomizer','random|rainbomizer|replacement|model selection'],['Spawning & Objects','spawn|ramp|object|ipl|pickups'],['Physics & Events','gravity|earthquake|tornado|bounc|speed|slow motion|explosion|bullet|world event|jump|sentry'],['Missions & Story','mission|story'],['World Controls','world|clear area|camera|game settings|profile|presets']],
 Recovery:[['Heists','heist|cayo|diamond|doomsday|apartment|fib files'],['Businesses','business|bunker|nightclub|organization|payout|buyers|sales|safe|vehicle money'],['Casino','casino|slot|blackjack|roulette|poker|inside track|lucky wheel'],['Unlocks & Collectibles','unlock|collect|career|festive|arena|drug wars|mercenaries|chop shop|car meet'],['Money & Stats','money|earning|refund|character|recovery loop'],['Missions & Activities','mission|daily|stash|yacht|phone|biz teroids|skip|automation']],
 'Silent Night':[['Heists','heist|apartment|cayo|diamond|doomsday|auto shop|salvage|flash ops'],['Businesses','agency|bunker|hangar|nightclub|cargo|money fronts'],['Money & Unlocks','money|casino|unlock|boss'],['Developer Tools','dev|editor|stats'],['Settings','setting|preference|display|extras|session|misc|generic']],
 Minigames:[['Arcade Games','arcade|asteroid|brick|doom|pong|invader|browser'],['Driving Challenges','taxi|derby|drag|drift|racer|stunt|vehicle|chase'],['Combat & Survival','battle|bounty|fight|gang|head hunter|horde|rampage|sniper|survival|zombie|assassination'],['Challenges','escape|freefall|potato|hill|obstacle']],
 Settings:[['Interface & Overlays','ui|overlay|sidebar|scoreboard|info|headshot|quality|map|monitor|census'],['Commands & Chat','command|console|chat'],['Lua','lua'],['Preferences','setting|preference']],
 Teleport:[['Quick Teleports','blink|forward|up|aim|mark'],['Vehicles & Players','vehicle|player|bring'],['Locations & Navigation','gps|coord|interior|property|control']],
 'Other Menus':[['Imports','cherax']],
};
function bucket(section,name){return RULES[section]?.find(([,pattern])=>new RegExp(pattern,'i').test(name))?.[0]||({Self:'Utilities',Weapons:'Weapon Tools',Vehicles:'Vehicle Tools',Players:'Player Tools',Network:'Network Tools',Protections:'Protection Settings',World:'World Controls',Recovery:'Recovery Tools','Silent Night':'Settings',Minigames:'Challenges',Settings:'Utilities'}[section])||name;}

function organize(source,items){const placements=menuPaths(source.menus),tabs=new Map();
 for(const item of items){const location=source.locations.get(item.id),placement=placements.get(item.id);let section=sectionFor(location,placement?.path);
 const hint=clean(path.basename(location).replace(/\.(cpp|hpp|inl)$/,''));
 if(placement&&/\/Self\/Weapons\//i.test(placement.file.replace(/\\/g,'/')))section=sectionFor(placement.file,placement.path);
 if(section==='Self'&&/ammo|weapon|gun|recoil|spread|aim|tracer|melee|magic bullet|reload|targeting alert/i.test(hint))section='Weapons';
 if(section==='Self'&&/teleport/i.test(hint))section='Teleport';
 if(section==='Network'&&/All$/.test(hint)&&! /bail/i.test(hint))section='Players';
 if(section==='Settings'&&/bodyguard|ped swarm|windmill|flipper/i.test(hint))section='World';
 if(section==='Settings'&&/vehicle|customs|despawn/i.test(hint))section='Vehicles';
 if(section==='Settings'&&/saved players/i.test(hint))section='Players';
 if(section==='Settings'&&/matchmaking|physical index/i.test(hint))section='Network';
 if(section==='Settings'&&/body accessories/i.test(hint))section='Self';const origin=placement&&sectionFor(placement.file,placement.path)===section?placement:null;
 let parts=origin?.path.filter(n=>!generic(n)&&n.toLowerCase()!==section.toLowerCase())||[];
 const filename=clean(path.basename(location).replace(/\.(cpp|hpp|inl)$/,''));
 // Main tabs use descriptive groups as categories; nested tabs retain their path.
 let category=parts[0]||filename,group=parts.slice(1).join(' / ')||filename;
 if(section==='Silent Night'&&!origin){const rel=location.replace(/\\/g,'/').split('/night/')[1]||'';const p=rel.split('/').filter(s=>s!=='Features');category=clean(p[0]||filename);group=filename;}
 if(section==='Visuals'&&/\/ESP\//i.test(location)){category=filename==='Registry'?'Display & Filters':filename;group=parts.at(-1)||'Display Settings';}
 if(section==='Weapons'&&category==='Weapons')category=parts[1]||filename;
 if(section==='World'&&/^(World Misc|VFX)$/.test(filename)&&!origin){category=bucket(section,item.label+' '+item.id);group=filename==='VFX'?'Environment Settings':'World Actions';}
 if(section==='Visuals'){
  const text=item.label+' '+item.id;
  if(/Registry/.test(filename))category='Display & Filters';
  const rules=[['Health & Armour','health|armour|armor|hptext'],['Names & Distance','name|distance'],['Boxes & Fill','box|fill|rounding'],['Skeleton & Bones','skeleton|bone|joint'],['Colors & Effects','color|rainbow|glow|gradient|ptfx|particle'],['Position & Size','position|alignment|offset|scale|size|rotation|pitch|yaw'],['Trails & Projectiles','trail|bullet|projectile|throwable'],['Sound & Feedback','sound|damage|hitmarker']];
  group=rules.find(([,r])=>new RegExp(r,'i').test(text))?.[0]||'Display Controls';
 }
 if(section==='Protections'&&/backup/i.test(group))group='Event Filters';
 if(section==='Media & Browser'){
  const text=item.label+' '+item.id;
  group=[['Spotify','spotify'],['Radio','radio'],['Overlay & Appearance','overlay|color|size|position|opacity|artwork|theme|scale|width|height'],['Library & Playlists','library|playlist|folder|track|search']].find(([,pattern])=>new RegExp(pattern,'i').test(text))?.[0]||'Playback & Audio';
 }
 if(section==='Weapons'&&filename==='Weapon On Back')group=item.label.match(/Slot (\d+)/)?.[0]||(/global|pitch|roll|yaw|scale|spacing|layout/i.test(item.label)?'Layout & Position':'Loadout Settings');
 const oldCategory=category;
 category=bucket(section,category);
 group=[oldCategory.replace(/protections backup/i,'Event Filters'),group].filter((name,index,all)=>name!==category&&name!=='Options'&&all.indexOf(name)===index).join(' / ')||'Overview';
 item.sourcePath=location.replace(/\\/g,'/').split('/src/')[1];
 if(!tabs.has(section))tabs.set(section,new Map());const cats=tabs.get(section);if(!cats.has(category))cats.set(category,new Map());const groups=cats.get(category);if(!groups.has(group))groups.set(group,[]);groups.get(group).push(item);
 }
 return ORDER.filter(n=>tabs.has(n)).map(name=>({name,categories:[...tabs.get(name)].map(([name,groups])=>({name,groups:[...groups].map(([name,items])=>({name,items}))})).sort((a,b)=>a.name.localeCompare(b.name))}));
}
module.exports={menuPaths,organize,sectionFor,expression};
