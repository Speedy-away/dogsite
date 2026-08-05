/*
 * Builds the redesigned All Features pages from the extracted manifests.
 *
 *   node build-features-page.js            # dry run
 *   node build-features-page.js --apply
 *
 * Nav and footer are lifted verbatim from an existing site page so the chrome
 * cannot drift. Reads the manifests only; never touches the game sources.
 */
const fs = require('fs'), path = require('path');

const SITE = 'C:/Users/whatw/OneDrive/Documents/GitHub/dogsite';
const APPLY = process.argv.includes('--apply');
const VERSION = '4.3';

const PAGES = [
  { manifest: 'features-gta5.json', out: 'features-list/gta-features/index.html',
    title: 'All GTA 5 Features - Scooby Mod Menu',
    heading: 'GTA 5 FEATURES', product: '/products/gta5/',
    desc: 'Every feature in the Scooby GTA 5 mod menu, searchable: recovery, heist editor, vehicles, outfits, protections, world, players and more.' },
  { manifest: 'features-rdr2.json', out: 'features-list/rdr2-features/index.html',
    title: 'All RDR2 Features - Scooby Mod Menu',
    heading: 'RDR2 FEATURES', product: '/products/rdr2/',
    desc: 'Every feature in the Scooby Red Dead Redemption 2 mod menu, searchable: self, weapons, world, players, network and more.' },
];

// ---- shared chrome ----------------------------------------------------------
const donor = fs.readFileSync(path.join(SITE, 'guides/gta5/index.html'), 'utf8');
function slice(open, close) {
  const a = donor.indexOf(open); const b = donor.indexOf(close, a);
  if (a < 0 || b < 0) throw new Error('donor marker missing: ' + open);
  return donor.slice(a, b + close.length);
}
const NAV = slice('    <!--== Header ==-->', '    </nav>');
const FOOT = donor.slice(donor.indexOf('    <!--== Footer ==-->'));
// The nav and footer markup depends on the site's shared stylesheet - lift it too,
// or the chrome renders unstyled (giant SVGs, bare links).
const CHROME_CSS = slice('<style>', '</style>');

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
  .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const slug = s => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

// ImGui packs a widget id after "##" ("Name##object"). It is never meant to be
// read, so strip it. ALL-CAPS leftovers become Title Case.
function clean(s) {
  let t = String(s).split('##')[0].replace(/\s+/g, ' ').trim();
  if (t && t === t.toUpperCase() && /[A-Z]{3}/.test(t)) {
    t = t.toLowerCase().replace(/\b\w/g, c => c.toUpperCase());
  }
  return t;
}

