/*
 * READ-ONLY extractor for the GTA 5 menu.
 *
 * Walks the submenu .cpp files for the Category / Group / *CommandItem tree and
 * joins each command id to its label + description from base_english.json.
 * Writes a manifest; touches nothing in the source project.
 */
const fs = require('fs'), path = require('path');

const SRC = 'C:/Users/whatw/OneDrive/Documents/GitHub/Scooby-Op/GTA5/EE/GTA - Main Src/src/game/frontend/submenus';
const LABELS = 'C:/scooby/GTA5/Labels/base_english.json';
const OUT = path.join(__dirname, 'features-gta5.json');

const labels = JSON.parse(fs.readFileSync(LABELS, 'utf8'));
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
  const text = fs.readFileSync(file, 'utf8');
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

if (fs.existsSync(FEATURES)) {
  for (const file of walk(FEATURES)) {
    if (!missing.size) break;
    const text = fs.readFileSync(file, 'utf8');
    const rel = path.relative(FEATURES, file).replace(/\\/g, '/');
    const parts = rel.split('/');
    const area = parts[0].toLowerCase();
    const tabName = AREA_TAB[area] || TAB_NAMES[parts[0]] || 'Misc';
    // second path segment makes a decent category, else the file name
    const catName = (parts.length > 2 ? parts[1] : path.basename(file, '.cpp'))
      .replace(/([a-z])([A-Z])/g, '$1 $2');

    for (const m2 of text.matchAll(/"([A-Za-z0-9_]{3,})"/g)) {
      const id = m2[1];
      if (!missing.has(id)) continue;
      missing.delete(id);
      seen.add(id);
      if (!tabs.has(tabName)) tabs.set(tabName, new Map());
      const cats2 = tabs.get(tabName);
      if (!cats2.has(catName)) cats2.set(catName, new Map());
      const grps2 = cats2.get(catName);
      const gName = 'More';
      if (!grps2.has(gName)) grps2.set(gName, []);
      grps2.get(gName).push({ id, label: label(id), desc: desc(id), type: 'CommandItem' });
    }
  }
}
// ---- pass 3: anything left, anywhere in src ---------------------------------
if (missing.size) {
  const ALLSRC = path.resolve(SRC, '../../..');            // src/
  for (const file of walk(ALLSRC)) {
    if (!missing.size) break;
    const text = fs.readFileSync(file, 'utf8');
    const rel = path.relative(ALLSRC, file).replace(/\\/g, '/');
    const seg = rel.split('/').filter(s => !/^(game|frontend|features|core)$/.test(s));
    const tabName = AREA_TAB[(seg[0] || '').toLowerCase()] || 'Misc';
    const catName = (seg.length > 1 ? seg[seg.length - 2] : path.basename(file, '.cpp'))
      .replace(/([a-z])([A-Z])/g, '$1 $2');
    for (const m3 of text.matchAll(/"([A-Za-z0-9_]{3,})"/g)) {
      const id = m3[1];
      if (!missing.has(id)) continue;
      missing.delete(id); seen.add(id);
      if (!tabs.has(tabName)) tabs.set(tabName, new Map());
      const c3 = tabs.get(tabName);
      if (!c3.has(catName)) c3.set(catName, new Map());
      const g3 = c3.get(catName);
      if (!g3.has('More')) g3.set('More', []);
      g3.get('More').push({ id, label: label(id), desc: desc(id), type: 'CommandItem' });
    }
  }
}
// Anything still unplaced is referenced only from headers or generated code.
// It is still a real, labelled, described feature - keep it rather than drop it.
if (missing.size) {
  if (!tabs.has('Misc')) tabs.set('Misc', new Map());
  const c4 = tabs.get('Misc');
  if (!c4.has('Additional')) c4.set('Additional', new Map());
  const g4 = c4.get('Additional');
  if (!g4.has('More')) g4.set('More', []);
  for (const id of missing) {
    g4.get('More').push({ id, label: label(id), desc: desc(id), type: 'CommandItem' });
    seen.add(id);
  }
  missing.clear();
}
console.log('labelled commands :', allLabelled.length, '| unplaced:', missing.size);

// ---- shape + report ---------------------------------------------------------
const manifest = {
  game: 'GTA 5', slug: 'gta5',
  tabs: [...tabs.entries()].map(([tab, cats]) => ({
    name: tab,
    categories: [...cats.entries()].map(([cat, grps]) => ({
      name: cat,
      groups: [...grps.entries()].map(([g, items]) => ({ name: g, items })),
    })),
  })),
};

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
manifest.tabs.sort((a, b) => {
  const n = x => x.categories.reduce((s, c) => s + c.groups.reduce((t, g) => t + g.items.length, 0), 0);
  return n(b) - n(a);
});
for (const t of manifest.tabs) {
  const n = t.categories.reduce((s, c) => s + c.groups.reduce((x, g) => x + g.items.length, 0), 0);
  console.log('  ' + String(n).padStart(5), t.name, '(' + t.categories.length + ' categories)');
}

fs.writeFileSync(OUT, JSON.stringify(manifest, null, 1), 'utf8');
console.log('\nwrote', OUT);
