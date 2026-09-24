#!/usr/bin/env node
/* Source -> manifest -> both Half-Life pages. No game execution or network access. */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const copy = require('./half-life-copy');
const SITE = path.resolve(__dirname, '../..');
const MANIFEST = 'tools/features/features-half-life-1.json';
const PRODUCT = 'products/half-life-1/index.html';
const FEATURES = 'features-list/half-life-1-features/index.html';
const SOURCES = {
  host:'source/ports/goldsrc/src/ui.cpp',
  combat:'source/ports/goldsrc/src/combat_ui.cpp',
  view:'source/ports/goldsrc/src/view_ui.cpp',
  campaign:'source/ports/goldsrc/src/campaign_ui.cpp',
  pages:'source/ports/games/halflife/assets/halflife_pages.lua',
  registry:'source/ports/shared/vendor/UI/src/core/feature_registry.cpp',
  application:'source/ports/shared/vendor/UI/src/ui/application.cpp'
};
const hash = text => crypto.createHash('sha256').update(text).digest('hex');
const esc = text => String(text).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
function between(text, start, end) {
  const a = text.indexOf(start), b = text.indexOf(end, a + start.length);
  if (a < 0 || b < 0) throw Error(`Source structure changed: ${start}. Review the extractor before syncing.`);
  return text.slice(a, b);
}
function group(id) {
  if (id.startsWith('hl.combat.')) return ['Combat', /trigger|delay/.test(id) ? 'Triggerbot' : 'Aimbot'];
  if (id.startsWith('hl.movement.') || /^hl\.campaign\.(noclip|super_run|jump)$/.test(id)) return ['Movement','Movement controls'];
  if (id === 'hl.campaign.cleanup') return ['Spawner','World spawns'];
  if (id.startsWith('hl.campaign.')) return ['Self & View','Player'];
  if (id.startsWith('hl.view.')) return ['Self & View','View'];
  if (id.startsWith('esp.')) return ['Visuals','Entity ESP'];
  if (/radar/.test(id)) return ['Visuals','Radar'];
  if (/chams|^hl\.(hidden|viewmodel|grade)$/.test(id)) return ['Visuals','Materials & world'];
  if (/^hl\.(friendly|hostile|players|weapons|items|projectiles|objectives)$/.test(id)) return ['Visuals','Entity filters'];
  return ['Interface & Lua','Menu controls'];
}
function extract(s) {
  const items = new Map();
  const add = (id, label, file, desc = '', settings = []) => {
    if (copy.excluded.includes(id)) return;
    if (items.has(id)) throw Error(`Duplicate feature ID: ${id}`);
    if (!label || /[()]/.test(label)) throw Error(`Unresolved label: ${id}`);
    const [tab, category] = group(id);
    items.set(id, {id, label:copy.labels[id] || label, desc:copy.descriptions[id] || desc, settings, tab, category, source:SOURCES[file]});
  };
  const defaults = between(s.registry,'FeatureRegistry::FeatureRegistry()','Feature *FeatureRegistry::find');
  for (const m of defaults.matchAll(/add\(\{\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"[^"]+"\s*,\s*"([^"]*)"/g)) add(m[1],m[2],'registry',m[3]);
  const host = between(s.host,'void registerFeatures()','void publish()');
  for (const m of host.matchAll(/(\w+RegisterFeatures)\(\*app\)/g)) {
    if (!['campaignRegisterFeatures','combatRegisterFeatures','viewRegisterFeatures'].includes(m[1])) throw Error(`New registry ${m[1]} needs extraction support before syncing.`);
  }
  for (const m of host.matchAll(/fs\.remove\("([^"]+)"\)/g)) items.delete(m[1]);
  for (const m of host.matchAll(/feature\(id\("([^"]+)"\),\s*("[^"]+"|product\(\)\.\w+)/g)) {
    const id = 'hl.'+m[1];
    const label = m[2].startsWith('"') ? m[2].slice(1,-1) : copy.labels[id];
    add(id,label,'host');
  }
  for (const m of host.matchAll(/simple_base::Feature\s+\w+\{\s*(?:id\("([^"]+)"\)|"([^"]+)")\s*,\s*"([^"]+)"\s*,\s*"[^"]+"\s*,\s*"([^"]*)"/g)) add(m[1]?'hl.'+m[1]:m[2],m[3],'host',m[4]);
  const tuple = /\{\s*"([\w.]+)"\s*,\s*"([^"]+)"(?:\s*,\s*(-?[\d.]+)f?\s*,\s*(-?[\d.]+)f?\s*,\s*(-?[\d.]+)f?)?/g;
  for (const [file,prefix,start,end] of [
    ['combat','hl.','void combatRegisterFeatures','void combatRegisterLua'],
    ['view','hl.view.','void viewRegisterFeatures','void viewRegisterLua'],
    ['campaign','hl.campaign.','void campaignRegisterFeatures','void campaignPublish']
  ]) {
    const block = between(s[file],start,end);
    const declarations = file === 'view' ? block.split('simple_base::Feature reset')[0] : block;
    for (const m of declarations.matchAll(tuple)) add(prefix+m[1],m[2],file,'',m[4] ? [`Range: ${Number(m[4])}–${Number(m[5])}; default: ${Number(m[3])}`] : []);
    // Actions with direct names are separate from the tuple registrations above.
    for (const m of block.matchAll(/Feature\s+\w+\{id\("([^"]+)"\),\s*"([^"]+)"/g)) add(prefix+m[1],m[2],file);
    for (const m of block.matchAll(/std::pair\{"([^"]+)",\s*CampaignAction::(\w+)\}/g)) {
      const names = {RefillHealth:'Refill health',RefillArmor:'Refill armor',Cleanup:'Remove temporary world spawns'};
      if (!names[m[2]]) throw Error(`New campaign action ${m[2]} needs a public label.`);
      add(prefix+m[1],names[m[2]],file);
    }
  }
  // Read actual visible modes, not capability names (e.g. hidden/unimplemented modes).
  const lua = s.combat.slice(s.combat.indexOf('void combatInstallPages'));
  for (const m of lua.matchAll(/combo\('([^']+)',\s*'([^']+)',\s*\{([^}]+)\}/g)) {
    const item = items.get('hl.'+m[2]);
    if (!item) throw Error(`UI setting missing from registry: ${m[2]}`);
    item.settings.push(`${m[1]}: ${[...m[3].matchAll(/'([^']+)'/g)].map(v=>v[1]).join(', ')}`);
  }
  for (const m of lua.matchAll(/ui\.combo\('([^']+)',host\.setting\(prefix\.\.'([^']+)'[^\n]+?\{([^}]+)\}/g)) {
    const item = items.get('hl.'+m[2]);
    if (!item) throw Error(`UI mode missing from registry: ${m[2]}`);
    item.settings.push(`${m[1]}: ${[...m[3].matchAll(/'([^']+)'/g)].map(v=>v[1]).join(', ')}`);
  }
  for (const m of lua.matchAll(/ui\.keybind\(prefix\.\.'([^']+)',\s*'([^']+)'/g)) items.get('hl.'+m[1])?.settings.push(`${m[2]}: keyboard or mouse; Hold, Toggle or Always`);
  for (const m of s.pages.matchAll(/ui\.combo\("([^"]+)",halflife\.setting\("([^"]+)"[^\n]+?\{([^}]+)\}/g)) {
    items.get(m[2])?.settings.push(`${m[1]}: ${[...m[3].matchAll(/"([^"]+)"/g)].map(v=>v[1]).join(', ')}`);
  }
  for (const m of s.pages.matchAll(/ui\.slider\("([^"]+)",halflife\.setting\("([^"]+)","distance"\),([\d.]+),([\d.]+)\)/g)) {
    items.get(m[2])?.settings.push(`${m[1]}: ${m[3]}–${m[4]}`);
  }
  // Validate public UI references. Fail closed when C++ registration syntax changes.
  for (const [code,prefix] of [[lua,'hl.'],[s.campaign.slice(s.campaign.indexOf('bool campaignPages')),'hl.campaign.']]) {
    for (const m of code.matchAll(/ui\.(?:feature|keybind)\((v?prefix)\.\.'([^']+)'/g)) {
      const id = (m[1]==='vprefix'?'hl.view.':prefix)+m[2];
      if (!items.has(id) && !copy.excluded.includes(id)) throw Error(`Unmapped public control: ${id}`);
    }
  }
  for (const m of s.pages.matchAll(/ui\.feature\("([^"]+)"/g)) {
    if (!items.has(m[1]) && !copy.excluded.includes(m[1])) throw Error(`Unmapped public control: ${m[1]}`);
  }
  for (const extra of copy.extra) {
    if (!s[extra.file].includes(extra.anchor)) throw Error(`Source contract changed for ${extra.id}. Review before syncing.`);
    if (items.has(extra.id)) throw Error(`Duplicate additional feature ${extra.id}`);
    const {file,anchor,...item} = extra;
    items.set(item.id,{...item,settings:[],source:SOURCES[file]});
  }
  const spawner = items.get('hl.campaign.spawn');
  for (const m of s.campaign.matchAll(/ui\.slider(?:_int)?\('([^']+)',(?:quantity|distance),(\d+),(\d+)\)/g)) spawner.settings.push(`${m[1]}: ${m[2]}–${m[3]}`);
  // Read campaign multiplier ranges from the visible slider definitions.
  for (const m of lua.matchAll(/slider\('([^']+)','(campaign\.[^']+)',([\d.]+),([\d.]+)\)/g)) items.get('hl.'+m[2])?.settings.push(`${m[1]}: ${m[3]}–${m[4]}`);
  if (!items.has('hl.combat.aim') || !items.has('esp.enabled') || items.size < 25) throw Error('Incomplete Half-Life source catalog. No files written.');
  return [...items.values()];
}
function makeManifest(s) {
  const items = extract(s);
  const tabs = copy.order.map(name=>({name,categories:[]}));
  for (const item of items) {
    const tab = tabs.find(t=>t.name===item.tab);
    let category = tab.categories.find(c=>c.name===item.category);
    if (!category) { category={name:item.category,groups:[{name:'Features',items:[]}]}; tab.categories.push(category); }
    const {tab:unusedTab,category:unusedCategory,...entry} = item;
    if (!entry.settings.length) delete entry.settings;
    if (!entry.desc) delete entry.desc;
    category.groups[0].items.push(entry);
  }
  const keywords = ['Scooby Menu','Half-Life 1 cheat','HL1 cheat','GoldSrc','Half-Life Blue Shift cheat','Half-Life Opposing Force cheat','Half-Life Source cheat','free Half-Life cheat',...new Set(items.map(i=>i.label))].join(', ');
  const available = new Set(items.map(item=>item.id));
  const description = 'Free Half-Life 1 cheat: '+copy.highlights.filter(h=>h.ids.every(id=>available.has(id))).map(h=>h.label).join(', ')+'. Explore screenshots and features.';
  return {
    game:'Half-Life 1',slug:'half-life-1',
    source:'Generated from the Half-Life / GoldSrc menu source. Source inventory is not a release or runtime verification claim.',
    provenance:Object.fromEntries(Object.entries(SOURCES).map(([key,file])=>[file,hash(s[key])])),
    website:{
      product:{title:'Free Half-Life 1 Cheat - Scooby',description,keywords},
      features:{title:'Half-Life 1 Features — Scooby',description:'Explore Half-Life 1 '+tabs.filter(t=>t.categories.length).map(t=>t.name).join(', ')+'. Search features, modes and settings.',keywords},
      notice:'Feature availability depends on your selected game, build and session. The menu enables controls supported by that setup.'
    },
    tabs:tabs.filter(t=>t.categories.length)
  };
}
function replaceOne(text,pattern,value,label) {
  const matches = [...text.matchAll(new RegExp(pattern.source,pattern.flags.includes('g')?pattern.flags:pattern.flags+'g'))];
  if (matches.length!==1) throw Error(`Expected one ${label}; found ${matches.length}. No files written.`);
  return text.replace(pattern,()=>value);
}
function updateProduct(html, manifest, applyMetadata) {
  const items = manifest.tabs.flatMap(t=>t.categories.flatMap(c=>c.groups.flatMap(g=>g.items)));
  const ids = new Set(items.map(i=>i.id));
  const icon = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><polyline points="20 6 9 17 4 12"></polyline></svg>';
  const highlights = copy.highlights.filter(h=>h.ids.every(id=>ids.has(id))).map(h=>`<li>${icon}<span>${esc(h.label)}</span></li>`).join('');
  html = replaceOne(html,/<ul class="features-list" aria-label="Half-Life feature highlights">[\s\S]*?<\/ul>/,`<ul class="features-list" aria-label="Half-Life feature highlights">${highlights}</ul>`,'feature highlights');
  html = replaceOne(html,/<p class="product-intro">[\s\S]*?<\/p>/,'<p class="product-intro">Return to Black Mesa with a setup that fits your play style. Tune aiming, movement, visuals and camera controls, create encounters with the spawner, and save it all in your own profiles.</p>','product intro');
  const sections = manifest.tabs.map(tab=>{
    const c = copy.sections.find(c=>c.name===tab.name);
    const controls = tab.categories.flatMap(c=>c.groups.flatMap(g=>g.items));
    return `<section><h3>${esc(c?.title||tab.name)}</h3><p>${esc(c?.requires.every(id=>ids.has(id))?c.desc:'Explore the available controls and customize your setup.')}</p><p class="hl-feature-summary">${controls.length} features &amp; settings</p></section>`;
  }).join('');
  // Own only this bounded content region; preserve navigation, screenshots and access buttons.
  const details = `<section class="description-section" id="product-details"><span class="source-kicker">${items.length} FEATURES &amp; SETTINGS</span><h2 class="section-title">See more. Tune every detail.</h2><div class="description-content"><p>Scooby for Half-Life 1 brings combat, visuals, movement, camera controls and campaign tools together in one customizable menu. Save your favorite settings, assign hotkeys and build your own pages with Lua.</p><p><strong>Half-Life collection:</strong> Half-Life 1, Half-Life: Blue Shift, Half-Life: Opposing Force and Half-Life: Source share this product page and guide. Feature availability follows the selected edition and build; Half-Life: Source uses a separate Source-engine version.</p><div class="product-feature-grid">${sections}</div></div></section>`;
  html = replaceOne(html,/<section class="description-section" id="product-details">[\s\S]*?(?=<\/main>)/,details,'product details');
  return applyMetadata(PRODUCT,html,manifest.website.product);
}
function run({sourceRoot, siteRoot=SITE, apply=false}) {
  const snapshot = Object.fromEntries(Object.entries(SOURCES).map(([key,file])=>[key,fs.readFileSync(path.join(sourceRoot,file),'utf8')]));
  const manifest = makeManifest(snapshot);
  const {render,pages} = require(path.join(siteRoot,'tools/features/build-features-page.js'));
  const {applyMetadata} = require(path.join(siteRoot,'tools/seo-metadata.js'));
  const original = Object.fromEntries([MANIFEST,PRODUCT,FEATURES].map(file=>[file,fs.readFileSync(path.join(siteRoot,file),'utf8')]));
  const page = pages.find(p=>p.slug==='half-life-1');
  const output = {
    [MANIFEST]:JSON.stringify(manifest,null,2)+'\n',
    [PRODUCT]:updateProduct(original[PRODUCT],manifest,applyMetadata),
    [FEATURES]:applyMetadata(FEATURES,render(page,manifest),manifest.website.features).replace(/></g,'>\n<')+'\n'
  };
  const changed = Object.keys(output).filter(file=>output[file]!==original[file]);
  const before = JSON.parse(original[MANIFEST]).tabs.flatMap(t=>t.categories.flatMap(c=>c.groups.flatMap(g=>g.items))).map(i=>i.id);
  const after = manifest.tabs.flatMap(t=>t.categories.flatMap(c=>c.groups.flatMap(g=>g.items))).map(i=>i.id);
  const result = {features:after.length,changed,added:after.filter(id=>!before.includes(id)),removed:before.filter(id=>!after.includes(id)),applied:apply};
  if (apply && changed.length) {
    for (const [key,file] of Object.entries(SOURCES)) if (fs.readFileSync(path.join(sourceRoot,file),'utf8')!==snapshot[key]) throw Error(`Source changed during sync: ${file}. Retry after the edit finishes.`);
    for (const file of Object.keys(original)) if (fs.readFileSync(path.join(siteRoot,file),'utf8')!==original[file]) throw Error(`Website changed during sync: ${file}. Retry after the edit finishes.`);
    const staged = changed.map(file=>({file,absolute:path.join(siteRoot,file),temp:path.join(siteRoot,file)+`.sync-${process.pid}.tmp`}));
    const written = [];
    try {
      for (const entry of staged) fs.writeFileSync(entry.temp,output[entry.file],{flag:'wx'});
      for (const entry of staged) { fs.renameSync(entry.temp,entry.absolute); written.push(entry); }
    } catch (error) {
      for (const entry of written.reverse()) if (fs.readFileSync(entry.absolute,'utf8')===output[entry.file]) fs.writeFileSync(entry.absolute,original[entry.file]);
      throw error;
    } finally {
      for (const entry of staged) if (fs.existsSync(entry.temp)) fs.unlinkSync(entry.temp);
    }
  }
  return result;
}
if (require.main===module) {
  try {
    const args=process.argv.slice(2), index=args.indexOf('--source');
    if (index>=0 && (!args[index+1] || args[index+1].startsWith('--'))) throw Error('--source requires a repository path');
    const sourceRoot=path.resolve(index>=0?args[index+1]:process.env.SCOOBY_SOURCE_ROOT||path.join(SITE,'../Scooby-Op'));
    const result=run({sourceRoot,apply:args.includes('--apply')});
    console.log(JSON.stringify(result,null,2));
    if (args.includes('--check')&&result.changed.length) process.exitCode=1;
  } catch (error) { console.error(error.message); process.exitCode=1; }
}
module.exports={SOURCES,extract,makeManifest,updateProduct,run};
