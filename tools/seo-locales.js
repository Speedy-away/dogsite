/* Generate every localized homepage from the complete English homepage. */
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { chromium } = require('playwright');
const locales = require('./search-locales.json');
const { applyMetadata } = require('./seo-metadata');
const ROOT = path.resolve(__dirname, '..');
const apply = process.argv.includes('--apply');
const escape = value => value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const languageLinks = (code = 'en') => [['en', { tag:'en', native:'English' }], ...Object.entries(locales)].map(([key, locale]) =>
  `<a href="${key === 'en' ? '/' : '/lang/' + key + '/'}" lang="${locale.tag}" hreflang="${locale.tag}" data-site-language="${key}"${code === key ? ' aria-current="page"' : ''}>${escape(locale.native)}</a>`).join('\n');
let stale = 0;
function output(file, html) {
  const target = path.join(ROOT, file);
  const old = fs.existsSync(target) ? fs.readFileSync(target, 'utf8').replace(/\r\n/g, '\n') : '';
  if (old === html) return;
  stale++;
  if (apply) { fs.mkdirSync(path.dirname(target), { recursive:true }); fs.writeFileSync(target, html); }
  else console.log('Stale: ' + file);
}
async function main() {
  let home = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8').replace(/\r\n/g, '\n');
  const block = '<!-- BEGIN SEARCH LANGUAGES -->\n<details class="footer-languages" data-i18n-skip><summary>Languages</summary><nav class="language-links" aria-label="Languages">' + languageLinks() + '</nav></details>\n<!-- END SEARCH LANGUAGES -->';
  home = home.replace(/<!-- BEGIN SEARCH LANGUAGES -->[\s\S]*?<!-- END SEARCH LANGUAGES -->/, block);
  home = applyMetadata('index.html', home);
  output('index.html', home);
  // DOMParser is inert: homepage scripts and network requests never run at build time.
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  try {
    const page = await browser.newPage();
    for (const [code, locale] of Object.entries(locales)) {
      const context = { window: {} };
      vm.runInNewContext(fs.readFileSync(path.join(ROOT, 'lang', code + '.js'), 'utf8'), context);
      const dictionary = context.window.__scoobyI18nQueue.find(([key]) => key === code)?.[1];
      if (!dictionary) throw Error('Missing dictionary: ' + code);
      const html = await page.evaluate(({ home, code, locale, dictionary, links }) => {
        const doc = new DOMParser().parseFromString(home, 'text/html');
        doc.documentElement.setAttribute('lang', locale.tag);
        doc.documentElement.setAttribute('dir', locale.rtl ? 'rtl' : 'ltr');
        doc.documentElement.setAttribute('data-site-language', code);
        const skip = 'script,style,code,pre,textarea,noscript,svg,canvas,[data-i18n-skip],[translate="no"]';
        const norm = text => text.replace(/\s+/g, ' ').trim();
        const walker = doc.createTreeWalker(doc.body, NodeFilter.SHOW_TEXT);
        let node;
        while ((node = walker.nextNode())) {
          if (node.parentElement.closest(skip)) continue;
          const value = dictionary[norm(node.nodeValue)];
          if (value !== undefined) node.nodeValue = node.nodeValue.match(/^\s*/)[0] + value + node.nodeValue.match(/\s*$/)[0];
        }
        for (const el of doc.body.querySelectorAll('[placeholder],[title],[alt],[aria-label]')) {
          if (el.closest(skip)) continue;
          for (const attr of ['placeholder', 'title', 'alt', 'aria-label']) {
            const value = dictionary[norm(el.getAttribute(attr) || '')];
            if (value !== undefined) el.setAttribute(attr, value);
          }
        }
        doc.querySelector('.hero .lead').textContent = locale.intro;
        doc.querySelector('.footer-languages .language-links').innerHTML = links;
        // Root homepage entity URLs must not leak into localized structured data.
        for (const script of doc.querySelectorAll('script[type="application/ld+json"]')) script.remove();
        return '<!DOCTYPE html>\n' + doc.documentElement.outerHTML + '\n';
      }, { home, code, locale, dictionary, links: languageLinks(code) });
      const file = 'lang/' + code + '/index.html';
      output(file, applyMetadata(file, html));
    }
  } finally { await browser.close(); }
  console.log(`${Object.keys(locales).length} full-layout translated homepages; ${stale} ${apply ? 'updated' : 'stale'}.`);
  if (stale && !apply) process.exitCode = 1;
}
main().catch(error => { console.error(error); process.exitCode = 1; });
