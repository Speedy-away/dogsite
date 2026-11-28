// Import the exact release's retained catalogue, not the PC feature list.
'use strict';
const fs=require('node:fs'),crypto=require('node:crypto');
const input=process.argv[2];
if(!input)throw Error('Usage: node tools/features/import-rdr2-ps4-catalog.cjs RETAINED_CATALOG.hpp');
const source=fs.readFileSync(input,'utf8');
const output='tools/features/features-rdr2-ps4.json';
const manifest=JSON.parse(fs.readFileSync(output,'utf8'));
const version=manifest.supported_versions?.join(' ').match(/v(\d+\.\d+\.\d+)/)?.[1];
if(!version)throw Error('Release version missing from manifest');
const release=version+' Beta';
const quoted=/"(?:\\.|[^"\\])*"/g;
const fields=line=>[...line.matchAll(quoted)].map(m=>JSON.parse(m[0]));
const pageBlock=source.split('inline constexpr Page pages[]{')[1].split('};')[0];
const pages=new Map(pageBlock.split('\n').filter(l=>l.trim().startsWith('{')).map(l=>{const p=fields(l);return[p[0],p[1]];}));
const featureBlock=source.split('inline constexpr Feature features[]{')[1].split('};')[0];
const names={player:'Self',network:'Network & recovery',weapon:'Weapons',vehicle:'Vehicles',teleport:'Teleport',world:'World',spawn:'Spawner',misc:'Miscellaneous',scripthook:'ScriptHook',settings:'Settings'};
const tabs=new Map();
let rows=0,excluded=0;
for(const line of featureBlock.split('\n')){
  if(!line.trim().startsWith('{'))continue;
  rows++;
  const [id,page,rawLabel,kind,target,description,menuPage]=fields(line);
  const label=rawLabel.split('##')[0].trim();
  // Separators, navigation links and unnamed dynamic rows are not controls.
  if(!label||['breakOption','submenuOption'].includes(kind)){excluded++;continue;}
  const presented=menuPage||page;
  const parts=presented.split('/'),root=parts[1]||'main';
  const tabName=names[root]||'Main menu & diagnostics';
  if(!tabs.has(tabName))tabs.set(tabName,new Map());
  const categories=tabs.get(tabName);
  const trail=parts.slice(1).map((part,i)=>pages.get(parts.slice(0,i+2).join('/'))||part.replaceAll('_',' ')).join(' → ')||'Main menu';
  if(!categories.has(trail))categories.set(trail,[]);
  const scope=(line.match(/Scope::(\w+)/)||[])[1]||'Local';
  categories.get(trail).push({id,label:page==='main/player'&&label==='Invincibility'?'Godmode':label,desc:description||'Source catalogue control; beta runtime availability remains unverified.',settings:[`Control: ${kind.replace(/Option$/,'')} · Scope: ${scope.replace(/([a-z])([A-Z])/g,'$1 $2')}`],source_page:page,source_kind:kind});
}
const overview=manifest.tabs.find(t=>t.name==='Overview & availability')||{name:'Overview & availability',categories:manifest.tabs.map(t=>({name:t.name,groups:t.categories.flatMap(c=>c.groups)}))};
manifest.tabs=[overview,...[...tabs].map(([name,categories])=>({name,categories:[...categories].map(([name,items])=>({name,groups:[{name,items}]}))}))];
manifest.source_catalog={sha256:crypto.createHash('sha256').update(source).digest('hex'),release,rows,excluded_navigation_separators_or_unnamed:excluded,individual_controls:rows-excluded};
manifest.website={features:{description:'Explore Scooby RDR2 PS4 v'+release+': self and outfits, weapons and aim, player/NPC ESP, teleport, vehicles, bodyguards, pets, world tools and recovery controls. Search the full menu catalogue.'},notice:'Controls from the v'+release+' release catalogue, grouped by menu page. Availability depends on the supported game, session and providers. Incoming protections, portraits and IP/geolocation are unavailable. Recovery request amounts are not guaranteed.'};
fs.writeFileSync(output,JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify(manifest.source_catalog));
