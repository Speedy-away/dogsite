# Adding a language

The site has runtime dictionaries for detailed pages and generated static homepages for search discovery. Add both when introducing a language.

1. Add the lowercase URL code, native name, badge label and flag code to `LANGS` in `i18n.js`. Set `tag` if the HTML language tag differs from the URL code and `rtl: true` for right-to-left languages. Use an existing SVG under `flags/` or add the corresponding icon from [flag-icons v7.5.0](https://github.com/lipis/flag-icons/tree/v7.5.0/flags/4x3). Native language names remain the identifying labels.
2. Add a dictionary at `<code>.js`. Keep the English source keys and translate their values. For core coverage, start with a dictionary such as `uk.js` and mark the locale with `"coverage": "core"`. For broader coverage, match the key set of an existing full dictionary and add the portal copy in `../portal/portal-translations.js`. Brand names and code identifiers remain unchanged.
3. Add the language to `../tools/search-locales.json`, including its native name, valid BCP 47 tag, Open Graph locale, title, introduction, descriptive paragraph and English-content notice. Add `rtl: true` where appropriate. URL codes can differ from tags: `zh` uses `zh-Hans`; `pt-br` uses `pt-BR`.
4. Add the translated word for “Languages” under the `Languages` dictionary key to localize the footer selector.
5. Run the generators and checks from the repository root:

```sh
node --check lang/<code>.js
node tools/seo-locales.js --apply
node tools/seo-directory.js --apply
node tools/seo-sitemap.js --apply
node --test tools/seo.test.js
node tools/seo-locales.js
node tools/seo-directory.js
node tools/seo-metadata.js
```

The generators add the homepage, metadata, reciprocal language links, directory entry and sitemap URL.

Check the homepage with JavaScript disabled, on mobile and desktop, and in the intended reading direction. Follow a product link and verify the selected language carries into the runtime translator. Check that English and other language links still work. Have a fluent speaker review new translations.

## Regional variants

Use a distinct code and dictionary for a regional variant, such as `pt-br.js`. Detection tries the full browser tag before its base language. Give each variant appropriate copy and metadata, with its own canonical URL.

The site uses an explicit localized URL first, then a saved choice, then the first supported browser preference. When no preference matches, the page starts in English and opens the language picker.

## Existing coverage

English uses source content. Each locale in `tools/search-locales.json` has a dictionary and generated homepage. Locales marked `core` translate shared navigation and key homepage copy. Content without a matching translation falls back to English.

Run `node tools/i18n-verify.js` for a coverage estimate or pass a locale code for its page breakdown. The report uses candidate strings from source HTML, which can include names and excludes copy rendered by JavaScript.

## Removing a language

Remove its dictionary, runtime registration, locale record and generated homepage. Remove its flag asset if no other locale uses it. Regenerate the other homepages, directory and sitemap so no stale alternate links remain. Existing saved choices then fall back to English. Consider a redirect for previously published URLs.
