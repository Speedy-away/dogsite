/*
 * Checks every dictionary against the strings actually present on the site.
 *
 *   node tools/i18n-verify.js          summarize every language
 *   node tools/i18n-verify.js ca       show gaps for a specific language
 *
 * Reports:
 *   - unmatched keys : dictionary entries absent from source HTML
 *   - untranslated   : site strings with no entry, worst-covered pages first
 *   - coverage       : per language, share of site strings translated
 */
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const I18N_DIR = path.join(ROOT, 'lang');

// ---- collect the site's real strings (same rules as i18n-extract.js) --------
const { collect } = require('./i18n-extract.js');
const site = collect(ROOT);
const siteKeys = new Set(site.map(e => e.text));
// The shared selector looks these up after creating its controls.
const selectorKeys = new Set(['Change language', 'Select language']);

// ---- load each dictionary in a sandbox -------------------------------------
function loadDict(code) {
  const sandbox = { window: {} };
  vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(I18N_DIR, code + '.js'), 'utf8'), sandbox);
  const q = sandbox.window.__scoobyI18nQueue || [];
  const hit = q.find(p => p[0] === code);
  if (!hit) throw new Error(code + '.js did not register a dictionary');
  return hit[1];
}

let codes = fs.readdirSync(I18N_DIR)
  .filter(f => /^[a-z]{2,3}(-[a-z]{2})?\.js$/.test(f))
  .map(f => f.replace('.js', ''));

const requestedCode = process.argv[2];
if (requestedCode) {
  if (!codes.includes(requestedCode)) {
    console.error('Unknown locale: ' + requestedCode);
    process.exit(1);
  }
  codes = [requestedCode];
}

console.log('site strings:', siteKeys.size, '\n');

let anyDead = false;
const perLang = {};
const homepageKeys = site.filter(entry => entry.files.includes('index.html')).map(entry => entry.text);

for (const code of codes) {
  const dict = loadDict(code);
  const keys = Object.keys(dict);
  const dead = keys.filter(k => !siteKeys.has(k) && !selectorKeys.has(k));
  const covered = keys.filter(k => siteKeys.has(k));
  perLang[code] = new Set(covered);

  const pct = ((covered.length / siteKeys.size) * 100).toFixed(1);
  const homepageCovered = homepageKeys.filter(key => perLang[code].has(key)).length;
  console.log(code.toUpperCase() + ':', String(keys.length).padStart(4), 'entries,',
              String(covered.length).padStart(4), 'match site (' + pct + '%),',
              homepageCovered + '/' + homepageKeys.length + ' homepage keys');

  if (dead.length) {
    anyDead = true;
    console.log('   ' + dead.length + ' key(s) absent from source HTML');
    if (requestedCode) {
      dead.slice(0, 25).forEach(k => console.log('     ' + JSON.stringify(k)));
      if (dead.length > 25) console.log('     ... and ' + (dead.length - 25) + ' more');
    }
  }
  // Empty values cannot provide a translation.
  const empty = keys.filter(k => !dict[k] || !String(dict[k]).trim());
  if (empty.length) console.log('   ' + empty.length + ' EMPTY value(s):', empty.slice(0, 8));
}

if (requestedCode) {
  const missing = site.filter(entry => !perLang[requestedCode].has(entry.text));
  const byPage = {};
  for (const entry of missing) {
    for (const file of entry.files) byPage[file] = (byPage[file] || 0) + 1;
  }
  console.log('\nuntranslated in ' + requestedCode + ': ' + missing.length + ' candidate strings');
  console.log('pages with the most missing entries:');
  Object.entries(byPage).sort((a, b) => b[1] - a[1]).slice(0, 12)
    .forEach(([file, count]) => console.log(String(count).padStart(6), file));
}

process.exit(anyDead ? 1 : 0);
