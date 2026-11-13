/*!
 * Scooby site i18n — runtime translation + language selector.
 *
 * Drop this one tag into any page and it handles the rest:
 *   <script src="/lang/i18n.js"></script>
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
    { code: 'en', label: 'EN', native: 'English', flag: 'gb' },
    { code: 'ar', label: 'AR', native: 'العربية', rtl: true, flag: 'sa' },
    { code: 'es', label: 'ES', native: 'Español', flag: 'es' },
    { code: 'pt', label: 'PT', native: 'Português', flag: 'pt' },
    { code: 'pt-br', label: 'BR', native: 'Português (Brasil)', tag: 'pt-BR', flag: 'br' },
    { code: 'fr', label: 'FR', native: 'Français', flag: 'fr' },
    { code: 'de', label: 'DE', native: 'Deutsch', flag: 'de' },
    { code: 'ru', label: 'RU', native: 'Русский', flag: 'ru' },
    { code: 'tr', label: 'TR', native: 'Türkçe', flag: 'tr' },
    { code: 'pl', label: 'PL', native: 'Polski', flag: 'pl' },
    { code: 'it', label: 'IT', native: 'Italiano', flag: 'it' },
    { code: 'zh', label: 'ZH', native: '简体中文', tag: 'zh-Hans', flag: 'cn' },
    { code: 'ja', label: 'JA', native: '日本語', flag: 'jp' },
    { code: 'ko', label: 'KO', native: '한국어', flag: 'kr' },
    { code: 'th', label: 'TH', native: 'ไทย', flag: 'th' },
    { code: 'vi', label: 'VI', native: 'Tiếng Việt', flag: 'vn' },
    { code: 'id', label: 'ID', native: 'Indonesia', flag: 'id' },
    { code: 'hi', label: 'HI', native: 'हिन्दी', flag: 'in' },
    { code: 'sr', label: 'SR', native: 'Српски', flag: 'rs' },
    { code: 'nl', label: 'NL', native: 'Nederlands', flag: 'nl' },
    { code: 'ka', label: 'KA', native: 'ქართული', flag: 'ge' },
    { code: 'uk', label: 'UA', native: 'Українська', flag: 'ua' },
    { code: 'cs', label: 'CS', native: 'Čeština', flag: 'cz' },
    { code: 'sk', label: 'SK', native: 'Slovenčina', flag: 'sk' },
    { code: 'ro', label: 'RO', native: 'Română', flag: 'ro' },
    { code: 'hu', label: 'HU', native: 'Magyar', flag: 'hu' },
    { code: 'el', label: 'EL', native: 'Ελληνικά', flag: 'gr' },
    { code: 'sv', label: 'SV', native: 'Svenska', flag: 'se' },
    { code: 'da', label: 'DA', native: 'Dansk', flag: 'dk' },
    { code: 'fi', label: 'FI', native: 'Suomi', flag: 'fi' },
    { code: 'bg', label: 'BG', native: 'Български', flag: 'bg' },
    { code: 'zh-tw', label: '繁中', native: '繁體中文', tag: 'zh-Hant', flag: 'tw' },
    { code: 'ms', label: 'MS', native: 'Bahasa Melayu', flag: 'my' },
    { code: 'fil', label: 'FIL', native: 'Filipino', flag: 'ph' },
    { code: 'bn', label: 'BN', native: 'বাংলা', flag: 'bd' },
    { code: 'pa', label: 'PA', native: 'ਪੰਜਾਬੀ (ਗੁਰਮੁਖੀ)', tag: 'pa-Guru', flag: 'in' },
    { code: 'jv', label: 'JV', native: 'Basa Jawa', flag: 'id' },
    { code: 'mr', label: 'MR', native: 'मराठी', flag: 'in' },
    { code: 'te', label: 'TE', native: 'తెలుగు', flag: 'in' },
    { code: 'ta', label: 'TA', native: 'தமிழ்', flag: 'in' },
    { code: 'gu', label: 'GU', native: 'ગુજરાતી', flag: 'in' },
    { code: 'kn', label: 'KN', native: 'ಕನ್ನಡ', flag: 'in' },
    { code: 'ml', label: 'ML', native: 'മലയാളം', flag: 'in' },
    { code: 'ne', label: 'NE', native: 'नेपाली', flag: 'np' },
    { code: 'my', label: 'MY', native: 'မြန်မာ', flag: 'mm' },
    { code: 'km', label: 'KM', native: 'ខ្មែរ', flag: 'kh' },
    { code: 'uz', label: 'UZ', native: 'Oʻzbekcha', flag: 'uz' },
    { code: 'az', label: 'AZ', native: 'Azərbaycanca', flag: 'az' },
    { code: 'sw', label: 'SW', native: 'Kiswahili', flag: 'ke' },
    { code: 'ha', label: 'HA', native: 'Hausa', flag: 'ng' },
    { code: 'yo', label: 'YO', native: 'Yorùbá', flag: 'ng' },
    { code: 'am', label: 'AM', native: 'አማርኛ', flag: 'et' },
    { code: 'nb', label: 'NB', native: 'Norsk bokmål', flag: 'no' },
    { code: 'hr', label: 'HR', native: 'Hrvatski', flag: 'hr' },
    { code: 'lt', label: 'LT', native: 'Lietuvių', flag: 'lt' },
    { code: 'ca', label: 'CA', native: 'Català', flag: 'es-ct' },
    { code: 'gl', label: 'GL', native: 'Galego', flag: 'es-ga' },
    { code: 'eu', label: 'EU', native: 'Euskara', flag: 'es-pv' },
    { code: 'is', label: 'IS', native: 'Íslenska', flag: 'is' },
    { code: 'et', label: 'ET', native: 'Eesti', flag: 'ee' },
    { code: 'lv', label: 'LV', native: 'Latviešu', flag: 'lv' },
    { code: 'sl', label: 'SL', native: 'Slovenščina', flag: 'si' },
    { code: 'sq', label: 'SQ', native: 'Shqip', flag: 'al' },
    { code: 'mk', label: 'MK', native: 'Македонски', flag: 'mk' },
    { code: 'be', label: 'BE', native: 'Беларуская', flag: 'by' },
    { code: 'kk', label: 'KK', native: 'Қазақша', flag: 'kz' },
    { code: 'mn', label: 'MN', native: 'Монгол', flag: 'mn' },
    { code: 'si', label: 'SI', native: 'සිංහල', flag: 'lk' },
    { code: 'lo', label: 'LO', native: 'ລາວ', flag: 'la' },
    { code: 'or', label: 'OR', native: 'ଓଡ଼ିଆ', flag: 'in' },
    { code: 'as', label: 'AS', native: 'অসমীয়া', flag: 'in' },
    { code: 'so', label: 'SO', native: 'Soomaali', flag: 'so' },
    { code: 'zu', label: 'ZU', native: 'IsiZulu', flag: 'za' },
    // Right-to-left: these also flip <html dir> and mirror the selector.
    { code: 'he', label: 'HE', native: 'עברית',  rtl: true, flag: 'il' },
    { code: 'ur', label: 'UR', native: 'اردو', rtl: true, flag: 'pk' },
    { code: 'fa', label: 'FA', native: 'فارسی', rtl: true, flag: 'ir' },
    { code: 'ps', label: 'PS', native: 'پښتو', rtl: true, flag: 'af' },
    { code: 'pa-pk', label: 'PK', native: 'پنجابی (شاہ مکھی)', tag: 'pa-Arab', rtl: true, flag: 'pk' }
  ];
  var CODES = LANGS.map(function (l) { return l.code; });

  // Resolve dictionaries and flags from this script's own URL so the code works
  // at any directory depth, and over file:// as well as http://.
  var BASE = (function () {
    var s = document.currentScript;
    if (!s) {
      var all = document.getElementsByTagName('script');
      for (var i = all.length - 1; i >= 0; i--) {
        if (/i18n\.js(\?|$)/.test(all[i].src)) { s = all[i]; break; }
      }
    }
    return s && s.src ? s.src.replace(/[^/]*$/, '') : '/lang/';
  })();

  // ---------------------------------------------------------------- state ---

  var dicts = { en: {} };        // lang -> { english: translated }
  var current = DEFAULT_LANG;
  var textOriginals = new WeakMap();   // text node -> original English
  var textRendered = new WeakMap();
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
    var explicit = document.documentElement.getAttribute('data-site-language');
    if (CODES.indexOf(explicit) !== -1) return explicit;
    var saved = stored();
    if (saved && CODES.indexOf(saved) !== -1) return saved;
    var navLangs = navigator.languages && navigator.languages.length
      ? navigator.languages : [navigator.language || ''];
    for (var i = 0; i < navLangs.length; i++) {
      // Try the full tag first so pt-BR gets Brazilian, not European, Portuguese.
      var full = String(navLangs[i]).toLowerCase();
      if (CODES.indexOf(full) !== -1) return full;
      if (/^zh-(hant|hk|mo|tw)(-|$)/.test(full)) return 'zh-tw';
      if (/^pa-(arab|pk)(-|$)/.test(full) || /^pnb(-|$)/.test(full)) return 'pa-pk';
      var base = full.split('-')[0];
      if (base === 'no') return 'nb';
      if (CODES.indexOf(base) !== -1) return base;
    }
    return null;
  }

  // ------------------------------------------------- anti-flash of English ---
  // Only hide content when we already know a non-English language is coming,
  // so English visitors never pay for this.

  var initial = detect() || DEFAULT_LANG;

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
    dicts[code] = Object.assign({}, table || {}, (window.__scoobyPortalTranslations || {})[code] || {});
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
    if (skipped(node.parentNode)) return;
    var original = textOriginals.get(node);
    if (original !== undefined && textRendered.has(node) && node.nodeValue !== textRendered.get(node)) {
      original = node.nodeValue;
      textOriginals.set(node, original);
    }
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
      textRendered.set(node, original);
      return;
    }
    // Keep the surrounding whitespace the layout may depend on.
    var lead = (original.match(/^\s*/) || [''])[0];
    var trail = (original.match(/\s*$/) || [''])[0];
    var next = lead + hit + trail;
    if (node.nodeValue !== next) node.nodeValue = next;
    textRendered.set(node, next);
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
      if (applying) return;
      var table = dicts[current] || {};
      observer.disconnect();
      applying = true;
      for (var i = 0; i < records.length; i++) {
        if (records[i].type === 'characterData') translateText(records[i].target, table);
        if (records[i].type === 'attributes') {
          var el = records[i].target;
          var saved = attrOriginals.get(el);
          if (saved) delete saved[records[i].attributeName];
          translateAttrs(el, table);
        }
        var added = records[i].addedNodes;
        for (var j = 0; j < added.length; j++) {
          var node = added[j];
          if (node.nodeType === 3) translateText(node, table);
          else if (node.nodeType === 1) apply(node, table);
        }
      }
      applying = false;
      observe();
    });
    observe();
  }

  function observe() {
    if (observer) observer.observe(document.body, { childList: true, characterData: true, attributes: true, attributeFilter: ATTRS, subtree: true });
  }

  // ------------------------------------------------------------- switching ---

  var requestSeq = 0;

  function setLang(code, opts) {
    opts = opts || {};
    if (CODES.indexOf(code) === -1) code = DEFAULT_LANG;
    // Pretranslated homepages switch URLs so static text and metadata agree.
    var explicit = document.documentElement.getAttribute('data-site-language');
    if (explicit && code !== explicit && !opts.silent) {
      store(code);
      window.location.assign(code === DEFAULT_LANG ? '/' : '/lang/' + code + '/');
      return;
    }

    // Dictionaries load over the network, so a slow one must never overwrite a
    // newer choice made while it was still in flight.
    var mySeq = ++requestSeq;

    loadDict(code, function () {
      if (mySeq !== requestSeq) return;         // superseded by a later switch
      current = code;
      var table = dicts[code] || {};
      if (observer) observer.disconnect();
      applying = true;
      apply(document.body || document.documentElement, table);
      applyMeta(table);
      applying = false;

      // Right-to-left scripts need the whole document mirrored, not just translated.
      var meta = LANGS.filter(function (l) { return l.code === code; })[0];
      document.documentElement.setAttribute('lang', meta.tag || code);
      document.documentElement.setAttribute('dir', meta && meta.rtl ? 'rtl' : 'ltr');
      if (!opts.silent) store(code);
      syncUI();
      reveal();
      startObserver();
      observe();

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
    /* Capped so a long language list scrolls instead of running off-screen. */
    '.i18n-menu{--menu-bg:#14161b;--menu-text:#f0f2f6;--menu-muted:#aab3c1;--menu-border:#343844;',
    '--menu-input:#101217;--menu-hover:#232731;--menu-active:#202d42;--menu-accent:#96bafa;',
    'display:none;position:absolute;top:calc(100% + 9px);left:0;bottom:auto;width:min(17.5rem,calc(100vw - 20px));',
    'max-height:min(65dvh,26rem);margin:0;padding:0;overflow:hidden;',
    'background:var(--menu-bg);color:var(--menu-text);border:1px solid var(--menu-border);border-radius:14px;',
    'box-shadow:0 18px 48px #05070b99;transition:none}',
    '.i18n-switcher.open .i18n-menu{display:flex;flex-direction:column}',
    '.i18n-menu::backdrop{background:transparent}',
    '.i18n-menu-head{padding:10px;border-bottom:1px solid var(--menu-border)}',
    '.i18n-menu :is(.i18n-search input,.i18n-option):focus-visible{outline:2px solid var(--menu-accent);outline-offset:-2px}',
    '.i18n-menu .i18n-search input{height:38px;padding-inline:34px 10px;font-size:max(16px,.875rem);',
    'background:var(--menu-input);color:var(--menu-text);border-color:var(--menu-border)}',
    '.i18n-menu .i18n-search input::placeholder{color:var(--menu-muted)}',
    '.i18n-menu .i18n-search svg{inset-inline-start:11px;stroke:var(--menu-muted);width:15px;height:15px}',
    '.i18n-options{min-height:0;overflow-y:auto;overscroll-behavior:contain;scrollbar-width:thin;',
    'scrollbar-color:var(--menu-border) transparent;scrollbar-gutter:stable;margin:0;padding:5px 6px;list-style:none}',
    '.i18n-options li{margin:0;padding:0;list-style:none}',
    '.i18n-option{display:flex;align-items:center;gap:11px;width:100%;min-height:44px;padding:7px 9px;border:0;',
    'border-radius:7px;background:transparent;color:var(--menu-text);font:inherit;',
    'text-align:start;cursor:pointer;transition:background .15s}',
    '.i18n-option:hover,.i18n-option:focus-visible{background:var(--menu-hover)}',
    '.i18n-option[aria-selected="true"]{background:var(--menu-active)}',
    '.i18n-option-copy{display:grid;min-width:0;gap:2px;overflow-wrap:anywhere}',
    '.i18n-option-name{font-size:.86rem;font-weight:650;line-height:1.25}',
    '.i18n-option-hint{font-size:.72rem;color:var(--menu-muted);line-height:1.25}',
    '.i18n-option[aria-selected="true"] .i18n-option-hint{color:var(--menu-text);opacity:.8}',
    '.i18n-menu .i18n-no-results{padding:12px 14px;margin:0;color:var(--menu-muted)}',
    '.i18n-option .i18n-flag{width:24px;height:17px}',
    /* Local SVG flags render consistently across operating systems. */
    '.i18n-flag{display:inline-block;width:20px;height:14px;border-radius:2.5px;overflow:hidden;',
    'flex-shrink:0;line-height:0;box-shadow:0 0 0 1px rgba(255,255,255,.14) inset}',
    '.i18n-flag{object-fit:fill;vertical-align:middle}',
    '.i18n-toggle .i18n-flag{width:19px;height:13px}',
    '.i18n-check{margin-inline-start:auto;width:14px;height:14px;stroke:var(--menu-accent);fill:none;stroke-width:2.5;opacity:0;flex-shrink:0}',
    '.i18n-option[aria-selected="true"] .i18n-check{opacity:1}',
    // Left group so the selector sits beside the brand without breaking space-between.
    '.i18n-lead{display:flex;align-items:center;gap:14px;flex-shrink:0}',
    // Fallback for pages with no navigation bar.
    '.i18n-floating{position:fixed;top:16px;left:16px;z-index:99999}',
    '.i18n-floating .i18n-toggle{background:rgba(12,12,14,.9);border-color:rgba(255,255,255,.18);',
    'backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px)}',
    '@media (max-width:600px){.i18n-toggle{padding:6px 9px;font-size:.78rem}}',
    // A selector at the end of its row opens its menu toward the start.
    '.i18n-end .i18n-menu{left:auto;right:0}',
    // Wiki header: sits with the theme control and follows the wiki's light/dark colours.
    '.wiki-header .i18n-toggle,.wiki-header .i18n-toggle:hover,.wiki-header .i18n-switcher.open .i18n-toggle{',
    'color:var(--text);background:var(--bg);border-color:var(--border)}',
    '.wiki-header .i18n-toggle:hover,.wiki-header .i18n-switcher.open .i18n-toggle{border-color:var(--accent)}',
    '.wiki-header .i18n-menu{--menu-bg:var(--header);--menu-text:var(--text);--menu-muted:var(--muted);',
    '--menu-border:var(--border);--menu-input:var(--bg);--menu-hover:var(--soft);--menu-active:var(--soft);--menu-accent:var(--accent)}',
    '@media (max-width:600px){.wiki-header .i18n-current{display:none}}',
    // API reference sidebar: the brand and the selector share the brand's underline.
    'aside.sidebar>.i18n-row{display:flex;align-items:center;gap:10px;',
    'border-bottom:1px solid var(--border);margin-bottom:10px}',
    'aside.sidebar>.i18n-row>.brand{flex:1;min-width:0;border-bottom:0;margin-bottom:0}',
    'aside.sidebar>.i18n-row>.i18n-switcher{margin:0 4px 8px 0}',
    // Native references: docked at the end of the fixed header, and the search
    // box gives up that much room. At 900px and below the header stacks, so the
    // selector sits beside the (narrow, centred) search box instead.
    '.i18n-floating.i18n-docked{top:8px;left:auto;right:12px}',
    '@media (min-width:901px){html.i18n-dock-next #__next>header input{margin-right:calc(var(--i18n-dock-w,90px) + 24px)}}',
    '@media (max-width:900px){.i18n-floating.i18n-docked{top:61px;right:10px}.i18n-docked .i18n-current{display:none}}',

    /* ---- right-to-left ---- */
    /* The dropdown and the floating pill are anchored with `left`, which has to
       flip so the menu stays inside the viewport when the page is mirrored. */
    '[dir="rtl"] .i18n-menu{left:auto;right:0}',
    '[dir="rtl"] .i18n-floating{left:auto;right:16px}',
    '[dir="rtl"] .i18n-end .i18n-menu{right:auto;left:0}',
    '[dir="rtl"] .i18n-floating.i18n-docked{right:auto;left:12px}',
    '[dir="rtl"] aside.sidebar>.i18n-row>.i18n-switcher{margin:0 0 8px 4px}',
    '@media (min-width:901px){html[dir="rtl"].i18n-dock-next #__next>header input{',
    'margin-right:16px;margin-left:calc(var(--i18n-dock-w,90px) + 24px)}}',
    '@media (max-width:900px){[dir="rtl"] .i18n-floating.i18n-docked{left:10px}}',
    /* Language names stay in their own script and direction. */
    '.i18n-option,.i18n-pick{unicode-bidi:isolate}',

    /* ---- first-visit language picker ---- */
    '.i18n-modal-overlay{box-sizing:border-box;position:fixed;inset:0;margin:auto;padding:0;',
    'width:min(49rem,calc(100% - 32px));max-width:none;max-height:none;border:1px solid #333640;',
    'border-radius:20px;background:#14161b;color:#f0f2f6;overflow:hidden;color-scheme:dark;',
    'box-shadow:0 26px 90px #05070ba6;font-family:inherit}',
    '.i18n-modal-overlay::backdrop{background:#06080bc9;backdrop-filter:blur(8px)}',
    '.i18n-modal{display:flex;flex-direction:column;height:min(43rem,calc(100dvh - 46px))}',
    '.i18n-modal-head{padding:24px 26px 16px}',
    '.i18n-modal-heading{display:flex;align-items:center;gap:14px;margin-bottom:18px}',
    '.i18n-modal-heading svg{box-sizing:content-box;width:20px;height:20px;padding:10px;border-radius:10px;',
    'background:#202b3c;color:#9bbdf6;stroke:currentColor;fill:none;stroke-width:1.65;flex:none}',
    '.i18n-modal h2{margin:0;color:#f7f8fb;font-size:clamp(1.3rem,3vw,1.75rem);font-weight:750;',
    'letter-spacing:-.035em;line-height:1.15;outline:none}',
    '.i18n-search{position:relative;display:block}',
    '.i18n-search svg{position:absolute;inset-inline-start:14px;top:50%;width:17px;height:17px;transform:translateY(-50%);',
    'fill:none;stroke:#a8b0bf;stroke-width:1.7;pointer-events:none}',
    '.i18n-search input{display:block;box-sizing:border-box;width:100%;height:44px;margin:0;padding:0 13px 0 40px;',
    'border:1px solid #363b46;border-radius:9px;background:#101217;color:#f1f4fa;font:inherit;font-size:1rem}',
    '.i18n-search input::placeholder{color:#a1a9b6}',
    '.i18n-modal :is(input,button):focus-visible{outline:2px solid #8ab3ff;outline-offset:2px}',
    '.i18n-results{min-height:0;flex:1;overflow-y:auto;overscroll-behavior:contain;scrollbar-gutter:stable;',
    'padding:4px 22px 14px 26px}',
    '.i18n-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:3px 8px}',
    '.i18n-pick{display:flex;align-items:center;gap:11px;min-height:53px;padding:8px 10px;overflow-wrap:anywhere;',
    'border:1px solid transparent;border-radius:8px;background:none;color:#f0f2f6;',
    'font:inherit;line-height:1.3;cursor:pointer;text-align:left;transition:background .15s,border-color .15s}',
    '.i18n-pick[hidden],.i18n-no-results[hidden]{display:none}',
    '.i18n-pick:hover,.i18n-pick:focus-visible{background:#232731}',
    '.i18n-pick.suggested{background:#202b3c;border-color:#405a82}',
    '.i18n-pick .i18n-flag{width:25px;height:18px;border-radius:3px}',
    '.i18n-pick-copy{display:grid;min-width:0;gap:2px}',
    '.i18n-pick-name{font-size:.9rem;font-weight:650}',
    '.i18n-pick-hint{color:#aab3c1;font-size:.73rem}',
    '.i18n-pick.suggested .i18n-pick-hint{color:#b5d0ff}',
    '.i18n-no-results{margin:22px 10px;color:#b5bdca;font-size:.9rem}',
    '.i18n-modal-foot{display:flex;align-items:center;justify-content:space-between;gap:12px;',
    'border-top:1px solid #2c3039;padding:9px 26px;color:#aab3c1;font-size:.8rem}',
    '.i18n-dismiss{min-height:44px;padding:0 10px;border:0;border-radius:7px;background:none;',
    'color:#c5d9fb;font:inherit;font-weight:650;cursor:pointer}',
    '.i18n-dismiss:hover{background:#212a38}',
    '@media(max-width:660px){.i18n-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}',
    '@media(max-width:460px){.i18n-modal-overlay{width:calc(100% - 20px);border-radius:16px}',
    '.i18n-modal{height:min(43rem,calc(100dvh - 22px))}.i18n-modal-head{padding:16px 14px 12px}',
    '.i18n-results{padding-inline:12px 8px}.i18n-modal-foot{padding-inline:14px}.i18n-pick{gap:8px;padding-inline:7px}}',
    '@media(prefers-reduced-motion:reduce){.i18n-pick,.i18n-option{transition:none}}'
  ].join('');

  var GLOBE = '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9.5"/>' +
              '<path d="M2.5 12h19"/><path d="M12 2.5a15 15 0 0 1 0 19a15 15 0 0 1 0-19z"/></svg>';

  var SEARCH = '<label class="i18n-search"><svg viewBox="0 0 24 24" aria-hidden="true">' +
    '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4 4"/></svg>' +
    '<input type="search" aria-label="Search languages" placeholder="Search languages" autocomplete="off"></label>';
  var englishNames = new Intl.DisplayNames(['en'], { type: 'language' });

  function flagHTML(language, lazy) {
    return '<img class="i18n-flag" src="' + BASE + 'flags/' + language.flag + '.svg" alt="" draggable="false"' +
      (lazy ? ' loading="lazy"' : '') + '>';
  }

  var CARET = '<svg class="i18n-caret" viewBox="0 0 24 24" aria-hidden="true"><polyline points="6 9 12 15 18 9"/></svg>';
  var CHECK = '<svg class="i18n-check" viewBox="0 0 24 24" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>';

  // Ordered by preference; the selector lands in the first container that exists.
  var MOUNTS = ['.nav-inner', '.navbar-inner', '.nav-container', 'nav.navbar',
                '.portal-header .header-inner', 'header.header', '.header-inner',
                '.site-header'];
  // Headers with a group of controls on the right (the wiki's search/theme bar):
  // the selector joins that group rather than crowding the brand.
  var END_SLOTS = ['.wiki-header .header-actions'];
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
    toggle.setAttribute('aria-haspopup', 'dialog');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.setAttribute('aria-label', 'Change language');
    toggle.innerHTML = '<span class="i18n-toggle-flag">' + flagHTML(LANGS[0]) + '</span>' +
                       '<span class="i18n-current">EN</span>' + CARET;

    var menu = document.createElement('div');
    menu.className = 'i18n-menu';
    menu.id = 'site-language-options';
    toggle.setAttribute('aria-controls', menu.id);
    var usePopover = typeof menu.showPopover === 'function';
    if (usePopover) menu.setAttribute('popover', 'manual');
    menu.setAttribute('role', 'dialog');
    menu.innerHTML = '<div class="i18n-menu-head">' + SEARCH + '</div>' +
      '<ul class="i18n-options" role="listbox" aria-label="Select language"></ul>' +
      '<p class="i18n-no-results" role="status" hidden>No languages found.</p>';
    var list = menu.querySelector('.i18n-options');
    var search = menu.querySelector('input');
    var empty = menu.querySelector('.i18n-no-results');
    var choices = [];

    LANGS.forEach(function (l) {
      var li = document.createElement('li');
      li.setAttribute('role', 'presentation');
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'i18n-option';
      btn.setAttribute('role', 'option');
      btn.setAttribute('data-lang', l.code);
      btn.setAttribute('aria-selected', 'false');
      btn.tabIndex = -1;
      btn.innerHTML = flagHTML(l, true) + '<span class="i18n-option-copy">' +
        '<bdi class="i18n-option-name" lang="' + (l.tag || l.code) + '" dir="' + (l.rtl ? 'rtl' : 'ltr') + '"></bdi>' +
        '<span class="i18n-option-hint" lang="en"></span></span>' + CHECK;
      var englishName = englishNames.of(l.tag || l.code);
      btn.querySelector('.i18n-option-name').textContent = l.native;
      var hint = btn.querySelector('.i18n-option-hint');
      hint.textContent = englishName;
      hint.hidden = englishName === l.native;
      btn.addEventListener('click', function () {
        close();
        toggle.focus();
        setLang(l.code);
      });
      li.appendChild(btn);
      list.appendChild(li);
      choices.push({ row: li, button: btn, text: languageSearchKey(l, englishName) });
    });

    root.appendChild(toggle);
    root.appendChild(menu);

    function open(focusSearch) {
      search.value = '';
      filter();
      root.classList.add('open'); toggle.setAttribute('aria-expanded', 'true');
      positionMenu();
      if (usePopover) menu.showPopover();
      if (focusSearch) {
        search.focus({ preventScroll: true });
        return;
      }
      var selected = list.querySelector('[aria-selected="true"]') || choices[0].button;
      selected.focus({ preventScroll: true });
      selected.scrollIntoView({ block: 'nearest' });
    }
    function close() {
      if (usePopover && menu.matches(':popover-open')) menu.hidePopover();
      root.classList.remove('open'); toggle.setAttribute('aria-expanded', 'false');
    }

    function positionMenu() {
      if (!usePopover) return;
      var r = toggle.getBoundingClientRect();
      var viewport = window.visualViewport;
      var screenWidth = viewport ? viewport.width : window.innerWidth;
      var screenHeight = viewport ? viewport.height : window.innerHeight;
      var viewLeft = viewport ? viewport.offsetLeft : 0;
      var viewTop = viewport ? viewport.offsetTop : 0;
      var width = Math.min(280, screenWidth - 20);
      var rtl = getComputedStyle(root).direction === 'rtl';
      var alignRight = rtl !== root.classList.contains('i18n-end');
      var below = viewTop + screenHeight - r.bottom - 19;
      var above = r.top - viewTop - 19;
      var openAbove = below < 210 && above > below;
      menu.style.position = 'fixed';
      menu.style.width = width + 'px';
      menu.style.left = Math.max(viewLeft + 10, Math.min(alignRight ? r.right - width : r.left, viewLeft + screenWidth - width - 10)) + 'px';
      menu.style.right = 'auto';
      menu.style.top = openAbove ? 'auto' : (r.bottom + 9) + 'px';
      menu.style.bottom = openAbove ? (window.innerHeight - r.top + 9) + 'px' : 'auto';
      menu.style.maxHeight = Math.max(0, Math.min(openAbove ? above : below, 416)) + 'px';
    }

    function filter() {
      var query = searchTerms(search.value);
      var shown = choices.filter(function (choice) {
        var match = matchesSearch(choice.text, query);
        choice.row.hidden = !match;
        return match;
      });
      empty.hidden = shown.length > 0;
      list.scrollTop = 0;
    }

    search.addEventListener('input', filter);
    toggle.addEventListener('click', function (e) {
      e.stopPropagation();
      if (root.classList.contains('open')) { close(); return; }
      open(e.detail === 0);
    });
    function reposition() { if (root.classList.contains('open')) positionMenu(); }
    window.addEventListener('resize', reposition);
    if (window.visualViewport) window.visualViewport.addEventListener('resize', reposition);
    window.addEventListener('scroll', function (e) {
      // Capture also receives the language list's own scroll events.
      if (menu.contains(e.target)) return;
      if (root.classList.contains('open')) close();
    }, true);
    document.addEventListener('click', function (e) {
      if (!root.contains(e.target)) close();
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && root.classList.contains('open')) { e.preventDefault(); close(); toggle.focus(); }
    });
    toggle.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') { e.preventDefault(); open(); }
    });
    menu.addEventListener('keydown', function (e) {
      var options = choices.filter(function (choice) { return !choice.row.hidden; }).map(function (choice) { return choice.button; });
      var index = options.indexOf(document.activeElement), next;
      if (document.activeElement === search) {
        if (options.length && (e.key === 'ArrowDown' || e.key === 'ArrowUp' || (e.key === 'Enter' && options.length === 1))) {
          e.preventDefault();
          if (e.key === 'Enter') options[0].click();
          else options[e.key === 'ArrowUp' ? options.length - 1 : 0].focus();
        }
        return;
      }
      if (e.key === 'Tab' && e.shiftKey) { e.preventDefault(); search.focus(); return; }
      if (e.key === 'ArrowDown') next = (index + 1) % options.length;
      if (e.key === 'ArrowUp') next = (index + options.length - 1) % options.length;
      if (e.key === 'Home') next = 0;
      if (e.key === 'End') next = options.length - 1;
      if (next !== undefined) { e.preventDefault(); options[next].focus(); }
      if (e.key === 'Tab') { close(); toggle.focus(); }
    });
    document.addEventListener('focusin', function (e) {
      if (!root.contains(e.target)) close();
    });

    mount(root);
    syncUI();
  }

  function mount(el) {
    var host = null;
    var portalBrand = document.querySelector('.portal-modern .header-top > .portal-logo');
    if (portalBrand) {
      var portalLead = document.createElement('div');
      portalLead.className = 'i18n-lead';
      portalBrand.parentNode.insertBefore(portalLead, portalBrand);
      portalLead.appendChild(portalBrand);
      portalLead.appendChild(el);
      return;
    }
    for (var s = 0; s < END_SLOTS.length; s++) {
      host = document.querySelector(END_SLOTS[s]);
      if (host) {
        el.classList.add('i18n-end');
        host.insertBefore(el, host.firstChild);
        return;
      }
    }
    // The API references' sidebar opens with a block-level brand. Put the brand
    // and the selector on one row, with the selector at the far end.
    var sideBrand = document.querySelector('aside.sidebar > .brand');
    if (sideBrand) {
      var row = document.createElement('div');
      row.className = 'i18n-row';
      sideBrand.parentNode.insertBefore(row, sideBrand);
      row.appendChild(sideBrand);
      row.appendChild(el);
      el.classList.add('i18n-end');
      return;
    }
    // The native references are a React app that owns its header, so anything
    // inserted there could be dropped when it hydrates. Keep the selector
    // outside the app and dock it into room the header leaves free for it.
    if (document.querySelector('#__next > header')) {
      el.classList.add('i18n-floating', 'i18n-docked', 'i18n-end');
      document.documentElement.classList.add('i18n-dock-next');
      document.body.appendChild(el);
      window.addEventListener('resize', reserveDock);
      return;
    }
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
    var t = window.__scoobyI18n.t;
    root.querySelector('.i18n-toggle').setAttribute('aria-label', t('Change language'));
    root.querySelector('.i18n-menu').setAttribute('aria-label', t('Select language'));
    root.querySelector('.i18n-options').setAttribute('aria-label', t('Languages'));
    var search = root.querySelector('.i18n-search input');
    var searchLabel = t('Search languages');
    search.setAttribute('aria-label', searchLabel);
    search.placeholder = searchLabel;
    root.querySelector('.i18n-no-results').textContent = t('No languages found.');
    var meta = LANGS.filter(function (l) { return l.code === current; })[0] || LANGS[0];
    var label = root.querySelector('.i18n-current');
    if (label) label.textContent = meta.label;
    var tf = root.querySelector('.i18n-toggle-flag');
    if (tf) tf.innerHTML = flagHTML(meta);
    var opts = root.querySelectorAll('.i18n-option');
    for (var i = 0; i < opts.length; i++) {
      opts[i].setAttribute('aria-selected', String(opts[i].getAttribute('data-lang') === current));
    }
    reserveDock();
  }

  // A docked selector is out of the header's flow; tell the header how much
  // room to leave. Its width changes with the language and the breakpoint.
  function reserveDock() {
    if (root && root.classList.contains('i18n-docked')) {
      document.documentElement.style.setProperty('--i18n-dock-w', root.offsetWidth + 'px');
    }
  }

  // Shared search for the header and first-visit language pickers.
  function searchKey(text) {
    // Strip accents from Latin text without changing vowel marks in other scripts.
    return text.toLowerCase().normalize('NFD').replace(/(\p{Script=Latin})\p{M}+/gu, '$1').normalize('NFC');
  }

  function languageSearchKey(language, englishName) {
    return searchKey([language.native, englishName, language.code, language.tag || ''].join(' '));
  }

  function searchTerms(text) {
    return searchKey(text.trim()).split(/\s+/);
  }

  function matchesSearch(text, terms) {
    return terms.every(function (term) { return text.indexOf(term) !== -1; });
  }

  // ------------------------------------------------- first-visit picker ---

  var picker = null;

  function showPicker(force) {
    if (picker) return;
    var suggested = detect();
    // Ask only when neither the page, a saved choice, nor the browser picks a supported language.
    if (!force && suggested) return;

    picker = document.createElement('dialog');
    picker.className = 'i18n-modal-overlay';
    picker.setAttribute('data-i18n-skip', '');
    picker.setAttribute('aria-labelledby', 'i18n-picker-title');
    picker.setAttribute('lang', 'en');
    picker.setAttribute('dir', 'ltr');

    var box = document.createElement('div');
    box.className = 'i18n-modal';

    box.innerHTML = '<header class="i18n-modal-head"><div class="i18n-modal-heading">' + GLOBE +
      '<h2 id="i18n-picker-title" tabindex="-1" autofocus>Choose your language</h2></div>' +
      SEARCH + '</header>' +
      '<div class="i18n-results"><div class="i18n-grid"></div>' +
      '<p class="i18n-no-results" hidden>No languages found.</p></div>' +
      '<footer class="i18n-modal-foot"><span role="status"></span>' +
      '<button type="button" class="i18n-dismiss">Continue in English</button></footer>';

    var grid = box.querySelector('.i18n-grid');
    var results = box.querySelector('.i18n-results');
    var empty = box.querySelector('.i18n-no-results');
    var count = box.querySelector('[role="status"]');
    var search = box.querySelector('input');
    var choices = [];
    LANGS.forEach(function (l) {
      var isSuggested = l.code === suggested && suggested !== DEFAULT_LANG;
      var englishName = englishNames.of(l.tag || l.code);
      var button = document.createElement('button');
      button.type = 'button';
      button.className = 'i18n-pick' + (isSuggested ? ' suggested' : '');
      button.dataset.lang = l.code;
      button.innerHTML = flagHTML(l) + '<span class="i18n-pick-copy">' +
        '<bdi class="i18n-pick-name" lang="' + (l.tag || l.code) + '" dir="' + (l.rtl ? 'rtl' : 'ltr') + '"></bdi>' +
        '<span class="i18n-pick-hint"></span></span>';
      button.querySelector('.i18n-pick-name').textContent = l.native;
      var hint = button.querySelector('.i18n-pick-hint');
      hint.textContent = [englishName !== l.native ? englishName : '', isSuggested ? 'Suggested' : ''].filter(Boolean).join(' · ');
      hint.hidden = !hint.textContent;
      grid.appendChild(button);
      choices.push({ button: button, text: languageSearchKey(l, englishName) });
    });

    picker.appendChild(box);
    document.body.appendChild(picker);

    var prevOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    function close(code) {
      document.body.style.overflow = prevOverflow;
      picker.close();
      picker.remove();
      picker = null;
      setLang(code, {});
    }

    function filter() {
      var query = searchTerms(search.value);
      var visible = choices.filter(function (choice) {
        var matches = matchesSearch(choice.text, query);
        choice.button.hidden = !matches;
        return matches;
      });
      count.textContent = visible.length + (visible.length === 1 ? ' language' : ' languages');
      empty.hidden = visible.length > 0;
      results.scrollTop = 0;
    }

    search.addEventListener('input', filter);
    search.addEventListener('keydown', function (e) {
      if (e.key !== 'ArrowDown' && e.key !== 'Enter') return;
      var first = grid.querySelector('button:not([hidden])');
      if (!first) return;
      e.preventDefault();
      if (e.key === 'Enter' && search.value.trim()) first.click();
      else first.focus();
    });
    box.addEventListener('click', function (e) {
      var pick = e.target.closest ? e.target.closest('.i18n-pick') : null;
      if (pick) { close(pick.getAttribute('data-lang')); return; }
      if (e.target.closest && e.target.closest('.i18n-dismiss')) close(DEFAULT_LANG);
    });
    picker.addEventListener('click', function (e) {
      if (e.target === picker) close(current);
    });
    picker.addEventListener('cancel', function (e) {
      e.preventDefault();
      close(current);
    });

    filter();
    // The heading receives focus first so phones do not open their keyboard on arrival.
    picker.showModal();
  }

  // ------------------------------------------------------------------ boot ---

  hideWhileLoading();

  function boot() {
    buildSelector();
    if (initial !== DEFAULT_LANG) setLang(initial, { silent: true });
    else { current = DEFAULT_LANG; syncUI(); startObserver(); reveal(); }
    showPicker();
  }

  // Exported before boot() so a dictionary that lands early can always register.
  window.__scoobyI18n = {
    register: register,
    t: function (key, params) {
      var value = (dicts[current] || {})[key] || key;
      return value.replace(/\{(\w+)\}/g, function (match, name) {
        return params && params[name] !== undefined ? String(params[name]) : match;
      });
    },
    set: setLang,
    get: function () { return current; },
    langs: LANGS,
    /** Re-open the language picker. */
    showPicker: function () { showPicker(true); },
    /** Forget the saved choice so the next page load uses browser detection. */
    reset: function () { try { localStorage.removeItem(STORAGE_KEY); } catch (e) {} },
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
