/*
 * Splits guides/index.html (5 tabs in one document) into one page per game,
 * and rewrites guides/index.html as a hub. Shared head/nav/footer/scripts are
 * lifted verbatim from the source so every page stays byte-identical in chrome.
 *
 *   node split-guides.js            # dry run
 *   node split-guides.js --apply
 */
const fs = require('fs');
const path = require('path');

const ROOT = process.argv.find(a => a.startsWith('--root=')) ?
             process.argv.find(a => a.startsWith('--root=')).slice(7) :
             'C:/Users/whatw/OneDrive/Documents/GitHub/dogsite';
const APPLY = process.argv.includes('--apply');
const SRC = path.join(ROOT, 'guides', 'index.html');
const html = fs.readFileSync(SRC, 'utf8');

const PAGES = [
  { id: 'gta5',    slug: 'gta5',    tab: 'GTA 5',   name: 'GTA 5',
    title: 'GTA 5 Setup Guide - Scooby Mod Menu',
    desc: 'Complete GTA 5 setup guide for Scooby mod menu: first time setup, free version, modded outfits and vehicles, money methods, hosting public sessions and troubleshooting.',
    sub: 'Setup, features and troubleshooting for GTA 5' },
  { id: 'fivem',   slug: 'fivem',   tab: 'FiveM',   name: 'FiveM',
    title: 'FiveM Setup Guide - Scooby Mod Menu',
    desc: 'FiveM setup guide for Scooby: requirements, VC Runtimes, installation and fixes for crashing and connection errors.',
    sub: 'Requirements and installation for FiveM' },
  { id: 'redm',    slug: 'redm',    tab: 'RedM',    name: 'RedM',
    title: 'RedM Setup Guide - Scooby Mod Menu',
    desc: 'RedM setup guide for Scooby: requirements, VC Runtimes, installation and fixes for crashing and connection errors.',
    sub: 'Requirements and installation for RedM' },
  { id: 'rdr2',    slug: 'rdr2',    tab: 'RDR2',    name: 'RDR2',
    title: 'RDR2 Setup Guide - Scooby Mod Menu',
    desc: 'Red Dead Redemption 2 setup guide for Scooby: what to do before launching, how to launch the menu and how to fix crashes.',
    sub: 'Setup and troubleshooting for Red Dead Redemption 2' },
  { id: 'general', slug: 'general', tab: 'General', name: 'General',
    title: 'General Guides - Scooby Mod Menu',
    desc: 'General Scooby guides: getting a free key, resetting your HWID, fixing connection or SSL errors and solving crashes.',
    sub: 'Free keys, HWID resets and common fixes' },
];

// ---- slice the shared chrome ------------------------------------------------
function between(open, close, from = 0) {
  const a = html.indexOf(open, from);
  if (a < 0) throw new Error('missing marker: ' + open);
  const b = html.indexOf(close, a);
  if (b < 0) throw new Error('missing close: ' + close);
  return { start: a, end: b + close.length, text: html.slice(a, b + close.length) };
}

const headBlock = between('<!DOCTYPE html>', '</head>');
const navBlock  = between('    <!--== Header ==-->', '    </nav>');
// everything from the footer comment to the end of the document
const tailStart = html.indexOf('    <!--== Footer ==-->');
if (tailStart < 0) throw new Error('missing footer marker');
const tail = html.slice(tailStart);

// ---- pull each tab's inner HTML --------------------------------------------
// Tabs are siblings: <div id="X" class="tab-content..."> ... </div> before the
// next tab (or before the closing </div></section>). Depth-count to find the end.
function tabInner(id) {
  const openRe = new RegExp('<div id="' + id + '" class="tab-content[^"]*">');
  const m = openRe.exec(html);
  if (!m) throw new Error('tab not found: ' + id);
  let i = m.index + m[0].length;
  let depth = 1;
  const tagRe = /<\/?div\b[^>]*>/g;
  tagRe.lastIndex = i;
  let t;
  while ((t = tagRe.exec(html))) {
    depth += t[0][1] === '/' ? -1 : 1;
    if (depth === 0) return html.slice(i, t.index);
  }
  throw new Error('unbalanced tab: ' + id);
}

