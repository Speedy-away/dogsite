/*
 * Redesigns changelog/index.html.
 *
 * Every existing version card is carried over VERBATIM - this only rebuilds the
 * page around them. No release note is invented, reworded or dropped.
 *
 *   node build-changelog.js            # dry run
 *   node build-changelog.js --apply
 */
const fs = require('fs'), path = require('path');

const SITE = 'C:/Users/whatw/OneDrive/Documents/GitHub/dogsite';
const APPLY = process.argv.includes('--apply');
const SRC = path.join(SITE, 'changelog/index.html');
const src = fs.readFileSync(SRC, 'utf8');

// ---- carve out every version card, keeping its inner HTML untouched ---------
function cards() {
  const out = [];
  const re = /<div class="version-card"(?:\s+id="([^"]*)")?>/g;
  let m;
  while ((m = re.exec(src))) {
    let i = m.index + m[0].length, depth = 1;
    const tag = /<\/?div\b[^>]*>/g;
    tag.lastIndex = i;
    let t;
    while ((t = tag.exec(src))) {
      depth += t[0][1] === '/' ? -1 : 1;
      if (depth === 0) break;
    }
    if (!t) throw new Error('unbalanced version-card: ' + m[1]);
    const inner = src.slice(i, t.index);
    const title = (/<h2 class="version-title">([\s\S]*?)<\/h2>/.exec(inner) || [, ''])[1]
      .replace(/<[^>]+>/g, '').trim();
    const date = (/<span class="version-date">([\s\S]*?)<\/span>/.exec(inner) || [, ''])[1]
      .replace(/<[^>]+>/g, '').trim();
    const badge = (/<span class="version-badge[^"]*">([\s\S]*?)<\/span>/.exec(inner) || [, ''])[1]
      .replace(/<[^>]+>/g, '').trim();
    const text = inner.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    out.push({ id: m[1] || '', title, date, badge, inner, text });
    re.lastIndex = t.index;
  }
  return out;
}
const CARDS = cards();
console.log('version cards found:', CARDS.length);
if (CARDS.length < 30) throw new Error('parsed too few cards - refusing to rebuild');

