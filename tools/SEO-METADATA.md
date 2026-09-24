# Search metadata maintenance

All public, indexable HTML pages have page-specific search titles, descriptions, focused keyword tags, Open Graph tags, Twitter preview tags and canonical URLs. Account, redirect and error pages keep their existing noindex settings.

Edit the page copy in `tools/seo-metadata.js`, then run:

```sh
node tools/seo-metadata.js --apply
node tools/seo-metadata.js
node tools/seo-sitemap.js --apply
node tools/seo-sitemap.js
```

The metadata audit reports uncovered pages, duplicate titles/descriptions and stale generated tags. Feature-page and changelog builders apply the same metadata when generating HTML. The historical `split-guides.js` migration should not be rerun.

Titles target each page's specific topic, including game names on requirements and injection guides. Descriptions summarize actual content. Upcoming products are labeled Coming Soon. Unverifiable safety and detection guarantees are omitted from metadata. Keywords are descriptive editorial choices, not claims of measured search volume. GTA 5 and RDR2 use both cheat and mod menu terms; other games use cheat. Keep these terms natural in visible copy and link to relevant feature and setup pages.

Google does not use the meta-keywords tag for indexing or ranking. It may use titles and descriptions for search results and may choose different text from the page. Open Graph and Twitter tags provide share previews; they do not guarantee rankings.

After publishing, submit https://scoobymenu.cc/sitemap.xml in Google Search Console and Bing Webmaster Tools. Use their query and impression reports to guide future wording. This change does not publish the site or submit it to search engines.

References:
- https://developers.google.com/search/docs/crawling-indexing/special-tags
- https://developers.google.com/search/docs/appearance/title-link
- https://developers.google.com/search/docs/appearance/snippet