// ---- rewrite links that used to switch tabs --------------------------------
// Which page owns which anchor, so cross-tab links become cross-page links.
const anchorOwner = {};
for (const p of PAGES) {
  const inner = tabInner(p.id);
  const ids = inner.match(/\bid="([a-z0-9-]+)"/g) || [];
  ids.forEach(s => { anchorOwner[s.slice(4, -1)] = p.slug; });
}

function rewriteLinks(inner, ownSlug) {
  let out = inner;
  const unresolved = [];
  // <a href="#x" onclick="switchTab('y');return false;">  ->  /guides/y/#x
  out = out.replace(
    /<a href="#([a-z0-9-]+)" onclick="switchTab\('([a-z0-9]+)'\);return false;">/g,
    (full, anchor, tabId) => {
      const target = (PAGES.find(p => p.id === tabId) || {}).slug;
      if (!target) { unresolved.push(full); return full; }
      return target === ownSlug
        ? '<a href="#' + anchor + '">'
        : '<a href="/guides/' + target + '/#' + anchor + '">';
    });
  // plain in-page anchors that actually live on another page
  out = out.replace(/href="#([a-z0-9-]+)"/g, (full, anchor) => {
    const owner = anchorOwner[anchor];
    if (!owner || owner === ownSlug) return full;
    return 'href="/guides/' + owner + '/#' + anchor + '"';
  });
  if (unresolved.length) console.log('  ! unresolved:', unresolved);
  return out;
}

// ---- sidebar ----------------------------------------------------------------
// The old inline table of contents is replaced by a sticky sidebar, so drop it.
function stripToc(inner) {
  const m = /<div class="toc">/.exec(inner);
  if (!m) return inner;
  let i = m.index + m[0].length, depth = 1;
  const tagRe = /<\/?div\b[^>]*>/g;
  tagRe.lastIndex = i;
  let t;
  while ((t = tagRe.exec(inner))) {
    depth += t[0][1] === '/' ? -1 : 1;
    if (depth === 0) return inner.slice(0, m.index) + inner.slice(t.index + t[0].length);
  }
  return inner;
}

// Every .guide-card with an id and an <h2> becomes a sidebar row.
function sections(inner) {
  const out = [];
  const re = /<div class="guide-card" id="([a-z0-9-]+)">\s*<h2>([\s\S]*?)<\/h2>/g;
  let m;
  while ((m = re.exec(inner))) {
    out.push({ id: m[1], label: m[2].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim() });
  }
  return out;
}

function sidebarFor(inner) {
  const secs = sections(inner);
  // A one-row sidebar is just noise - those pages stay full width.
  if (secs.length < 2) return '';
  return '                <aside class="guide-sidebar">\n' +
    '                    <div class="guide-sidebar-inner">\n' +
    '                        <h3>On this page</h3>\n' +
    '                        <nav class="guide-nav">\n' +
    secs.map(s => '                            <a href="#' + s.id + '">' + s.label + '</a>').join('\n') +
    '\n                        </nav>\n' +
    '                    </div>\n' +
    '                </aside>\n';
}

const LAYOUT_CSS = `<style>
    /* Two-column guide layout with a sticky section nav */
    .guide-layout {
        display: grid;
        grid-template-columns: 250px minmax(0, 1fr);
        gap: 40px;
        /* No align-items:start - the aside must stretch to the row height or
           the sticky inner has no travel room and scrolls away immediately. */
    }
    .guide-sidebar-inner {
        position: sticky;
        top: 100px;
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 14px;
        padding: 20px;
        max-height: calc(100vh - 130px);
        overflow-y: auto;
    }
    .guide-sidebar-inner h3 {
        font-size: .72rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 1px;
        color: var(--text-secondary);
        margin: 0 0 14px;
    }
    .guide-nav { display: flex; flex-direction: column; gap: 2px; }
    .guide-nav a {
        display: block;
        padding: 8px 12px;
        border-radius: 8px;
        border-left: 2px solid transparent;
        color: var(--text-secondary);
        font-size: .87rem;
        line-height: 1.4;
        text-decoration: none;
        transition: all .2s ease;
    }
    .guide-nav a:hover {
        background: rgba(255,255,255,.04);
        color: var(--text-primary);
    }
    .guide-nav a.active {
        background: var(--accent-soft);
        border-left-color: var(--accent);
        color: var(--accent);
        font-weight: 600;
    }
    .guide-main { min-width: 0; }
    @media (max-width: 900px) {
        .guide-layout { grid-template-columns: 1fr; gap: 24px; }
        .guide-sidebar-inner {
            position: static;
            max-height: none;
            padding: 16px;
        }
        .guide-nav {
            flex-direction: row;
            flex-wrap: wrap;
            gap: 8px;
        }
        .guide-nav a {
            border-left: none;
            border: 1px solid var(--border);
            padding: 7px 13px;
            font-size: .82rem;
        }
        .guide-nav a.active { border-color: var(--accent-line); }
    }
</style>
`;

