/*!
 * Scooby site i18n — runtime translation + language selector.
 *
 * Drop this one tag into any page and it handles the rest:
 *   <script src="/assets/i18n/i18n.js"></script>
 *
 * How it works: the page stays authored in English. Dictionaries map the
 * English source string to a translation, so no per-element markup is needed
 * and new pages are covered automatically once their strings are in the
 * dictionary. See TRANSLATIONS.md.
 */
(function () {
  'use strict';

  if (window.__scoobyI18n) return;              // already loaded on this page

  var DEFAULT_LANG = 'en';
  var STORAGE_KEY = 'scooby.lang';

  var LANGS = [
    { code: 'en', label: 'EN', native: 'English'    },
    { code: 'es', label: 'ES', native: 'Español'    },
    { code: 'pt', label: 'PT', native: 'Português'  },
    { code: 'fr', label: 'FR', native: 'Français'   },
    { code: 'de', label: 'DE', native: 'Deutsch'    },
    { code: 'ru', label: 'RU', native: 'Русский'    }
  ];
  var CODES = LANGS.map(function (l) { return l.code; });

  // Resolve sibling dictionaries from this script's own URL so the code works
  // at any directory depth, and over file:// as well as http://.
  var BASE = (function () {
    var s = document.currentScript;
    if (!s) {
      var all = document.getElementsByTagName('script');
      for (var i = all.length - 1; i >= 0; i--) {
        if (/i18n\.js(\?|$)/.test(all[i].src)) { s = all[i]; break; }
      }
    }
    return s && s.src ? s.src.replace(/[^/]*$/, '') : '/assets/i18n/';
  })();

  // ---------------------------------------------------------------- state ---

  var dicts = { en: {} };        // lang -> { english: translated }
  var current = DEFAULT_LANG;
  var textOriginals = new WeakMap();   // text node -> original English
  var attrOriginals = new WeakMap();   // element   -> { attr: original }
  var titleOriginal = null;
  var observer = null;
  var applying = false;

  // ------------------------------------------------------------ preference ---

  function stored() {
    try { return localStorage.getItem(STORAGE_KEY); } catch (e) { return null; }
  }
  function store(code) {
    try { localStorage.setItem(STORAGE_KEY, code); } catch (e) { /* private mode */ }
  }

  function detect() {
    var saved = stored();
    if (saved && CODES.indexOf(saved) !== -1) return saved;
    var navLangs = navigator.languages || [navigator.language || ''];
    for (var i = 0; i < navLangs.length; i++) {
      var base = String(navLangs[i]).toLowerCase().split('-')[0];
      if (CODES.indexOf(base) !== -1) return base;
    }
    return DEFAULT_LANG;
  }

  // ------------------------------------------------- anti-flash of English ---
  // Only hide content when we already know a non-English language is coming,
  // so English visitors never pay for this.

  var initial = detect();

  function hideWhileLoading() {
    if (initial === DEFAULT_LANG) return;
    var st = document.createElement('style');
    st.id = 'i18n-cloak';
    st.textContent = 'html.i18n-loading body{visibility:hidden!important}';
    (document.head || document.documentElement).appendChild(st);
    document.documentElement.classList.add('i18n-loading');
    // Never leave the page blank if a dictionary fails to arrive.
    setTimeout(reveal, 1800);
  }
  function reveal() {
    document.documentElement.classList.remove('i18n-loading');
  }

  // ------------------------------------------------------- dictionary load ---

  var pending = {};

  function loadDict(code, cb) {
    if (code === DEFAULT_LANG || dicts[code]) return cb(null);
    if (pending[code]) return pending[code].push(cb);
    pending[code] = [cb];

    var s = document.createElement('script');
    s.src = BASE + code + '.js';
    s.async = true;
    s.onload = function () { flush(code, null); };
    s.onerror = function () {
      dicts[code] = {};                      // fail soft: page stays English
      flush(code, new Error('dictionary ' + code + ' failed to load'));
    };
    (document.head || document.documentElement).appendChild(s);
  }

  function flush(code, err) {
    var q = pending[code] || [];
    delete pending[code];
    q.forEach(function (fn) { try { fn(err); } catch (e) {} });
  }

  // Dictionary files call this.
  function register(code, table) {
    dicts[code] = table || {};
    if (pending[code]) flush(code, null);
  }

  // ------------------------------------------------------------ traversal ---

  var SKIP_TAGS = { SCRIPT: 1, STYLE: 1, CODE: 1, PRE: 1, TEXTAREA: 1, NOSCRIPT: 1, SVG: 1, CANVAS: 1 };
  var ATTRS = ['placeholder', 'title', 'alt', 'aria-label'];

  function skipped(el) {
    for (var n = el; n && n.nodeType === 1; n = n.parentNode) {
      if (SKIP_TAGS[n.tagName]) return true;
      if (n.hasAttribute && n.hasAttribute('data-i18n-skip')) return true;
    }
    return false;
  }

  var norm = function (s) { return s.replace(/\s+/g, ' ').trim(); };

  function translateText(node, table) {
    var original = textOriginals.get(node);
    if (original === undefined) {
      original = node.nodeValue;
      if (!norm(original) || !/[A-Za-z]/.test(original)) return;
      if (skipped(node.parentNode)) return;
      textOriginals.set(node, original);
    }
    var key = norm(original);
    var hit = table[key];
    if (hit === undefined) {
      if (node.nodeValue !== original) node.nodeValue = original;   // reverting
      return;
    }
    // Keep the surrounding whitespace the layout may depend on.
    var lead = (original.match(/^\s*/) || [''])[0];
    var trail = (original.match(/\s*$/) || [''])[0];
    var next = lead + hit + trail;
    if (node.nodeValue !== next) node.nodeValue = next;
  }

  function translateAttrs(el, table) {
    if (skipped(el)) return;
    var saved = attrOriginals.get(el);
    for (var i = 0; i < ATTRS.length; i++) {
      var a = ATTRS[i];
      if (!el.hasAttribute(a)) continue;
      if (!saved) { saved = {}; attrOriginals.set(el, saved); }
      if (saved[a] === undefined) saved[a] = el.getAttribute(a);
      var key = norm(saved[a]);
      if (!key) continue;
      var hit = table[key];
      el.setAttribute(a, hit === undefined ? saved[a] : hit);
    }
  }

  function apply(root, table) {
    // Text nodes.
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null, false);
    var batch = [], n;
    while ((n = walker.nextNode())) batch.push(n);
    for (var i = 0; i < batch.length; i++) translateText(batch[i], table);

    // Attributes.
    var sel = ATTRS.map(function (a) { return '[' + a + ']'; }).join(',');
    var els = root.querySelectorAll ? root.querySelectorAll(sel) : [];
    for (var j = 0; j < els.length; j++) translateAttrs(els[j], table);
    if (root.nodeType === 1 && root.matches && root.matches(sel)) translateAttrs(root, table);
  }

  function applyMeta(table) {
    if (titleOriginal === null) titleOriginal = document.title;
    var t = table[norm(titleOriginal)];
    document.title = t === undefined ? titleOriginal : t;

    var meta = document.querySelector('meta[name="description"]');
    if (meta) {
      var saved = attrOriginals.get(meta);
      if (!saved) { saved = { content: meta.getAttribute('content') }; attrOriginals.set(meta, saved); }
      var d = table[norm(saved.content || '')];
      meta.setAttribute('content', d === undefined ? saved.content : d);
    }
  }

  // ------------------------------------------------------- dynamic content ---

  function startObserver() {
    if (observer || !window.MutationObserver) return;
    observer = new MutationObserver(function (records) {
      if (applying || current === DEFAULT_LANG) return;
      var table = dicts[current] || {};
      applying = true;
      for (var i = 0; i < records.length; i++) {
        var added = records[i].addedNodes;
        for (var j = 0; j < added.length; j++) {
          var node = added[j];
          if (node.nodeType === 3) translateText(node, table);
          else if (node.nodeType === 1) apply(node, table);
        }
      }
      applying = false;
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  // ------------------------------------------------------------- switching ---

  var requestSeq = 0;

  function setLang(code, opts) {
    opts = opts || {};
    if (CODES.indexOf(code) === -1) code = DEFAULT_LANG;

    // Dictionaries load over the network, so a slow one must never overwrite a
    // newer choice made while it was still in flight.
    var mySeq = ++requestSeq;

    loadDict(code, function () {
      if (mySeq !== requestSeq) return;         // superseded by a later switch
      current = code;
      var table = dicts[code] || {};
      applying = true;
      apply(document.body || document.documentElement, table);
      applyMeta(table);
      applying = false;

      document.documentElement.setAttribute('lang', code);
      if (!opts.silent) store(code);
      syncUI();
      reveal();
      startObserver();

      try {
        window.dispatchEvent(new CustomEvent('scooby:langchange', { detail: { lang: code } }));
      } catch (e) {}
    });
  }

  // -------------------------------------------------------------- selector ---

  var CSS = [
    '.i18n-switcher{position:relative;display:inline-flex;flex-shrink:0;font-family:inherit;z-index:1200}',
    '.i18n-switcher *{box-sizing:border-box}',
    '.i18n-toggle{display:inline-flex;align-items:center;gap:7px;padding:7px 11px;border-radius:50px;',
    'border:1px solid rgba(255,255,255,.15);background:rgba(255,255,255,.04);color:#e9e9f1;',
    'font-family:inherit;font-size:.82rem;font-weight:600;letter-spacing:.02em;cursor:pointer;',
    'line-height:1;transition:background .18s,border-color .18s,color .18s;white-space:nowrap}',
    '.i18n-toggle:hover{background:rgba(255,255,255,.09);border-color:rgba(255,255,255,.28);color:#fff}',
    '.i18n-toggle:focus-visible{outline:2px solid #4f8ef5;outline-offset:2px}',
    '.i18n-toggle svg{width:15px;height:15px;flex-shrink:0;stroke:currentColor;fill:none;stroke-width:2}',
    '.i18n-toggle .i18n-caret{width:11px;height:11px;opacity:.65;transition:transform .2s}',
    '.i18n-switcher.open .i18n-toggle .i18n-caret{transform:rotate(180deg)}',
    '.i18n-switcher.open .i18n-toggle{background:rgba(255,255,255,.1);border-color:rgba(255,255,255,.3);color:#fff}',
    '.i18n-menu{position:absolute;top:calc(100% + 9px);left:0;min-width:186px;margin:0;padding:6px;',
    'list-style:none;background:#111114;border:1px solid rgba(255,255,255,.13);border-radius:13px;',
    'box-shadow:0 18px 48px rgba(0,0,0,.62);opacity:0;visibility:hidden;transform:translateY(-6px);',
    'transition:opacity .17s,transform .17s,visibility .17s}',
    '.i18n-switcher.open .i18n-menu{opacity:1;visibility:visible;transform:none}',
    '.i18n-menu li{margin:0;padding:0;list-style:none}',
    '.i18n-option{display:flex;align-items:center;gap:10px;width:100%;padding:9px 11px;border:0;',
    'border-radius:9px;background:transparent;color:#a9a9ba;font-family:inherit;font-size:.87rem;',
    'font-weight:500;text-align:left;cursor:pointer;transition:background .15s,color .15s}',
    '.i18n-option:hover{background:rgba(255,255,255,.06);color:#fff}',
    '.i18n-option[aria-selected="true"]{color:#fff;background:rgba(79,142,245,.14)}',
    '.i18n-badge{display:inline-flex;align-items:center;justify-content:center;min-width:30px;padding:3px 6px;',
    'border-radius:5px;background:rgba(255,255,255,.08);font-size:.68rem;font-weight:700;letter-spacing:.05em;',
    'color:#d5d5e2;flex-shrink:0}',
    '.i18n-option[aria-selected="true"] .i18n-badge{background:rgba(79,142,245,.28);color:#fff}',
    '.i18n-check{margin-left:auto;width:14px;height:14px;stroke:#4f8ef5;fill:none;stroke-width:2.5;opacity:0;flex-shrink:0}',
    '.i18n-option[aria-selected="true"] .i18n-check{opacity:1}',
    // Left group so the selector sits beside the brand without breaking space-between.
    '.i18n-lead{display:flex;align-items:center;gap:14px;flex-shrink:0}',
    // Fallback for pages with no navigation bar.
    '.i18n-floating{position:fixed;top:16px;left:16px;z-index:99999}',
    '.i18n-floating .i18n-toggle{background:rgba(12,12,14,.9);border-color:rgba(255,255,255,.18);',
    'backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px)}',
    '@media (max-width:600px){.i18n-menu{min-width:170px}.i18n-toggle{padding:6px 9px;font-size:.78rem}}'
  ].join('');

  var GLOBE = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9.5"/>' +
              '<path d="M2.5 12h19"/><path d="M12 2.5a15 15 0 0 1 0 19a15 15 0 0 1 0-19z"/></svg>';
  var CARET = '<svg class="i18n-caret" viewBox="0 0 24 24" aria-hidden="true"><polyline points="6 9 12 15 18 9"/></svg>';
  var CHECK = '<svg class="i18n-check" viewBox="0 0 24 24" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>';

  // Ordered by preference; the selector lands in the first container that exists.
  var MOUNTS = ['.nav-inner', '.navbar-inner', '.nav-container', 'nav.navbar',
                '.portal-header .header-inner', 'header.header', '.header-inner'];
  var BRANDS = '.brand, .logo, .navbar-brand-text, .portal-logo, .navbar-brand, .brand-name';

  var root = null;

  function buildSelector() {
    if (document.querySelector('.i18n-switcher')) return;

    var style = document.createElement('style');
    style.id = 'i18n-style';
    style.textContent = CSS;
    (document.head || document.documentElement).appendChild(style);

    root = document.createElement('div');
    root.className = 'i18n-switcher';
    root.setAttribute('data-i18n-skip', '');       // never translate language names

    var toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'i18n-toggle';
    toggle.setAttribute('aria-haspopup', 'listbox');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.setAttribute('aria-label', 'Change language');
    toggle.innerHTML = GLOBE + '<span class="i18n-current">EN</span>' + CARET;

    var menu = document.createElement('ul');
    menu.className = 'i18n-menu';
    menu.setAttribute('role', 'listbox');
    menu.setAttribute('aria-label', 'Select language');

    LANGS.forEach(function (l) {
      var li = document.createElement('li');
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'i18n-option';
      btn.setAttribute('role', 'option');
      btn.setAttribute('data-lang', l.code);
      btn.setAttribute('aria-selected', 'false');
      btn.innerHTML = '<span class="i18n-badge">' + l.label + '</span><span>' + l.native + '</span>' + CHECK;
      btn.addEventListener('click', function () {
        close();
        setLang(l.code);
      });
      li.appendChild(btn);
      menu.appendChild(li);
    });

    root.appendChild(toggle);
    root.appendChild(menu);

    function open() { root.classList.add('open'); toggle.setAttribute('aria-expanded', 'true'); }
    function close() { root.classList.remove('open'); toggle.setAttribute('aria-expanded', 'false'); }

    toggle.addEventListener('click', function (e) {
      e.stopPropagation();
      root.classList.contains('open') ? close() : open();
    });
    document.addEventListener('click', function (e) {
      if (!root.contains(e.target)) close();
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') close();
    });

    mount(root);
    syncUI();
  }

  function mount(el) {
    var host = null;
    for (var i = 0; i < MOUNTS.length; i++) {
      host = document.querySelector(MOUNTS[i]);
      if (host) break;
    }
    if (!host) {                                   // no nav on this page
      el.classList.add('i18n-floating');
      document.body.appendChild(el);
      return;
    }
    // Group the selector with the brand so flex spacing stays intact.
    var brand = host.querySelector(BRANDS);
    if (brand && brand.parentNode === host) {
      var lead = document.createElement('div');
      lead.className = 'i18n-lead';
      host.insertBefore(lead, brand);
      lead.appendChild(el);
      lead.appendChild(brand);
    } else {
      host.insertBefore(el, host.firstChild);
    }
  }

  function syncUI() {
    if (!root) return;
    var meta = LANGS.filter(function (l) { return l.code === current; })[0] || LANGS[0];
    var label = root.querySelector('.i18n-current');
    if (label) label.textContent = meta.label;
    var opts = root.querySelectorAll('.i18n-option');
    for (var i = 0; i < opts.length; i++) {
      opts[i].setAttribute('aria-selected', String(opts[i].getAttribute('data-lang') === current));
    }
  }

  // ------------------------------------------------------------------ boot ---

  hideWhileLoading();

  function boot() {
    buildSelector();
    if (initial !== DEFAULT_LANG) setLang(initial, { silent: true });
    else { current = DEFAULT_LANG; syncUI(); startObserver(); reveal(); }
  }

  // Exported before boot() so a dictionary that lands early can always register.
  window.__scoobyI18n = {
    register: register,
    set: setLang,
    get: function () { return current; },
    langs: LANGS,
    /** Strings on the page with no translation in the active language. */
    missing: function () {
      var table = dicts[current] || {}, out = {}, w = document.createTreeWalker(
        document.body, NodeFilter.SHOW_TEXT, null, false), n;
      while ((n = w.nextNode())) {
        var v = norm(textOriginals.get(n) !== undefined ? textOriginals.get(n) : n.nodeValue);
        if (v && /[A-Za-z]/.test(v) && !skipped(n.parentNode) && table[v] === undefined) out[v] = 1;
      }
      return Object.keys(out);
    }
  };

  // Drain dictionaries that were included manually and arrived first.
  var queued = window.__scoobyI18nQueue;
  if (queued && queued.length) {
    for (var q = 0; q < queued.length; q++) register(queued[q][0], queued[q][1]);
    window.__scoobyI18nQueue = [];
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
