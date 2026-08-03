# SEO — getting scoobymenu.cc into search results

## The honest summary

The site was **not blocked** from being indexed — `robots.txt` allows everything, there is no `noindex` on content pages, and every page ships real HTML that crawlers can read without running JavaScript. So nothing here was stopping you appearing.

What was missing was the technical groundwork that makes crawling reliable, plus **the submission step, which nobody can do for you from the codebase**. See *What you still have to do* at the bottom — that part matters more than everything else on this page.

---

## How DuckDuckGo actually works

DuckDuckGo does **not** run its own web crawl of any real size. Its results come mostly from **Bing's index**, topped up with its own crawler (DuckDuckBot) and other sources.

That means:

> **To appear on DuckDuckGo, you need to be in Bing.**
> Submitting to Bing Webmaster Tools is the single highest-impact action available.

The same applies to Yahoo and Ecosia, which are also Bing-backed. Google is a separate index and needs its own submission.

---

## What was fixed

| Problem | Fix |
| --- | --- |
| 10 pages missing from `sitemap.xml` | Sitemap regenerated from the filesystem — **22 → 29 URLs** |
| `lastmod` dates were hand-written and stale (all `2026-06-12`) | Now taken from each file's **last git commit date** |
| Login-gated `/portal/` was indexable | `noindex, nofollow` added, and excluded from the sitemap |
| `freekey.html` had no canonical and no meta description | Both added |
| `/store/` had **no `<h1>`** at all | Page header added (the CSS for it already existed, unused) |
| `/docs/` had **two `<h1>`s** | Second demoted to `<h2>` |
| No 404 page — GitHub Pages served a generic one | [404.html](404.html) added, `noindex, follow` so link equity still flows |

Verified in a real browser across 15 pages: **every indexable page has a title, meta description, canonical URL and exactly one `<h1>`**, and 0 pages have problems.

### One thing worth knowing

The language system hides the page body for a moment while a translation loads, to avoid a flash of English. That cloak only ever activates when a **stored language preference** exists — which a crawler never has. This was checked explicitly: `visibility: visible` on every page, no cloak class. **Crawlers see the full English content.**

---

## Keeping the sitemap current

```bash
node tools/seo-sitemap.js           # show what it would write, exit 1 if stale
node tools/seo-sitemap.js --apply   # write sitemap.xml
```

It walks the site, skips anything with a `noindex` tag or a meta-refresh redirect, pulls `lastmod` from git, and assigns priority/changefreq per section. Add a page, run it, done — no hand-editing.

Because the no-argument form exits non-zero when the file is out of date, it works as a CI or pre-commit check.

---

## What you still have to do

None of this can be done from the repository — it needs access to your accounts. **This is the part that actually gets you indexed.**

### 1. Bing Webmaster Tools — this is the one that matters for DuckDuckGo

1. Go to <https://www.bing.com/webmasters>
2. Add `https://scoobymenu.cc`
3. Verify ownership. Easiest for GitHub Pages: choose the **HTML meta tag** method and paste the tag into `<head>` of [index.html](index.html) — I can wire it in for you.
4. Submit `https://scoobymenu.cc/sitemap.xml`
5. Use **URL Inspection → Request Indexing** on the homepage

Bing also supports **IndexNow**, which pushes updates instantly instead of waiting for a crawl. If you want it, generate a key in Webmaster Tools and I'll add the key file and a submit script.

### 2. Google Search Console

1. <https://search.google.com/search-console>
2. Add the property, verify (same HTML-tag method works)
3. Submit the sitemap, then **Request Indexing** on the homepage

### 3. Expect it to take time

Indexing is not instant. A new domain typically takes **days to a few weeks** to appear, and ranking for competitive terms takes longer. If nothing shows after ~2 weeks, check Bing/Google Search Console for crawl errors rather than assuming it's broken.

### 4. Check whether you are already indexed

```
site:scoobymenu.cc
```

Run that on DuckDuckGo, Bing and Google. Nothing returned means not indexed yet — go do step 1.

---

## Realistic expectations for this niche

Worth saying plainly: game-cheat and mod-menu sites have a harder time in search than most. Search engines apply extra scrutiny to the category, some sites in it get filtered or demoted regardless of technical quality, and ad networks and hosts can be twitchy about it. Clean markup and a valid sitemap remove every *technical* reason not to index you — they cannot override an editorial or policy decision.

The things that move the needle after submission are ordinary: inbound links from places that already rank (your Discord, YouTube descriptions, community posts), genuinely useful pages (the guides are your strongest asset here), and consistent uptime.

---

## Files

| File | Purpose |
| --- | --- |
| [robots.txt](robots.txt) | Allows all crawlers, points to the sitemap |
| [sitemap.xml](sitemap.xml) | 29 indexable URLs — generated, don't hand-edit |
| [404.html](404.html) | Branded not-found page |
| [tools/seo-sitemap.js](tools/seo-sitemap.js) | Regenerates the sitemap |