const SCROLLSPY = `    <script>
    // Highlight the sidebar row for whichever section is currently in view.
    (function () {
        var links = [].slice.call(document.querySelectorAll('.guide-nav a'));
        if (!links.length) return;
        var targets = links.map(function (a) {
            return document.getElementById(a.getAttribute('href').slice(1));
        });
        function sync() {
            var best = 0;
            for (var i = 0; i < targets.length; i++) {
                if (targets[i] && targets[i].getBoundingClientRect().top <= 140) best = i;
            }
            links.forEach(function (a, i) { a.classList.toggle('active', i === best); });
        }
        window.addEventListener('scroll', sync, { passive: true });
        sync();
    })();
    </script>
`;

// ---- per-page head ----------------------------------------------------------
function headFor(p) {
  const url = 'https://scoobymenu.cc/guides/' + p.slug + '/';
  return headBlock.text
    .replace('</head>', LAYOUT_CSS + '</head>')
    .replace(/<title>[^<]*<\/title>/, '<title>' + p.title + '</title>')
    .replace(/(<meta name="description" content=")[^"]*(">)/, '$1' + p.desc + '$2')
    .replace(/(<link rel="canonical" href=")[^"]*(">)/, '$1' + url + '$2')
    .replace(/(<meta property="og:url" content=")[^"]*(">)/, '$1' + url + '$2')
    .replace(/(<meta property="og:title" content=")[^"]*(">)/, '$1' + p.title + '$2')
    .replace(/(<meta property="og:description" content=")[^"]*(">)/, '$1' + p.desc + '$2')
    .replace(/(<meta name="twitter:title" content=")[^"]*(">)/, '$1' + p.title + '$2')
    .replace(/(<meta name="twitter:description" content=")[^"]*(">)/, '$1' + p.desc + '$2');
}

// ---- the game switcher, now real links -------------------------------------
function tabStrip(activeSlug) {
  return '            <div class="game-tabs">\n' +
    PAGES.map(p =>
      '                <a class="game-tab' + (p.slug === activeSlug ? ' active' : '') +
      '" href="/guides/' + p.slug + '/">' + p.tab + '</a>'
    ).join('\n') + '\n            </div>\n';
}

// ---- breadcrumb JSON-LD so search engines see the hierarchy ----------------
function breadcrumb(p) {
  return '<script type="application/ld+json">' + JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://scoobymenu.cc/' },
      { '@type': 'ListItem', position: 2, name: 'Guides', item: 'https://scoobymenu.cc/guides/' },
      { '@type': 'ListItem', position: 3, name: p.name + ' Guide', item: 'https://scoobymenu.cc/guides/' + p.slug + '/' },
    ],
  }) + '</script>\n';
}

// ---- build ------------------------------------------------------------------
const written = [];

for (const p of PAGES) {
  console.log('building /guides/' + p.slug + '/');
  const inner = stripToc(rewriteLinks(tabInner(p.id), p.slug));
  const sidebar = sidebarFor(inner);
  console.log('  sections:', sections(inner).length);
  const doc =
    headFor(p) + '\n<body>\n' +
    navBlock.text + '\n' +
    '    <!--== Page Header ==-->\n' +
    '    <div class="page-header">\n' +
    '        <div class="container">\n' +
    '            <h1 class="page-title">' + p.name.toUpperCase() + ' GUIDES</h1>\n' +
    '            <p class="page-subtitle">' + p.sub + '</p>\n' +
    '        </div>\n' +
    '    </div>\n' +
    '    <!--== Guide Content ==-->\n' +
    '    <section class="guide-section">\n' +
    '        <div class="container">\n' +
    tabStrip(p.slug) +
    (sidebar
      ? '            <div class="guide-layout">\n' + sidebar +
        '                <div class="guide-main">\n' + inner +
        '                </div>\n            </div>\n'
      : inner) +
    '        </div>\n' +
    '    </section>\n' +
    SCROLLSPY +
    breadcrumb(p) +
    tail;

  const out = path.join(ROOT, 'guides', p.slug, 'index.html');
  written.push([out, doc]);
}

// ---- hub page ---------------------------------------------------------------
const HUB_DESC = 'Scooby setup guides for GTA 5, FiveM, RedM and RDR2, plus free keys, HWID resets and fixes for crashes and connection errors.';
const hubCards = PAGES.map(p =>
  '                <a class="hub-card" href="/guides/' + p.slug + '/">\n' +
  '                    <h2>' + p.name + '</h2>\n' +
  '                    <p>' + p.sub + '</p>\n' +
  '                    <span class="hub-go">Open guide\n' +
  '                        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"></polyline></svg>\n' +
  '                    </span>\n' +
  '                </a>'
).join('\n');

const HUB_CSS = `<style>
    .hub-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 18px;
        margin-bottom: 50px;
    }
    .hub-card {
        display: block;
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 16px;
        padding: 28px;
        text-decoration: none;
        transition: all .25s ease;
    }
    .hub-card:hover {
        background: var(--card-hover);
        border-color: var(--accent-line);
        transform: translateY(-3px);
    }
    .hub-card h2 {
        font-size: 1.35rem;
        font-weight: 700;
        color: var(--text-primary);
        margin: 0 0 8px;
    }
    .hub-card p {
        color: var(--text-secondary);
        font-size: .93rem;
        line-height: 1.6;
        margin: 0 0 16px;
    }
    .hub-go {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        color: var(--accent);
        font-size: .88rem;
        font-weight: 600;
    }
</style>
`;

const hubHead = headBlock.text
  .replace(/<title>[^<]*<\/title>/, '<title>Setup Guides - Scooby Mod Menu</title>')
  .replace(/(<meta name="description" content=")[^"]*(">)/, '$1' + HUB_DESC + '$2')
  .replace(/(<link rel="canonical" href=")[^"]*(">)/, '$1https://scoobymenu.cc/guides/$2')
  .replace(/(<meta property="og:url" content=")[^"]*(">)/, '$1https://scoobymenu.cc/guides/$2')
  .replace(/(<meta property="og:title" content=")[^"]*(">)/, '$1Setup Guides - Scooby Mod Menu$2')
  .replace(/(<meta property="og:description" content=")[^"]*(">)/, '$1' + HUB_DESC + '$2')
  .replace(/(<meta name="twitter:title" content=")[^"]*(">)/, '$1Setup Guides - Scooby Mod Menu$2')
  .replace(/(<meta name="twitter:description" content=")[^"]*(">)/, '$1' + HUB_DESC + '$2')
  .replace('</head>', HUB_CSS + '</head>');

const hub =
  hubHead + '\n<body>\n' +
  navBlock.text + '\n' +
  '    <!--== Page Header ==-->\n' +
  '    <div class="page-header">\n' +
  '        <div class="container">\n' +
  '            <h1 class="page-title">SETUP GUIDES</h1>\n' +
  '            <p class="page-subtitle">Select a game to view setup guides and tutorials</p>\n' +
  '        </div>\n' +
  '    </div>\n' +
  '    <section class="guide-section">\n' +
  '        <div class="container">\n' +
  '            <div class="hub-grid">\n' + hubCards + '\n            </div>\n' +
  '            <div style="text-align:center;">\n' +
  '                <a href="/" class="back-link">\n' +
  '                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"></polyline></svg>\n' +
  '                    Back to Home\n' +
  '                </a>\n' +
  '            </div>\n' +
  '        </div>\n' +
  '    </section>\n' +
  tail;

written.push([path.join(ROOT, 'guides', 'index.html'), hub]);

// ---- report / write ---------------------------------------------------------
console.log('');
for (const [f, doc] of written) {
  console.log((APPLY ? 'WROTE  ' : 'would write  ') + path.relative(ROOT, f).replace(/\\/g, '/') +
              '  (' + Math.round(doc.length / 1024) + ' KB)');
  if (APPLY) {
    fs.mkdirSync(path.dirname(f), { recursive: true });
    fs.writeFileSync(f, doc, 'utf8');
  }
}
if (!APPLY) console.log('\nDRY RUN - re-run with --apply');