const CSS = `<style>
:root{--bg:#080808;--card:#111;--card-hi:#161616;--border:rgba(255,255,255,.07);
--border-hi:rgba(255,255,255,.13);--accent:#4f8ef5;--accent-soft:rgba(79,142,245,.13);
--accent-line:rgba(79,142,245,.32);--text:#f4f4f7;--dim:#9a9aaa;--faint:#5c5c6c;--green:#22c55e}
*{margin:0;padding:0;box-sizing:border-box}
html{scroll-behavior:smooth}
body{font-family:'Inter',-apple-system,BlinkMacSystemFont,sans-serif;background:var(--bg);
color:var(--text);line-height:1.6;overflow-x:hidden}
body::before{content:'';position:fixed;inset:0;pointer-events:none;z-index:0;
background:radial-gradient(ellipse at 20% 10%,rgba(79,142,245,.08),transparent 50%),
radial-gradient(ellipse at 80% 80%,rgba(37,99,235,.06),transparent 50%)}
.container{max-width:1180px;margin:0 auto;padding:0 24px;position:relative;z-index:1}

/* hero */
.fx-hero{padding:150px 0 40px;text-align:center}
.fx-title{font-size:3.2rem;font-weight:900;letter-spacing:2px;margin-bottom:14px}
.fx-sub{color:var(--dim);max-width:640px;margin:0 auto 28px}
.fx-stats{display:flex;justify-content:center;gap:14px;flex-wrap:wrap}
.fx-stat{background:var(--card);border:1px solid var(--border);border-radius:14px;
padding:16px 26px;min-width:120px}
.fx-stat b{display:block;font-size:1.7rem;font-weight:800;color:var(--accent);line-height:1.2}
.fx-stat span{font-size:.74rem;text-transform:uppercase;letter-spacing:1px;color:var(--faint)}

/* sticky controls */
.fx-controls{position:sticky;top:0;z-index:50;padding:16px 0;
background:rgba(8,8,8,.92);backdrop-filter:blur(14px);
border-bottom:1px solid var(--border);margin-bottom:28px}
.fx-search{position:relative;margin-bottom:12px}
.fx-search input{width:100%;padding:14px 18px 14px 46px;border-radius:12px;
background:var(--card);border:1px solid var(--border-hi);color:var(--text);
font-family:inherit;font-size:.95rem;outline:none;transition:border-color .2s}
.fx-search input:focus{border-color:var(--accent-line)}
.fx-search svg{position:absolute;left:16px;top:50%;transform:translateY(-50%);
width:18px;height:18px;color:var(--faint)}
.fx-tabs{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
.fx-tab{padding:7px 16px;border-radius:30px;border:1px solid var(--border);
background:rgba(255,255,255,.03);color:var(--dim);font-family:inherit;font-size:.83rem;
font-weight:600;cursor:pointer;transition:.2s;white-space:nowrap}
.fx-tab:hover{color:var(--text);border-color:var(--border-hi)}
.fx-tab.active{background:var(--accent-soft);border-color:var(--accent-line);color:var(--accent)}
.fx-tab i{font-style:normal;opacity:.55;margin-left:5px;font-size:.78rem}
.fx-count{margin-left:auto;color:var(--faint);font-size:.82rem;white-space:nowrap}

/* tree */
.fx-tab-block{margin-bottom:34px}
.fx-tab-name{font-size:1.5rem;font-weight:800;margin-bottom:14px;
padding-bottom:10px;border-bottom:1px solid var(--border)}
.fx-tab-name span{color:var(--faint);font-size:.85rem;font-weight:500;margin-left:8px}
.fx-cat{background:var(--card);border:1px solid var(--border);border-radius:14px;
margin-bottom:10px;overflow:hidden}
.fx-cat-head{display:flex;align-items:center;gap:10px;padding:15px 20px;cursor:pointer;
user-select:none;transition:background .2s}
.fx-cat-head:hover{background:var(--card-hi)}
.fx-cat-head h3{font-size:1rem;font-weight:650;flex:1}
.fx-cat-head .n{color:var(--faint);font-size:.82rem}
.fx-cat-head .chev{width:16px;height:16px;color:var(--faint);transition:transform .25s;flex-shrink:0}
.fx-cat.open .chev{transform:rotate(90deg)}
.fx-cat-body{display:none;padding:0 20px 8px}
.fx-cat.open .fx-cat-body{display:block}
.fx-group{margin-bottom:14px}
.fx-group-name{font-size:.72rem;font-weight:700;text-transform:uppercase;
letter-spacing:1px;color:var(--faint);margin:14px 0 8px}
.fx-items{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:8px}
.fx-item{background:rgba(255,255,255,.02);border:1px solid var(--border);
border-radius:10px;padding:11px 14px;transition:.18s}
.fx-item:hover{background:rgba(255,255,255,.04);border-color:var(--border-hi)}
.fx-item b{display:block;font-size:.9rem;font-weight:600;margin-bottom:3px}
.fx-item p{font-size:.81rem;color:var(--dim);line-height:1.5}
mark{background:rgba(79,142,245,.28);color:#cfe0ff;border-radius:3px;padding:0 2px}
.fx-empty{text-align:center;padding:70px 20px;color:var(--dim);display:none}
.fx-empty b{display:block;font-size:1.1rem;color:var(--text);margin-bottom:6px}
.fx-actions{display:flex;gap:10px;justify-content:center;margin:34px 0 60px;flex-wrap:wrap}
.fx-btn{display:inline-flex;align-items:center;gap:8px;padding:11px 24px;border-radius:50px;
font-size:.9rem;font-weight:600;text-decoration:none;transition:.2s;border:1px solid var(--border-hi)}
.fx-btn.primary{background:var(--accent);border-color:var(--accent);color:#fff}
.fx-btn.primary:hover{background:#3d7ae0}
.fx-btn.ghost{color:var(--dim)}
.fx-btn.ghost:hover{color:var(--text);background:rgba(255,255,255,.05)}
@media(max-width:760px){
.fx-hero{padding:120px 0 30px}
.fx-title{font-size:2.1rem}
.fx-stat{padding:12px 18px;min-width:96px}
.fx-stat b{font-size:1.35rem}
.fx-items{grid-template-columns:1fr}
.fx-count{width:100%;margin:6px 0 0}
}
</style>`;

