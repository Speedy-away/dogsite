/*
 * READ-ONLY extractor for the GTA 5 menu.
 *
 * Walks the submenu .cpp files for the Category / Group / *CommandItem tree and
 * joins commands to current source registrations, labels and access gates.
 * Writes a manifest; touches nothing in the source project.
 */
const fs = require('fs'), path = require('path');

const ROOT = process.env.GTA5_SOURCE || path.resolve(__dirname, '../../../Scooby-Op/GTA5/EE/GTA - Main Src');
const SRC = path.join(ROOT, 'src/game/frontend/submenus');
const OUT = path.join(__dirname, 'features-gta5.json');

const source = require('./gta5-source.cjs').readSource(ROOT);
const {labels} = source;
const {stripComments} = require('./gta5-source.cjs');
const label = id => (labels['command.' + id + '.label'] || '').trim();
const desc = id => (labels['command.' + id + '.description'] || '').trim();

// ---- collect .cpp files, skipping build output ------------------------------
function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (/^(build|out|\.git|third_party|_backup)/i.test(e.name)) continue;
      walk(p, out);
    } else if (/\.cpp$/i.test(e.name) && !/\.bak/i.test(e.name)) out.push(p);
  }
  return out;
}
const files = walk(SRC);

// ---- tab name from the top-level file/dir -----------------------------------
function tabOf(file) {
  const rel = path.relative(SRC, file).replace(/\\/g, '/');
  const top = rel.split('/')[0].replace(/\.cpp$/, '');
  return top;
}

const TAB_NAMES = {
  Self: 'Self', Vehicle: 'Vehicle', World: 'World', Network: 'Network',
  Players: 'Players', Recovery: 'Recovery', Teleport: 'Teleport',
  Settings: 'Settings', Night: 'Night Club', LuaContent: 'Lua',
  OtherMenus: 'Other Menus', Player: 'Players', misc: 'Misc',
};

