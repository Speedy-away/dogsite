# Bing search identity for Scooby Mod Menu

The official domain configured in `CNAME`, canonical tags and the sitemap is **https://scoobymenu.cc/**. The homepage identifies that domain in its title, description, visible badge, heading, download guidance and footer. Open Graph, Twitter and application description metadata use the same wording through `tools/seo-metadata.js`.

These are local changes until published. Bing chooses its own search titles and snippets, and a recrawl does not guarantee a ranking change or removal of another domain.

## What the site already provides

- `robots.txt` allows crawling and links to `https://scoobymenu.cc/sitemap.xml`.
- The homepage serves its content as HTML, has an indexable robots tag and uses a self-referencing canonical URL.
- `Organization` and `WebSite` structured data describe the brand. `sameAs` references the official Discord and Telegram accounts.

Structured data is a description, not ownership verification. Anyone can copy markup or profile links. Keep those links accurate and make sure the official profiles link back to `scoobymenu.cc`; do not add unverified profiles or other domains to `sameAs`.

## After publishing

1. Open [Bing Webmaster Tools](https://www.bing.com/webmasters) and select or verify `https://scoobymenu.cc/`. Use a real verification tag, file or DNS value supplied by Bing; the repository alone cannot establish account ownership.
2. Submit `https://scoobymenu.cc/sitemap.xml` in Sitemaps.
3. Inspect `https://scoobymenu.cc/` with URL Inspection. Check the live response, crawl errors, index status and selected canonical URL; request indexing if available.
4. Check Search Performance for `scooby mod menu` and related branded queries. Use account reports to diagnose indexing; an empty `site:` search is not conclusive.
5. Link to the official domain from the official Discord, Telegram and reseller profiles you control. Those account edits are separate from this repository change.

IndexNow is optional: it notifies participating engines about changed URLs. It requires a publicly hosted key file and does not guarantee crawling, indexing or ranking. There is no IndexNow submission implemented by this change.

## Report the two domains in the screenshot

The owner identified `scoobymenu.net` and `scoobymenu.live` as fake sites in Bing results for `scooby mod menu`. The supplied screenshot shows both using Scooby branding. A read-only inspection of `.net` also showed homepage sections and text matching Scooby's site. These observations do not establish what the downloaded software does.

Use Microsoft's [Report a Concern](https://www.microsoft.com/digitalsafety/report-a-concern), linked from [Bing's reporting instructions](https://support.microsoft.com/en-us/bing/how-to-report-a-concern-or-contact-bing). Select the category that matches the evidence. Include the exact result URLs, search query, screenshot, date observed and proof that you control the official site. Bing decides whether action is appropriate; reporting does not guarantee removal.

### Report draft for the owner

> Bing results for "scooby mod menu" show https://scoobymenu.net/ and https://scoobymenu.live/ using our Scooby name and branding. Our official website is https://scoobymenu.cc/. The two reported domains are unaffiliated with us and can mislead people seeking our downloads and support. Please review the results for impersonation and misleading content. We can provide proof of control of the official domain, the attached search-results screenshot and examples of matching content.

Attach the screenshot and ownership evidence when submitting. This draft has not been submitted. Requests concerning another site's downloads need evidence specific to those files; a copied page alone does not prove malware.

## Maintenance

Edit homepage search copy in `tools/seo-metadata.js`; keep visible homepage copy consistent with it.

```sh
node tools/seo-metadata.js           # audit all public page metadata
node tools/seo-metadata.js --apply   # regenerate all covered pages; review the diff
node tools/seo-sitemap.js            # audit the sitemap
node tools/seo-sitemap.js --apply    # regenerate after page changes
```

The sitemap generator uses each page's last Git commit date for `lastmod`. Regenerate after committing page changes when preparing a release. Excluded, redirect and account pages should stay excluded. The metadata audit may surface stale pages unrelated to an individual edit; review those separately.

## Sources

- [Bing Webmaster Guidelines](https://www.bing.com/webmasters/help/webmaster-guidelines-30fba23a)
- [Bing: Add and verify a site](https://www2.bing.com/webmasters/help/add-and-verify-site-12184f8b)
- [Bing: Sitemaps](https://www2.bing.com/webmasters/help/sitemaps-3b5cf6ed)
- [Bing: Structured data](https://www.bing.com/webmasters/help/marking-up-your-site-with-structured-data-3a93e731)
- [Microsoft: Report a concern about Bing](https://support.microsoft.com/en-us/bing/how-to-report-a-concern-or-contact-bing)
- [IndexNow FAQ](https://www.indexnow.org/faq)