const SCRIPT = `<script>
(function () {
  var search = document.getElementById('fxSearch');
  var tabs   = [].slice.call(document.querySelectorAll('.fx-tab'));
  var blocks = [].slice.call(document.querySelectorAll('.fx-tab-block'));
  var items  = [].slice.call(document.querySelectorAll('.fx-item'));
  var empty  = document.getElementById('fxEmpty');
  var countEl= document.getElementById('fxCount');
  var activeTab = 'all';

  // cache the searchable text once - 4k nodes is too many to re-read per keypress
  items.forEach(function (el) {
    el.__t = (el.getAttribute('data-s') || '').toLowerCase();
  });

  function esc(s){return s.replace(/[.*+?^\${}()|[\\]\\\\]/g,'\\\\$&');}

  function highlight(el, q) {
    var b = el.querySelector('b'), p = el.querySelector('p');
    [b, p].forEach(function (n) {
      if (!n) return;
      var raw = n.getAttribute('data-raw') || n.textContent;
      n.setAttribute('data-raw', raw);
      if (!q) { n.textContent = raw; return; }
      var re = new RegExp('(' + esc(q) + ')', 'ig');
      n.innerHTML = raw.replace(/[&<>]/g, function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];})
                       .replace(re, '<mark>$1</mark>');
    });
  }

  var timer;
  function apply() {
    var q = (search.value || '').trim().toLowerCase();
    var shown = 0;

    items.forEach(function (el) {
      var okTab = activeTab === 'all' || el.getAttribute('data-tab') === activeTab;
      var okQ   = !q || el.__t.indexOf(q) !== -1;
      var on    = okTab && okQ;
      el.style.display = on ? '' : 'none';
      if (on) { shown++; if (q) highlight(el, q); else highlight(el, ''); }
    });

    // roll visibility up: groups, then categories, then tab blocks
    [].forEach.call(document.querySelectorAll('.fx-group'), function (g) {
      g.style.display = g.querySelector('.fx-item:not([style*="none"])') ? '' : 'none';
    });
    [].forEach.call(document.querySelectorAll('.fx-cat'), function (c) {
      var any = c.querySelector('.fx-item:not([style*="none"])');
      c.style.display = any ? '' : 'none';
      if (q && any) c.classList.add('open');       // searching expands hits
    });
    blocks.forEach(function (b) {
      b.style.display = b.querySelector('.fx-cat:not([style*="none"])') ? '' : 'none';
    });

    empty.style.display = shown ? 'none' : 'block';
    countEl.textContent = shown.toLocaleString() + ' shown';
  }

  search.addEventListener('input', function () {
    clearTimeout(timer);
    timer = setTimeout(apply, 120);
  });

  tabs.forEach(function (t) {
    t.addEventListener('click', function () {
      tabs.forEach(function (x) { x.classList.remove('active'); });
      t.classList.add('active');
      activeTab = t.getAttribute('data-tab');
      apply();
    });
  });

  [].forEach.call(document.querySelectorAll('.fx-cat-head'), function (h) {
    h.addEventListener('click', function () { h.parentNode.classList.toggle('open'); });
  });

  document.getElementById('fxExpand').addEventListener('click', function (e) {
    e.preventDefault();
    var all = [].slice.call(document.querySelectorAll('.fx-cat'));
    var anyClosed = all.some(function (c) { return !c.classList.contains('open'); });
    all.forEach(function (c) { c.classList.toggle('open', anyClosed); });
    this.textContent = anyClosed ? 'Collapse all' : 'Expand all';
  });

  apply();
})();
</script>`;

