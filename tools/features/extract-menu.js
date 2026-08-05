/*
 * READ-ONLY extractor for the Scooby menus that use the Category/Group/Command
 * architecture (GTA 5, RDR2). Never writes to the source projects.
 *
 *   node extract-menu.js rdr2
 *
 * Labels come from an inline `static XCommand _N{"id", "Label", "Description"}`
 * declaration, or from a labels JSON when the project ships one.
 */
const fs = require('fs'), path = require('path');

const GAMES = {
  gta5: {
    name: 'GTA 5', slug: 'gta5',
    root: 'C:/Users/whatw/OneDrive/Documents/GitHub/Scooby-Op/GTA5/EE/GTA - Main Src/src',
    labels: 'C:/scooby/GTA5/Labels/base_english.json',
  },
  rdr2: {
    name: 'RDR2', slug: 'rdr2',
    root: 'C:/Users/whatw/OneDrive/Documents/GitHub/Scooby-Op/RDR2/Scooby-RDR2-working/src',
    labels: null,
  },
};

const key = process.argv[2];
const G = GAMES[key];
if (!G) { console.error('usage: node extract-menu.js <' + Object.keys(GAMES).join('|') + '>'); process.exit(1); }

const SUBMENUS = path.join(G.root, 'game/frontend/submenus');
const FEATURES = path.join(G.root, 'game/features');

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (/^(build|out|\.git|third_party|vendor|deps|_backup|_codex)/i.test(e.name)) continue;
      walk(p, out);
    } else if (/\.(cpp|hpp)$/i.test(e.name) && !/\.bak/i.test(e.name)) out.push(p);
  }
  return out;
}

// ---- label map ---------------------------------------------------------------
const labels = new Map();   // id -> {label, desc}

if (G.labels && fs.existsSync(G.labels)) {
  const j = JSON.parse(fs.readFileSync(G.labels, 'utf8'));
  for (const k of Object.keys(j)) {
    const m = /^command\.(.+)\.label$/.exec(k);
    if (!m) continue;
    const lb = (j[k] || '').trim();
    if (lb) labels.set(m[1], { label: lb, desc: (j['command.' + m[1] + '.description'] || '').trim() });
  }
}

// inline: static <Type> _Name{"id", "Label", "Description"
const INLINE = /static\s+\w+\s+\w+\s*\{\s*"([A-Za-z0-9_]+)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"/g;
const allFiles = walk(G.root);
for (const f of allFiles) {
  const t = fs.readFileSync(f, 'utf8');
  for (const m of t.matchAll(INLINE)) {
    const [, id, lb, ds] = m;
    if (!labels.has(id) && lb.trim()) labels.set(id, { label: lb.trim(), desc: ds.trim() });
  }
}
console.log('labelled commands :', labels.size);

// ---- hierarchy ---------------------------------------------------------------
const TAB = {
  Self: 'Self', Vehicle: 'Vehicle', World: 'World', Network: 'Network',
  Players: 'Players', Player: 'Players', Recovery: 'Recovery', Teleport: 'Teleport',
  Settings: 'Settings', Night: 'Night Club', LuaContent: 'Lua', LuaEditor: 'Lua',
  OtherMenus: 'Other Menus', misc: 'Misc', Misc: 'Misc', Debug: 'Debug',
  ScriptHookV: 'Script Hook', SelfOutfits: 'Self', Weapons: 'Weapons',
  aimbot: 'Aimbot', esp: 'ESP', weapon: 'Weapons', weapons: 'Weapons',
  self: 'Self', vehicle: 'Vehicle', world: 'World', network: 'Network',
  players: 'Players', recovery: 'Recovery', teleport: 'Teleport',
  settings: 'Settings', night: 'Night Club', lua: 'Lua', spoofing: 'Network',
  protections: 'Network', mount: 'Mount', horse: 'Mount', outfit: 'Self',
};
const tabs = new Map();
const seen = new Set();

function add(tab, cat, grp, id) {
  const meta = labels.get(id);
  if (!meta || seen.has(id)) return;
  seen.add(id);
  if (!tabs.has(tab)) tabs.set(tab, new Map());
  const c = tabs.get(tab);
  if (!c.has(cat)) c.set(cat, new Map());
  const g = c.get(cat);
  if (!g.has(grp)) g.set(grp, []);
  g.get(grp).push({ id, label: meta.label, desc: meta.desc });
}

const TREE = /std::make_shared<(Category|Group)>\(\s*"((?:[^"\\]|\\.)*)"|std::make_shared<\w*Item>\(\s*"([A-Za-z0-9_]+)"_J/g;
for (const file of walk(SUBMENUS)) {
  const text = fs.readFileSync(file, 'utf8');
  const top = path.relative(SUBMENUS, file).replace(/\\/g, '/').split('/')[0].replace(/\.(cpp|hpp)$/, '');
  const tab = TAB[top] || top;
  let cat = 'General', grp = 'General', m;
  TREE.lastIndex = 0;
  while ((m = TREE.exec(text))) {
    if (m[1] === 'Category') { cat = m[2]; grp = 'General'; }
    else if (m[1] === 'Group') { grp = m[2]; }
    else if (m[3]) add(tab, cat, grp, m[3]);
  }
}

// fallback: place the rest by the directory they are declared in
for (const base of [FEATURES, G.root]) {
  for (const file of walk(base)) {
    if (seen.size >= labels.size) break;
    const text = fs.readFileSync(file, 'utf8');
    const rel = path.relative(base, file).replace(/\\/g, '/').split('/');
    const tab = TAB[(rel[0] || '').toLowerCase()] || TAB[rel[0]] || 'Misc';
    const cat = (rel.length > 1 ? rel[rel.length - 2] : path.basename(file).replace(/\.\w+$/, ''))
      .replace(/([a-z])([A-Z])/g, '$1 $2');
    for (const m of text.matchAll(/"([A-Za-z0-9_]{3,})"/g)) {
      if (labels.has(m[1]) && !seen.has(m[1])) add(tab, cat, 'More', m[1]);
    }
  }
}
// keep anything still unplaced rather than silently dropping it
for (const id of labels.keys()) if (!seen.has(id)) add('Misc', 'Additional', 'More', id);

// ---- emit --------------------------------------------------------------------
const manifest = {
  game: G.name, slug: G.slug,
  tabs: [...tabs.entries()].map(([name, cats]) => ({
    name,
    categories: [...cats.entries()].map(([n, gs]) => ({
      name: n, groups: [...gs.entries()].map(([gn, items]) => ({ name: gn, items })),
    })),
  })),
};
const count = t => t.categories.reduce((s, c) => s + c.groups.reduce((x, g) => x + g.items.length, 0), 0);
manifest.tabs.sort((a, b) => count(b) - count(a));

let total = 0, cats = 0, groups = 0, withDesc = 0;
for (const t of manifest.tabs) for (const c of t.categories) {
  cats++;
  for (const g of c.groups) { groups++; total += g.items.length; withDesc += g.items.filter(i => i.desc).length; }
}
manifest.stats = { features: total, withDescription: withDesc, tabs: manifest.tabs.length, categories: cats, groups };

console.log('tabs / cats / grps:', manifest.tabs.length, '/', cats, '/', groups);
console.log('features          :', total, '| with description:', withDesc);
for (const t of manifest.tabs) console.log('  ' + String(count(t)).padStart(5), t.name);

const out = path.join(__dirname, 'features-' + G.slug + '.json');
fs.writeFileSync(out, JSON.stringify(manifest, null, 1), 'utf8');
console.log('wrote', out);
