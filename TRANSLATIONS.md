# Languages and translations

The site supports **22 language options**: English, Spanish, Portuguese, Brazilian Portuguese, French, German, Russian, Turkish, Polish, Italian, Simplified Chinese, Japanese, Korean, Thai, Vietnamese, Indonesian, Hindi, Serbian, Dutch, Georgian, Arabic and Hebrew.

## Searchable homepages

English uses `/`. Each other language has its own static homepage under `lang/`, such as `/lang/es/`, `/lang/pt-br/`, `/lang/th/` or `/lang/ar/`. The old root addresses (`/es/` and so on) forward there through `404.html`. The introduction, navigation and resource text are translated in the HTML, so they work without JavaScript. Game names and product brands remain unchanged.

Each homepage has a localized title and description, a self-canonical URL, and reciprocal hreflang links to all homepages. English is the x-default fallback. The sitemap and site directory include these pages. Arabic and Hebrew use right-to-left layouts.

This does **not** mean every product page, feature list or guide is fully translated. The localized homepages say that some detailed content is in English. Detailed pages continue to use the existing translation dictionaries, with English fallback for unmatched strings.

Translation sources:

- `tools/search-locales.json`: language tags, native names, translated titles, introductions and explanatory text.
- `lang/<code>.js`: existing navigation and UI dictionaries, also reused when building the homepages.
- `tools/seo-locales.js`: static homepage generator and native-language links in the English footer.
- `assets/js/language-home.js`: remembers a visited language URL for the existing page translator.
- `assets/css/language-home.css`: responsive language homepage and footer styles.

Run from the repository root after editing translation sources:

```sh
node tools/seo-locales.js --apply
node tools/seo-directory.js --apply
node tools/seo-metadata.js --apply
node --test tools/seo.test.js
node tools/seo-locales.js
node tools/seo-directory.js
node tools/seo-metadata.js
```

Commit page changes, regenerate and commit the sitemap, then deploy as described in [SEO.md](SEO.md). Review translated copy and layouts in a browser; automated checks do not establish linguistic quality.

## Language selection on detailed pages

`lang/i18n.js` reads the browser language on a first visit, or a saved choice under `scooby.lang`. A first-visit picker and navigation selector let the visitor choose a language. Explicit non-English choices on the English homepage open the matching translated homepage. Automatic browser detection does not redirect.

On product pages and guides, changing language translates matching text in place. Visiting a translated homepage saves its language for these pages. Returning to English through the translated homepage's English link saves English. Storage is optional; static pages work even when it is unavailable.

Dictionaries map exact English strings to translations. Unmatched text stays English. The runtime also translates titles, descriptions and selected accessibility attributes. Scripts, code blocks and elements marked `data-i18n-skip` are excluded.

To correct runtime text, edit the appropriate `lang/<code>.js` file. To correct a static homepage's main copy, edit `tools/search-locales.json` and regenerate. Keep both in sync when homepage source copy changes.

## Browser helpers

Pages loading `lang/i18n.js` expose:

```js
__scoobyI18n.set('fr')
__scoobyI18n.get()
__scoobyI18n.langs
__scoobyI18n.missing()
__scoobyI18n.showPicker()
__scoobyI18n.reset()
```

Use `missing()` to identify English strings without a translation on the current page. The static language homepages intentionally use ordinary language links instead of this runtime.

See [lang/ADDING-A-LANGUAGE.md](lang/ADDING-A-LANGUAGE.md) for adding a language.