// ---- shared chrome ----------------------------------------------------------
const donor = fs.readFileSync(path.join(SITE, 'guides/gta5/index.html'), 'utf8');
const cut = (o, c) => { const a = donor.indexOf(o), b = donor.indexOf(c, a); return donor.slice(a, b + c.length); };
const CHROME_CSS = cut('<style>', '</style>');
const NAV = cut('    <!--== Header ==-->', '    </nav>');
const FOOT = donor.slice(donor.indexOf('    <!--== Footer ==-->'));

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const CSS = `<style>
:root{--cl-card:#111;--cl-border:rgba(255,255,255,.07);--cl-border-hi:rgba(255,255,255,.13);
--cl-accent:#4f8ef5;--cl-soft:rgba(79,142,245,.13);--cl-line:rgba(79,142,245,.32);
--cl-text:#f4f4f7;--cl-dim:#9a9aaa;--cl-faint:#5c5c6c}
.cl-hero{padding:150px 0 36px;text-align:center}
.cl-title{font-size:3.1rem;font-weight:900;letter-spacing:2px;margin-bottom:12px;color:var(--cl-text)}
.cl-sub{color:var(--cl-dim);max-width:600px;margin:0 auto 26px}
.cl-stats{display:flex;justify-content:center;gap:14px;flex-wrap:wrap}
.cl-stat{background:var(--cl-card);border:1px solid var(--cl-border);border-radius:14px;padding:15px 26px;min-width:112px}
.cl-stat b{display:block;font-size:1.6rem;font-weight:800;color:var(--cl-accent);line-height:1.2}
.cl-stat span{font-size:.72rem;text-transform:uppercase;letter-spacing:1px;color:var(--cl-faint)}
.cl-search{position:sticky;top:0;z-index:50;padding:14px 0;background:rgba(8,8,8,.93);
backdrop-filter:blur(14px);border-bottom:1px solid var(--cl-border);margin-bottom:30px}
.cl-search-in{position:relative}
.cl-search input{width:100%;padding:13px 18px 13px 46px;border-radius:12px;background:var(--cl-card);
border:1px solid var(--cl-border-hi);color:var(--cl-text);font-family:inherit;font-size:.94rem;outline:none}
.cl-search input:focus{border-color:var(--cl-line)}
.cl-search svg{position:absolute;left:16px;top:50%;transform:translateY(-50%);width:18px;height:18px;color:var(--cl-faint)}
.cl-layout{display:grid;grid-template-columns:190px minmax(0,1fr);gap:36px}
.cl-side-in{position:sticky;top:86px;background:var(--cl-card);border:1px solid var(--cl-border);
border-radius:14px;padding:16px;max-height:calc(100vh - 116px);overflow-y:auto}
.cl-side-in h3{font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:1px;
color:var(--cl-faint);margin-bottom:12px}
.cl-jump{display:flex;flex-direction:column;gap:1px}
.cl-jump a{display:flex;justify-content:space-between;gap:8px;padding:7px 11px;border-radius:8px;
border-left:2px solid transparent;color:var(--cl-dim);font-size:.85rem;text-decoration:none;transition:.18s}
.cl-jump a:hover{background:rgba(255,255,255,.04);color:var(--cl-text)}
.cl-jump a.active{background:var(--cl-soft);border-left-color:var(--cl-accent);color:var(--cl-accent);font-weight:600}
.cl-jump a i{font-style:normal;font-size:.72rem;color:var(--cl-faint)}
.cl-main{min-width:0}
.cl-v{background:var(--cl-card);border:1px solid var(--cl-border);border-radius:16px;
padding:26px 28px;margin-bottom:16px;scroll-margin-top:96px;transition:border-color .2s}
.cl-v:hover{border-color:var(--cl-border-hi)}
.cl-v-head{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:18px;
padding-bottom:14px;border-bottom:1px solid var(--cl-border)}
.cl-v-title{font-size:1.5rem;font-weight:800;color:var(--cl-text)}
.cl-v-date{color:var(--cl-faint);font-size:.85rem}
.cl-v-badge{margin-left:auto;padding:4px 12px;border-radius:30px;font-size:.7rem;font-weight:700;
text-transform:uppercase;letter-spacing:.5px;background:var(--cl-soft);color:var(--cl-accent);
border:1px solid var(--cl-line)}
.cl-v-badge.soon{background:rgba(234,179,8,.12);color:#eab308;border-color:rgba(234,179,8,.3)}
.cl-v-body .feature-category{margin-bottom:18px}
.cl-v-body .feature-category:last-child{margin-bottom:0}
.cl-v-body .category-title{font-size:.74rem;font-weight:700;text-transform:uppercase;
letter-spacing:1px;color:var(--cl-accent);margin-bottom:9px}
.cl-v-body ul{list-style:none;padding:0;margin:0}
.cl-v-body li{position:relative;padding-left:18px;margin-bottom:7px;color:var(--cl-dim);
font-size:.9rem;line-height:1.6}
.cl-v-body li::before{content:'';position:absolute;left:3px;top:.62em;width:5px;height:5px;
border-radius:50%;background:var(--cl-line)}
.cl-v-body li strong{color:var(--cl-text);font-weight:600}
.cl-v-body p{color:var(--cl-dim);font-size:.9rem;margin-bottom:10px}
.cl-v-body h3,.cl-v-body h4{color:var(--cl-text);font-size:.95rem;margin:14px 0 8px}
.cl-v-body img{max-width:100%;height:auto;border-radius:10px;margin:10px 0}
.cl-empty{display:none;text-align:center;padding:70px 20px;color:var(--cl-dim)}
.cl-empty b{display:block;font-size:1.1rem;color:var(--cl-text);margin-bottom:6px}
mark{background:rgba(79,142,245,.28);color:#cfe0ff;border-radius:3px;padding:0 2px}
@media(max-width:900px){
.cl-layout{grid-template-columns:1fr;gap:20px}
.cl-side-in{position:static;max-height:none}
.cl-jump{flex-direction:row;flex-wrap:wrap;gap:7px}
.cl-jump a{border-left:none;border:1px solid var(--cl-border);padding:6px 12px;font-size:.8rem}
.cl-jump a i{display:none}
.cl-hero{padding:120px 0 26px}
.cl-title{font-size:2.1rem}
.cl-v{padding:20px}
}
</style>`;

// ---- rebuild each card ------------------------------------------------------
// The card's content is copied VERBATIM. Re-parsing it lost 76 release notes to
// nested divs, so the original markup is kept and the original class names are
// restyled in CSS instead.
function rebuild(c) {
  const cm = /<div class="version-content">([\s\S]*)<\/div>/.exec(c.inner);
  const content = cm ? cm[1] : c.inner;
  const badge = c.badge
    ? '<span class="cl-v-badge' + (/soon|coming/i.test(c.badge) ? ' soon' : '') + '">' + esc(c.badge) + '</span>'
    : '';
  const id = c.id || c.title.replace(/[^\w.]/g, '');
  return '      <div class="cl-v" id="' + esc(id) + '" data-s="' + esc(c.text.toLowerCase()) + '">\n' +
    '        <div class="cl-v-head"><span class="cl-v-title">' + esc(c.title) + '</span>' +
    (c.date ? '<span class="cl-v-date">' + esc(c.date) + '</span>' : '') + badge + '</div>\n' +
    '        <div class="cl-v-body">' + content + '</div>\n      </div>';
}