// ---- render -----------------------------------------------------------------
function render(page) {
  const m = JSON.parse(fs.readFileSync(path.join(__dirname, page.manifest), 'utf8'));
  const s = m.stats;
  const url = 'https://scoobymenu.cc/' + page.out.replace(/index\.html$/, '');

  const tabPills = ['<button class="fx-tab active" data-tab="all">All<i>' +
    s.features.toLocaleString() + '</i></button>']
    .concat(m.tabs.map(t => {
      const n = t.categories.reduce((a, c) => a + c.groups.reduce((b, g) => b + g.items.length, 0), 0);
      return '<button class="fx-tab" data-tab="' + esc(slug(t.name)) + '">' +
        esc(t.name) + '<i>' + n + '</i></button>';
    })).join('\n          ');

  const body = m.tabs.map(t => {
    const tSlug = slug(t.name);
    const tN = t.categories.reduce((a, c) => a + c.groups.reduce((b, g) => b + g.items.length, 0), 0);
    const cats = t.categories.map(c => {
      const cN = c.groups.reduce((a, g) => a + g.items.length, 0);
      const groups = c.groups.map(g => {
        const its = g.items.map(i => {
          const lab = clean(i.label);
          const searchText = (lab + ' ' + i.desc).replace(/\s+/g, ' ').trim();
          return '<div class="fx-item" data-tab="' + tSlug + '" data-s="' + esc(searchText) + '">' +
            '<b>' + esc(lab) + '</b>' +
            (i.desc ? '<p>' + esc(i.desc) + '</p>' : '') + '</div>';
        }).join('');
        const gName = clean(g.name);
        const showName = c.groups.length > 1 || (gName !== 'General' && gName !== 'More');
        return '<div class="fx-group">' +
          (showName ? '<div class="fx-group-name">' + esc(gName) + '</div>' : '') +
          '<div class="fx-items">' + its + '</div></div>';
      }).join('');
      return '<div class="fx-cat" id="' + tSlug + '-' + slug(c.name) + '">' +
        '<div class="fx-cat-head"><svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>' +
        '<h3>' + esc(clean(c.name)) + '</h3><span class="n">' + cN + '</span></div>' +
        '<div class="fx-cat-body">' + groups + '</div></div>';
    }).join('\n');
    // data-i18n-skip: these are in-game feature names straight from the menu.
    // They are not in any dictionary, and walking 4k of them costs seconds.
    return '        <div class="fx-tab-block" data-i18n-skip data-tab="' + tSlug + '">\n' +
      '          <h2 class="fx-tab-name">' + esc(t.name) + '<span>' + tN + ' features</span></h2>\n' +
      cats + '\n        </div>';
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(page.title)}</title>
<meta name="description" content="${esc(page.desc)}">
<link rel="canonical" href="${url}">
<meta property="og:type" content="website">
<meta property="og:url" content="${url}">
<meta property="og:title" content="${esc(page.title)}">
<meta property="og:description" content="${esc(page.desc)}">
<meta property="og:image" content="https://scoobymenu.cc/background-home.jpg">
<meta property="og:site_name" content="Scooby Menu">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(page.title)}">
<meta name="twitter:description" content="${esc(page.desc)}">
<link rel="shortcut icon" href="/assets/images/logo.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
${CHROME_CSS}
${CSS}
  <script src="/languages/i18n.js"></script>
  <link rel="stylesheet" href="/assets/css/mobile.css">
</head>
<body>
${NAV}
    <div class="fx-hero">
      <div class="container">
        <h1 class="fx-title">${esc(page.heading)}</h1>
        <p class="fx-sub">${esc(page.desc)}</p>
        <div class="fx-stats">
          <div class="fx-stat"><b>${s.features.toLocaleString()}</b><span>Features</span></div>
          <div class="fx-stat"><b>${s.tabs}</b><span>Tabs</span></div>
          <div class="fx-stat"><b>${s.categories}</b><span>Categories</span></div>
          <div class="fx-stat"><b>v${VERSION}</b><span>Version</span></div>
        </div>
      </div>
    </div>

    <div class="fx-controls">
      <div class="container">
        <div class="fx-search">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input id="fxSearch" type="search" placeholder="Search ${s.features.toLocaleString()} features&hellip;" autocomplete="off" data-i18n-skip>
        </div>
        <div class="fx-tabs">
          ${tabPills}
          <span class="fx-count" id="fxCount"></span>
        </div>
      </div>
    </div>

    <div class="container">
${body}
      <div class="fx-empty" id="fxEmpty"><b>No features match that search</b>Try a different word, or clear the filter.</div>
      <div class="fx-actions">
        <a class="fx-btn primary" href="${page.product}">View pricing</a>
        <a class="fx-btn ghost" href="#" id="fxExpand">Expand all</a>
        <a class="fx-btn ghost" href="/">Back to home</a>
      </div>
    </div>
${SCRIPT}
${FOOT}`;
}

for (const p of PAGES) {
  const html = render(p);
  const dest = path.join(SITE, p.out);
  console.log(p.out, '->', Math.round(html.length / 1024) + ' KB');
  if (APPLY) { fs.mkdirSync(path.dirname(dest), { recursive: true }); fs.writeFileSync(dest, html, 'utf8'); }
}
console.log(APPLY ? 'WROTE' : 'DRY RUN - re-run with --apply');
