# SCOOBYsite Dev Notes

## URL Structure
All pages use folder-based routing (`page/index.html`) for clean URLs on GitHub Pages.
- `/store` → `store/index.html`
- `/products/gta5` → `products/gta5/index.html`
- No `.html` extensions anywhere in internal links.
- All internal hrefs and asset paths are **absolute** (start with `/`).

## Local Development
**Double-click `serve.bat`**, then browse `http://localhost:8080`. It serves the repo folder,
picks the next free port if 8080 is taken, and opens your browser once the server is actually up.
Leave the window open while you browse; Ctrl+C stops it.

### Why opening the .html files directly does not work
Every internal href and asset path is absolute (see URL Structure above). Under `file://`
a link to `/guides` resolves against the **root of your drive** — the browser asks for
`file:///guides`, which does not exist — so you get a blank page and no CSS. Nothing is
broken; the same links resolve correctly the moment they are served over `http://`, which
is why the live site is fine. Always preview through `serve.bat`.

## Adding New Pages
Always create `newpage/index.html`, never `newpage.html`.


## Left 4 Dead pages

- Product: `/products/l4d/`; features: `/features-list/l4d-features/`.
- Wiki: `/guides/l4d/`; Lua API and examples: `/docs/l4d/`.
- Feature registry data: `tools/features/features-l4d.json`. Regenerate with `node tools/features/build-features-page.js --apply`.
- Lua reference sources: `docs/l4d/game-api.md`, `snippets.md`, and `ui-api.md`. Sync them from L4D-Debug after API changes, then run `node tools/build-l4d-docs.js` with the `marked` Node package available.
- Run `python tools/build-guide-search.py` after wiki edits. SEO entries are in `tools/seo-metadata.js`; regenerate metadata and sitemap with their `--apply` options.
- Browser validation: serve this repo on `127.0.0.1:8184`, then run `node tools/validate-l4d.js <screenshot-output-directory>` with Playwright and Microsoft Edge available. It covers desktop/mobile layouts, the screenshot lightbox, free-key modal, feature search, Lua copy buttons, and navigation.
- Gameplay images are user-supplied development captures, not synthetic screenshots. The city banner is original generated artwork. These pages use the existing general free-key flow; no separate L4D key policy is needed.


## Product terminology

Use **cheat** for GMOD, L4D, CS2, FiveM, RedM and other games. GTA 5 and RDR2 can use both **cheat** and **mod menu**; reserve **mod menu** for those two games. Keep product titles, visible copy, social metadata and structured data consistent; edit the source entries in `tools/seo-metadata.js` when changing generated metadata. References to interface menus and menu settings are still valid.