const jump = CARDS.map(c =>
  '            <a href="#' + esc(c.id || c.title.replace(/[^\w.]/g, '')) + '">' + esc(c.title) +
  (c.date ? '<i>' + esc(c.date.replace(/\s*\d{4}$/, '')) + '</i>' : '') + '</a>').join('\n');

const latest = CARDS.find(c => /latest/i.test(c.badge)) || CARDS[0];
const DESC = 'Every Scooby release, with what changed in each version across GTA 5, RDR2, FiveM, RedM and the loader.';

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Changelog - Scooby Mod Menu</title>
<meta name="description" content="${esc(DESC)}">
<link rel="canonical" href="https://scoobymenu.cc/changelog/">
<meta property="og:type" content="website">
<meta property="og:url" content="https://scoobymenu.cc/changelog/">
<meta property="og:title" content="Changelog - Scooby Mod Menu">
<meta property="og:description" content="${esc(DESC)}">
<meta property="og:image" content="https://scoobymenu.cc/background-home.jpg">
<meta property="og:site_name" content="Scooby Menu">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Changelog - Scooby Mod Menu">
<meta name="twitter:description" content="${esc(DESC)}">
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
    <div class="cl-hero">
      <div class="container">
        <h1 class="cl-title">CHANGELOG</h1>
        <p class="cl-sub">${esc(DESC)}</p>
        <div class="cl-stats">
          <div class="cl-stat"><b>${CARDS.length}</b><span>Releases</span></div>
          <div class="cl-stat"><b>${esc(latest.title)}</b><span>Latest</span></div>
          <div class="cl-stat"><b>${esc((latest.date || '').split(' ')[0] || '-')}</b><span>Released</span></div>
        </div>
      </div>
    </div>

    <div class="cl-search">
      <div class="container">
        <div class="cl-search-in">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input id="clSearch" type="search" placeholder="Search all ${CARDS.length} releases&hellip;" autocomplete="off" data-i18n-skip>
        </div>
      </div>
    </div>

    <div class="container">
      <div class="cl-layout">
        <aside>
          <div class="cl-side-in">
            <h3>Versions</h3>
            <nav class="cl-jump">
${jump}
            </nav>
          </div>
        </aside>
        <div class="cl-main">
${CARDS.map(rebuild).join('\n')}
          <div class="cl-empty" id="clEmpty"><b>No releases match that search</b>Try a different word, or clear the filter.</div>
        </div>
      </div>
    </div>

<script>
(function () {
  var input = document.getElementById('clSearch');
  var cards = [].slice.call(document.querySelectorAll('.cl-v'));
  var links = [].slice.call(document.querySelectorAll('.cl-jump a'));
  var empty = document.getElementById('clEmpty');
  var timer;

  function apply() {
    var q = (input.value || '').trim().toLowerCase();
    var shown = 0;
    cards.forEach(function (c) {
      var on = !q || (c.getAttribute('data-s') || '').indexOf(q) !== -1;
      c.style.display = on ? '' : 'none';
      if (on) shown++;
      var id = c.id;
      links.forEach(function (a) {
        if (a.getAttribute('href') === '#' + id) a.style.display = on ? '' : 'none';
      });
    });
    empty.style.display = shown ? 'none' : 'block';
  }
  input.addEventListener('input', function () { clearTimeout(timer); timer = setTimeout(apply, 120); });

  // highlight whichever release is currently in view
  function spy() {
    var best = null;
    cards.forEach(function (c) {
      if (c.style.display === 'none') return;
      if (c.getBoundingClientRect().top <= 130) best = c.id;
    });
    if (!best && cards.length) best = cards[0].id;
    links.forEach(function (a) { a.classList.toggle('active', a.getAttribute('href') === '#' + best); });
  }
  window.addEventListener('scroll', spy, { passive: true });
  spy();
})();
</script>
${FOOT}`;

console.log('latest:', latest.title, '|', latest.date);
console.log('output:', Math.round(html.length / 1024) + ' KB (was ' + Math.round(src.length / 1024) + ' KB)');
if (APPLY) { fs.writeFileSync(SRC, html, 'utf8'); console.log('WROTE'); }
else console.log('DRY RUN - re-run with --apply');
