# Search metadata maintenance

The existing Cherax Lua category page renders the complete collection for crawlers that do not execute JavaScript. Downloads remain on their resource cards, with no separate per-script pages. Run `npm run resources:seo` after changing the resource catalog. Unchanged generated pages retain their file modification times so sitemap `lastmod` values track content changes.

All public, indexable HTML pages have page-specific search titles, descriptions, focused keyword tags, Open Graph tags, Twitter preview tags and canonical URLs. Account, redirect and error pages keep their existing noindex settings.

Edit the page copy in `tools/seo-metadata.js`, then run:

```sh
npm run seo:update
npm run seo:check
```

These commands use Node scripts with no external packages. If the local npm launcher is unavailable, run `node tools/seo-metadata.js --apply`, `node tools/seo-directory.js --apply`, `node tools/seo-links.js --apply` and `node tools/seo-sitemap.js --apply` in that order, then `node --test tools/seo.test.js`. Omit `--apply` to check each generated output. `npm run build` refreshes these outputs before packaging; the Pages workflow fetches full Git history for page modification dates and runs the SEO tests before deployment.

The metadata audit reports uncovered pages, duplicate titles/descriptions and stale generated tags. Feature-page and changelog builders apply the same metadata when generating HTML. The historical `split-guides.js` migration should not be rerun.

Titles target each page's specific topic, including game names on requirements and injection guides. Descriptions summarize actual content. Upcoming products are labeled Coming Soon. Unverifiable safety and detection guarantees are omitted from metadata. Keywords are descriptive editorial choices, not claims of measured search volume. GTA 5 and RDR2 use both cheat and mod menu terms; other games use cheat. Keep these terms natural in visible copy and link to relevant feature and setup pages.

Google does not use the meta-keywords tag for indexing or ranking. It may use titles and descriptions for search results and may choose different text from the page. Open Graph and Twitter tags provide share previews; they do not guarantee rankings.

Keyword tags are trimmed and deduplicated, including the copies in structured data. Each localized homepage uses translated navigation terms from its existing dictionary, its native language name and relevant game names. Keep titles, descriptions and visible prose in the page's actual language. Adding hidden keywords does not replace useful page content.

The XML sitemap lists public canonical URLs only. Redirects, noindex pages, the account portal and pages canonicalized to another URL are omitted. Embedded advertising HTML carries `noindex`. The HTML directory groups feature lists and API references under their corresponding sections, and labels translated links with their language and right-to-left direction where applicable.

The existing translated homepages have reciprocal `hreflang` links in both HTML and XML, including their own language and an English `x-default` fallback. The locale registry is `tools/search-locales.json`; the matching static homepage and dictionary must exist before adding a language. English product pages do not receive language alternates until actual translated versions exist. Some homepages provide core translations only; their visible notices remain in place.

`lastmod` uses each page's most recent Git commit date. For pending local edits it uses the file modification date; when no date can be established, the tag is omitted. Running the sitemap generator alone does not assign today's date to every URL. The sitemap XML escapes URLs and uses the XHTML namespace for language alternates.

After publishing, submit https://scoobymenu.cc/sitemap.xml in Google Search Console and Bing Webmaster Tools. Use their query and impression reports to guide future wording. This change does not publish the site or submit it to search engines.

`robots.txt` advertises the same sitemap and allows public crawling for all search engines. Bing submission also helps discovery by services using Bing results, including DuckDuckGo. DuckDuckGo also operates its own crawler and indexes. Brave operates its own crawler and documents that pages must be crawlable by Googlebot for Brave to crawl them. Dedicated permissive bot groups are unnecessary when the shared rules already allow crawling.

After deployment, preview IndexNow notifications with `node tools/indexnow.js --all`, or use `--since <previous-release-commit>` for changes. Add `--submit` to send them. The existing **Notify search engines with IndexNow** workflow offers the same manual action. It verifies the live ownership key and requires the deployed sitemap to match the local sitemap before submitting. If the build generated a different sitemap, use the exact deployed build's sitemap locally first. IndexNow targets participating engines; it does not submit directly to Brave or guarantee indexing. Search-console verification and submission require access to the site's owner account.

References:
- https://developers.google.com/search/docs/crawling-indexing/special-tags
- https://developers.google.com/search/docs/appearance/title-link
- https://developers.google.com/search/docs/appearance/snippet
- https://developers.google.com/search/docs/specialty/international/localized-versions
- https://blogs.bing.com/webmaster/february-2023/The-Importance-of-Setting-the-lastmod-Tag-in-Your-Sitemap
- https://www.bing.com/webmasters/help/webmaster-guidelines-30fba23a
- https://duckduckgo.com/duckduckgo-help-pages/results/sources
- https://search.brave.com/help/brave-search-crawler

## Additional search engines and AI search

The XML sitemap includes image entries for public screenshots and resource previews linked in page HTML. The watch page generator uses the verified uploader, thumbnail, video description and original upload date from the video listings in `tools/seo-watch.cjs`. The video sitemap entries are for pages with the video as the main content.

Merchant Center's [Shopping policy](https://support.google.com/merchants/answer/6150005?hl=en-GB) excludes cheat software and game enhancements that make unauthorized changes. The community directory links to actual support channels. [Discussion forum markup](https://developers.google.com/search/docs/appearance/structured-data/discussion-forum) belongs on pages with real public user posts and replies.

Use the same sitemap URL in Google Search Console, Bing Webmaster Tools, Yandex Webmaster, and Naver Search Advisor. For Baidu, use its Search Resource Platform and the submission options available for the verified property. The site's shared robots rules allow public crawling, including by Brave and DuckDuckGo. IndexNow distributes URL changes to participating engines, including Bing, Yandex, Naver, Seznam.cz, and Yep. See https://www.indexnow.org/index for the current list.

The HTML site directory provides a visible, sourced description of whatwhatboy.com. The published `/llms.txt` is a plain-text reference to primary sources. AI search eligibility does not depend on this file. Public crawling is already allowed by the wildcard rule, including for OpenAI's OAI-SearchBot. Keep download, availability, and compatibility claims tied to the current first-party listing. This repository publishes scoobymenu.cc. The other domain needs its own sitemap and property verification.