// ---- parse ------------------------------------------------------------------
// Category("X") opens a category; Group("Y") opens a group; *CommandItem("id"_J)
// adds a command. Order in the file is the order in the menu.
const RE = /std::make_shared<(Category|Group)>\(\s*"((?:[^"\\]|\\.)*)"|std::make_shared<(\w*CommandItem|\w*Item)>\(\s*"((?:[^"\\]|\\.)*)"_J/g;

const tabs = new Map();
const seen = new Set();
let orphans = 0;

for (const file of files) {
  const text = stripComments(fs.readFileSync(file, 'utf8'));
  const tabKey = tabOf(file);
  const tabName = TAB_NAMES[tabKey] || tabKey;

  let cat = null, grp = null, m;
  RE.lastIndex = 0;
  while ((m = RE.exec(text))) {
    if (m[1] === 'Category') { cat = m[2]; grp = null; continue; }
    if (m[1] === 'Group')    { grp = m[2]; continue; }

    const id = m[4];
    const type = m[3];
    if (!id || seen.has(id)) continue;
    const lb = label(id);
    if (!lb) { orphans++; continue; }          // no user-facing label -> internal

    seen.add(id);
    if (!tabs.has(tabName)) tabs.set(tabName, new Map());
    const cats = tabs.get(tabName);
    const catName = cat || 'General';
    if (!cats.has(catName)) cats.set(catName, new Map());
    const grps = cats.get(catName);
    const grpName = grp || 'General';
    if (!grps.has(grpName)) grps.set(grpName, []);
    grps.get(grpName).push({ id, label: lb, desc: desc(id), type });
  }
}

// ---- pass 2: commands registered outside the submenu tree -------------------
// Aimbot presets, "all players" variants, heist loops and similar live under
// src/game/features/<area>/... . The directory tells us where they belong.
const FEATURES = path.resolve(SRC, '../../features');
const AREA_TAB = {
  self: 'Self', vehicle: 'Vehicle', world: 'World', network: 'Network',
  players: 'Players', recovery: 'Recovery', teleport: 'Teleport',
  settings: 'Settings', night: 'Night Club', weapons: 'Self', misc: 'Misc',
  spoofing: 'Network', protections: 'Network', lua: 'Lua',
};

const allLabelled = [...new Set(Object.keys(labels)
  .filter(k => k.startsWith('command.') && k.endsWith('.label'))
  .map(k => k.split('.')[1]))].filter(id => label(id));
const missing = new Set(allLabelled.filter(id => !seen.has(id)));

// Place remaining controls by their actual registration file. A mention in a
// comment, legacy menu, or unrelated feature must not decide its section.
for (const id of missing) {
  const file = source.locations.get(id);
  const relative = path.relative(path.join(ROOT, 'src'), file).replace(/\\/g, '/');
  const parts = relative.split('/').filter(part => !['game','features','frontend','submenus','core'].includes(part));
  const tabName = AREA_TAB[(parts[0] || '').toLowerCase()] || TAB_NAMES[parts[0]] || 'Misc';
  const catName = (parts.length > 2 ? parts[1] : path.basename(file).replace(/\.(cpp|hpp|inl)$/, ''))
    .replace(/([a-z])([A-Z])/g, '$1 $2');
  if (!tabs.has(tabName)) tabs.set(tabName, new Map());
  const categories = tabs.get(tabName);
  if (!categories.has(catName)) categories.set(catName, new Map());
  const groups = categories.get(catName);
  if (!groups.has('More')) groups.set('More', []);
  groups.get('More').push({id, label:label(id), desc:desc(id), type:'CommandItem'});
  seen.add(id);
}
missing.clear();
console.log('Unregistered menu references excluded:', source.unresolved.join(', '));
console.log('labelled commands :', allLabelled.length, '| unplaced:', missing.size);

// ---- shape + report ---------------------------------------------------------
const manifest = {
  game: 'GTA 5', slug: 'gta5',
  sourceDate: new Date().toLocaleDateString('en-CA', {timeZone:'Europe/London'}),
  tabs: [...tabs.entries()].map(([tab, cats]) => ({
    name: tab,
    categories: [...cats.entries()].map(([cat, grps]) => ({
      name: cat,
      groups: [...grps.entries()].map(([g, items]) => ({ name: g, items })),
    })),
  })),
};

for (const tab of manifest.tabs) for (const category of tab.categories) for (const group of category.groups) for (const item of group.items) {
  item.access = source.premium.has(item.id) ? 'premium' : 'free';
  const editions = source.editions.get(item.id);
  if (editions?.size === 1) item.edition = [...editions][0];
}

manifest.tabs = require('./gta5-hierarchy.cjs').organize(source, manifest.tabs.flatMap(t=>t.categories.flatMap(c=>c.groups.flatMap(g=>g.items))));

let total = 0, withDesc = 0, cats = 0, groups = 0;
for (const t of manifest.tabs) for (const c of t.categories) {
  cats++;
  for (const g of c.groups) {
    groups++;
    total += g.items.length;
    withDesc += g.items.filter(i => i.desc).length;
  }
}
manifest.stats = { features: total, withDescription: withDesc, tabs: manifest.tabs.length, categories: cats, groups };

console.log('files parsed      :', files.length);
console.log('tabs              :', manifest.tabs.length);
console.log('categories        :', cats);
console.log('groups            :', groups);
console.log('features          :', total);
console.log('with description  :', withDesc, '(' + Math.round(withDesc / total * 100) + '%)');
console.log('skipped (no label):', orphans);
console.log('');
// Keep the curated navigation order: Self, Weapons, Visuals, Vehicles, etc.
for (const t of manifest.tabs) {
  const n = t.categories.reduce((s, c) => s + c.groups.reduce((x, g) => x + g.items.length, 0), 0);
  console.log('  ' + String(n).padStart(5), t.name, '(' + t.categories.length + ' categories)');
}

fs.writeFileSync(OUT, JSON.stringify(manifest, null, 1), 'utf8');
console.log('\nwrote', OUT);
