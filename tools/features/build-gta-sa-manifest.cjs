const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'../..');
const source=path.resolve(root,'../Scooby-Op/old-rockstar-games/gta/SA');
const manifest={game:'San Andreas',slug:'gta-sa',source:'Reviewed SA feature controls, 2026-10-10. Source inventory is not a claim of live gameplay acceptance.',provenance:{},tabs:[]};
const specs=[['Combat','Lock-on aim','src/features/combat/lock_on/lock_on.cpp'],['Combat','Silent aim','src/features/combat/silent_aim/silent_aim.cpp'],['Combat','Triggerbot','src/features/combat/triggerbot/triggerbot.cpp'],['Local','Self','src/features/local/self/self.cpp'],['Local','Weapon','src/features/local/weapon/weapon.cpp'],['Local','Vehicle','src/features/local/vehicle/vehicle.cpp'],['Local','World and camera','src/features/local/world/world.cpp'],['Local','Teleport','src/features/local/teleport/teleport.cpp']];
function category(tab,name){let t=manifest.tabs.find(t=>t.name===tab);if(!t){t={name:tab,categories:[]};manifest.tabs.push(t)};const c={name,groups:[{name:'Controls',items:[]}]};t.categories.push(c);return c.groups[0].items}
for(const [tab,name,file] of specs){const raw=fs.readFileSync(path.join(source,file));manifest.provenance[file]=crypto.createHash('sha256').update(raw).digest('hex');const text=raw.toString();const items=category(tab,name);for(const m of text.matchAll(/(?:settings|x)\.(toggle|number|action)\(\s*"([^"]+)"\s*,\s*"([^"]+)"([^;]*)/g)){if(['aim.enabled','input.block'].includes(m[2]))continue;items.push({id:m[2],label:m[3],desc:tab==='Combat'?'Configure '+m[3].toLowerCase()+' for '+name.toLowerCase()+'. Requires a supported single-player session; live gameplay acceptance is pending.':'Configure '+m[3].toLowerCase()+'. Availability depends on the supported game build and current session.',settings:m[1]==='number'?['Adjustable value']:m[1]==='action'?['Action']:['On / off'],source:file})}}
manifest.tabs.find(t=>t.name==='Combat').categories[0].groups[0].items.unshift({id:'aim.enabled',label:'Enable aimbot',desc:'Enable lock-on aiming with the configured key and activation mode. Starts disabled; live gameplay acceptance is pending.',settings:['Aim key','Hold / Toggle / Always'],source:'src/features/combat/lock_on/lock_on.cpp'});
const teleport=manifest.tabs.find(t=>t.name==='Local').categories.find(c=>c.name==='Teleport').groups[0].items;
for(const [id,label,desc] of [['waypoint','Teleport to waypoint','Use the menu waypoint first, otherwise the game radar waypoint. Requires the exterior world and a successful ground query.'],['coordinates','Teleport to coordinates','Use X, Y and Z coordinates with optional ground snapping. Invalid or unloaded destinations are rejected.'],['back','Back','Return to the previous teleport position in this session.'],['save','Save current position','Remember your current position for the current session.'],['saved','Teleport to saved position','Return to a saved session position.'],['copy','Copy current coordinates','Fill the coordinate controls with your current position.'],['set_waypoint','Set menu waypoint','Choose a menu waypoint; you can also right-click the world map.']])teleport.push({id:'teleport.'+id,label,desc:desc+' On-foot in the current beta. Occupied-vehicle teleport is planned for the next update; in-game verification pending.',source:specs.at(-1)[2]});
const self=manifest.tabs.find(t=>t.name==='Local').categories.find(c=>c.name==='Self').groups[0].items;self.unshift({id:'self.heal',label:'Heal',desc:'Request a health refill through the supported game update. Session and player-lifetime checks apply; live gameplay acceptance pending.',settings:['Heal key'],source:'src/features/local/self/self.cpp'});
for(const group of ['Players','NPCs','Vehicles','Self']){const items=category('Visuals',group+' ESP');for(const [id,label] of [['enabled','Enable ESP'],['box','Box'],['name','Name'],['distance','Distance'],['health','Health bar'],['health_text','Health text'],['snaplines','Snaplines'],...(group!=='Vehicles'?[['skeleton','Skeleton']]:[]),...(['Players','NPCs'].includes(group)?[['weapon','Weapon name']]:[])])items.push({id:'esp.'+group.toLowerCase()+'.'+id,label,desc:`${label} control for the ${group.toLowerCase()} ESP profile. Uses the current game scene; live alignment acceptance is pending.`,source:'src/features/visuals/visuals.cpp'});}
category('Visuals','Radar').push({id:'overlay.radar',label:'Radar',desc:'Show entities from the current game scene in the radar overlay.',source:'src/features/visuals/visuals.cpp'});
category('Interface & scripts','Personal settings').push(...[['input.block','Block game input','Block game controls while the focused menu is open; close the menu to resume control.'],['profiles','Configs & keybinds','Keep your SA profiles and keybinds in the separate SA settings directory.'],['lua','Lua scripting','Use SA feature, UI and event APIs plus the shared typed game API. Capability reporting determines which requests are available.']].map(([id,label,desc])=>({id,label,desc,source:'README.md'})));
category('Visuals','Pickup ESP').push(...['enabled','box','name','distance','snaplines'].map(id=>({id:'esp.pickups.'+id,label:id==='enabled'?'Enable pickup ESP':id[0].toUpperCase()+id.slice(1),desc:'Display active streamed pickups with verified object and pickup lifetime checks. Live gameplay acceptance pending.',source:'src/game/adapter.cpp'})));
category('Spawner','Vehicles, weapons and pedestrians').push(...[
 ['spawner.spawn','Vehicle spawner','Search the 212-model catalogue by name, model or ID and choose a class. Ordinary vehicle spawning is implemented; trains and trailers require a dedicated spawner.'],
 ['spawner.weapon.spawn','Weapon spawner','Search 43 weapon/equipment models, set ammo and choose whether to equip.'],
 ['spawner.ped.spawn','Pedestrian spawner','Search 276 pedestrian models; choose count and distance.'],
 ['spawner.settings','Vehicle settings','Spawn inside when on foot, engine state, protection, retained speed, aircraft altitude and replace-last preferences.'],
 ['spawner.delete_all','Delete spawned entities','Delete tracked spawned entities; occupied vehicles are skipped.']
].map(([id,label,desc])=>({id,label,desc:desc+' Live gameplay acceptance pending.',source:'src/features/local/native_features.cpp'})));
category('Spawner','Spawn settings').push(...[
 ['spawner.inside','Spawn inside','Enter a newly spawned vehicle when currently on foot.'],
 ['spawner.god','Protect spawned vehicle','Apply vehicle protection to the newly spawned vehicle.'],
 ['spawner.engine','Engine on','Choose the engine state of the spawned vehicle.'],
 ['spawner.speed','Keep vehicle speed','Carry the validated current vehicle speed into the new vehicle.'],
 ['spawner.air','Aircraft spawn in air','Spawn planes and helicopters above the player.'],
 ['spawner.replace','Delete last before spawn','Replace the last tracked unoccupied spawned vehicle.'],
 ['spawner.info','Show vehicle info','Show the selected model ID and vehicle class.'],
 ['spawner.delete_last','Delete last spawned entity','Remove the last tracked eligible entity; occupied vehicles are skipped.'],
 ['spawner.weapon.ammo','Weapon ammo','Choose the ammunition amount when giving a weapon.'],
 ['spawner.weapon.equip','Equip weapon','Choose whether to equip the given weapon.'],
 ['spawner.ped.count','Pedestrian count','Choose the number of pedestrians to spawn within the bounded limit.'],
 ['spawner.ped.distance','Pedestrian distance','Choose how far ahead to spawn pedestrians.']
].map(([id,label,desc])=>({id,label,desc,source:'src/features/spawner/spawner.cpp'})));
category('Local','Weather selection').push({id:'world.weather_type',label:'Weather type',desc:'Choose from 21 weather presets for the weather override.',source:'src/features/local/world/world.cpp'});
category('Not available','Current limits').push(...[
 ['spectators','Multiplayer spectator list','Single-player SA does not provide remote spectators. Actual camera telemetry is available in World.'],
 ['special-spawners','Train and trailer spawners','Dedicated train/trailer native spawning is not implemented.'],
 ['tuning','Spawn maxed / vehicle tuning','Per-model upgrades are not implemented.'],
 ['vehicle-preview','3D vehicle preview','The catalogue provides vehicle metadata; a 3D vehicle preview is not implemented.'],
 ['no-reload','No reload','Ammo refill and maintained ammo are implemented; magazine/no-reload manipulation is not.']
].map(([id,label,desc])=>({id:'unavailable.'+id,label,desc,source:'docs/FEATURE_STATUS.md'})));
const upcoming = id => /^(weapon\.|vehicle\.|world\.|spawner\.|esp\.pickups\.)/.test(id);
for(const tab of manifest.tabs) for(const section of tab.categories) for(const group of section.groups) for(const item of group.items) {
 if(upcoming(item.id)) {item.availability='next-update';item.desc='Next update — not in the current download. '+item.desc;}
}
manifest.website={notice:'Current download: free beta.4. Items marked Next update are implemented in development, but are not included in this download. In-game verification and a new release are pending.',features:{description:'Browse current and upcoming San Andreas features: ESP, teleport, spawners, weapons, vehicles, weather, time, free camera and Lua. Search controls and check availability.'}};
for(const file of ['README.md','docs/FEATURE_STATUS.md','src/features/visuals/visuals.cpp','src/features/local/native_features.cpp','src/features/spawner/spawner.cpp'])manifest.provenance[file]=crypto.createHash('sha256').update(fs.readFileSync(path.join(source,file))).digest('hex');
fs.writeFileSync(path.join(root,'tools/features/features-gta-sa.json'),JSON.stringify(manifest,null,2)+'\n');
