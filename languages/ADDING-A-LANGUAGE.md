# Adding a language

The site has runtime dictionaries for detailed pages and generated static homepages for search discovery. Add both when introducing a language.

1. Add the lowercase URL code, native name and badge label to `LANGS` in `i18n.js`. Use `rtl: true` for right-to-left languages. Optionally add a flag to `FLAGS`; native language names remain the identifying labels.
2. Copy an existing dictionary to `<code>.js`. Change both registration codes at the bottom, keep the English keys, and translate the values. Keep the key set consistent with the other dictionaries. Brand names and code identifiers remain unchanged.
3. Add the language to `../tools/search-locales.json`, including its native name, valid BCP 47 tag, Open Graph locale, title, introduction, descriptive paragraph and English-content notice. Add `rtl: true` where appropriate. URL codes can differ from tags: `zh` uses `zh-Hans`; `pt-br` uses `pt-BR`.
4. Add the translated word for “Languages” to `languageLabels` in `../tools/seo-locales.js`.
5. Run the generators and checks from the repository root:

```sh
node --check languages/<code>.js
node tools/seo-locales.js --apply
node tools/seo-directory.js --apply
node tools/seo-metadata.js --apply
node --test tools/seo.test.js
node tools/seo-locales.js
node tools/seo-directory.js
node tools/seo-metadata.js
```

The generators add the homepage, metadata, reciprocal language links and directory entry. Commit page changes, then regenerate `sitemap.xml` and commit it, following [../SEO.md](../SEO.md).

Check the homepage with JavaScript disabled, on mobile and desktop, and in the intended reading direction. Follow a product link and verify the selected language carries into the runtime translator. Check that English and other language links still work. Have a fluent speaker review new translations.

## Regional variants

Use a distinct code and dictionary for a regional variant, such as `pt-br.js`. Detection tries the full browser tag before its base language. Give each variant appropriate copy and metadata, with its own canonical URL.

## Existing coverage

All 22 choices listed in [../TRANSLATIONS.md](../TRANSLATIONS.md) are available. English uses source content; the other 21 have dictionaries and generated homepages. Detailed content can still fall back to English.

## Removing a language

Remove its dictionary, runtime registration, optional flag, locale record, language label and generated homepage. Regenerate the other homepages, directory and sitemap so no stale alternate links remain. Existing saved choices then fall back to English. Consider a redirect for previously published URLs.
