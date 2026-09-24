# Search discovery for Scooby cheats and mod menus

The official site is **https://scoobymenu.cc/**. Public HTML, canonical URLs, the sitemap and structured data use this domain. Engines decide whether to crawl, index and rank pages; submissions do not guarantee placement or clear security warnings.

## Implemented

- Unique titles, descriptions, canonical URLs and social previews for public pages, maintained in `tools/seo-metadata.js`.
- Relevant search phrases in titles and visible homepage copy. Updated keyword tags describe page topics; Google does not use `meta keywords` for ranking.
- Homepage Organization and WebSite identity, WebPage descriptions, and BreadcrumbList data based on visible navigation. Existing application and collection markup is preserved. No ratings, reviews or ownership verification are invented.
- A JavaScript-free directory at `/sitemap/`, linked from the homepage, covering public game, feature, guide and documentation pages.
- `robots.txt` allows crawling and advertises `/sitemap.xml`. Noindex pages, account pages, redirect stubs, tools and local backups are excluded from the sitemap.
- Searchable homepages in 22 language options (English plus 21 translations), with self-canonical URLs, reciprocal hreflang links and an English x-default. Translated prose is present in the HTML; Arabic and Hebrew use right-to-left layouts. Product and guide pages retain their existing runtime translations and can still contain English text.
- IndexNow verification at `/indexnow-key.txt`, a preview-first submission tool, and a manual GitHub Actions release workflow for participating engines including Bing.

The dashboard loader remains available. The homepage download remains paused. These changes do not alter the loader or its destination.

## Account setup

1. Preserve the existing Google Search Console DNS verification record.
2. In [Bing Webmaster Tools](https://www.bing.com/webmasters/), import the verified property from Google Search Console, or use the actual verification value provided by Bing.
3. Submit `https://scoobymenu.cc/sitemap.xml` in each engine's Sitemaps report.
4. Inspect important URLs. Fix reported crawl errors, accidental noindex directives or incorrect canonicals. Redirects and duplicate URLs can appropriately remain unindexed.
5. Compare clicks, impressions and queries over equivalent periods. Use actual queries to guide future content improvements. Review security issues separately.

IndexNow is not a Google indexing submission or a security review. Google clearance does not establish Microsoft SmartScreen clearance. Do not hide downloads or rotate domains to avoid review.

## Coverage beyond Google

Submit changed pages once through the global IndexNow endpoint. Participating engines share the notification: Bing, Yandex, Naver, Seznam.cz, Yep and Amazon. Do not send the same batch separately to each engine. [IndexNow lists its current participants](https://www.indexnow.org/faq).

DuckDuckGo sources many traditional web links from Bing, so Bing discovery also supports that route; it is not a separate DuckDuckGo submission. [DuckDuckGo explains its sources](https://duckduckgo.com/duckduckgo-help-pages/results/sources).

Brave operates its own crawler. Its documentation says pages must be crawlable by Googlebot; the site's public pages meet that robots requirement. This is crawl eligibility, not confirmation that Brave has indexed them. [Brave crawler documentation](https://search.brave.com/help/brave-search-crawler).

Google is separate from IndexNow. Submit the sitemap through the verified Search Console property and inspect important URLs there. Bing Webmaster Tools and Yandex Webmaster also provide account-based sitemap and crawl reports. Preserve genuine verification records; do not invent account tokens or treat an HTTP 200 page response as indexing evidence.

## Mobile images and useful content

The homepage and store use smaller card images. GMOD and the largest L4D screenshot use responsive WebP previews; the lightbox fetches the original only when opened. The original captures remain intact. Rebuild the display copies with `node tools/build-display-images.js` when those source assets change (requires `sharp`).

The homepage keeps its initial HTML background image, delays the next scene's preload, and skips preloading while paused, offscreen, hidden, or using data saver. GMOD, L4D and CS2 product questions link to their actual setup, requirements, feature and troubleshooting guides. Keep answers aligned with those guides as game support changes.

Run `node tools/validate-search-pages.js <output-directory>` with Playwright and Microsoft Edge available. The script serves the local repository, checks mobile/desktop layouts, preview enlargement, FAQs and slideshow playback, and records local image-transfer totals. These measurements are not PageSpeed scores or real-user Core Web Vitals.

For search performance, compare equivalent periods in Search Console and Bing Webmaster Tools. Filter by page, query, device and country; prioritize relevant queries with substantial impressions and low click-through rates. Review the landing page and search intent before changing a title or description. Do not infer impressions or clicks from public searches.

## Release maintenance

From the repository root, using Node 22 or later:

```sh
node tools/seo-locales.js --apply
node tools/seo-directory.js --apply
node tools/seo-metadata.js --apply
node --test tools/seo.test.js
node tools/seo-locales.js
node tools/seo-directory.js
node tools/seo-metadata.js
```

Commit the page changes, then update the sitemap so `lastmod` uses their actual last Git commit dates:

```sh
node tools/seo-sitemap.js --apply
node tools/seo-sitemap.js
```

Commit the sitemap and deploy. Unchanged pages retain their commit dates; the generator does not reset all dates each time it runs. Homepage language choices link to the corresponding language URL. Automatic browser-language detection does not redirect visitors. See TRANSLATIONS.md for translation maintenance; only equivalent homepages have hreflang, not English-only detailed pages.

## IndexNow after deployment

For an initial submission:

```sh
node tools/indexnow.js --all
node tools/indexnow.js --all --submit
```

For subsequent releases, specify the commit deployed before the new release:

```sh
node tools/indexnow.js --since PREVIOUS_RELEASE_COMMIT
node tools/indexnow.js --since PREVIOUS_RELEASE_COMMIT --submit
```

Without `--submit`, no network requests are sent. Submission first verifies the live key and matching deployed sitemap. It includes changed public HTML pages and removed URLs from the prior sitemap. Shared styles, scripts and data trigger notifications for public pages that may render differently. Image changes notify pages referencing that path. Account pages and local tooling remain excluded.

Alternatively, after Pages deployment completes, open GitHub Actions → **Notify search engines with IndexNow** → Run workflow on `main`. Supply the previous deployed commit; leave it blank only for the initial submission. This workflow is manual, not scheduled, and has read-only repository permissions.

HTTP 200 means received; 202 means received with key validation pending. Neither means indexed. Do not repeatedly submit unchanged pages. A 403 can mean the key is not deployed; 429 means submissions are throttled. Preserve the public key file across releases. It proves website control, not ownership of a webmaster account.

## Official identity and impersonation

Keep official Discord, Telegram and reseller profiles accurate and link back to `scoobymenu.cc`. Structured data `sameAs` links describe identity; they cannot prove ownership or remove another domain.

The owner identified `scoobymenu.net` and `scoobymenu.live` as unaffiliated sites using Scooby branding. Report impersonation through [Microsoft Report a Concern](https://www.microsoft.com/digitalsafety/report-a-concern), with exact result URLs, the query, dated screenshots, examples of copied branding and ownership evidence. Do not claim their downloads are malware without file-specific evidence. These tools do not submit reports.

## References

- [Google: supported meta tags](https://developers.google.com/search/docs/crawling-indexing/special-tags)
- [Google: localized versions](https://developers.google.com/search/docs/specialty/international/localized-versions)
- [Google: breadcrumb data](https://developers.google.com/search/docs/appearance/structured-data/breadcrumb)
- [Google: sitemap guidance](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)
- [Bing Webmaster Guidelines](https://www.bing.com/webmasters/help/bing-webmaster-guidelines-30fba23a)
- [IndexNow documentation](https://www.indexnow.org/documentation)
