# SCOOBYsite Dev Notes

## URL Structure
All pages use folder-based routing (`page/index.html`) for clean URLs on GitHub Pages.
- `/store` â†’ `store/index.html`
- `/products/gta5` â†’ `products/gta5/index.html`
- No `.html` extensions anywhere in internal links.
- All internal hrefs and asset paths are **absolute** (start with `/`).

## Local Development
**Double-click `serve.bat`**, then browse `http://localhost:8080`. It serves the repo folder,
picks the next free port if 8080 is taken, and opens your browser once the server is actually up.
Leave the window open while you browse; Ctrl+C stops it.

The preview uses `tools/serve.py` to show the root `404.html` for missing URLs,
with an actual HTTP 404 status, matching the site's GitHub Pages fallback.
Directories without an index also show the error page instead of a file listing.
To start without opening a browser, run `python tools/serve.py 8080`.
The server binds to `127.0.0.1` by default; use `--bind` to change it.
Check routing with `python -B -m unittest discover -s tools -p "test_serve.py"`.

### Error page
`404.html` is the hosting-required exception to folder-based routing. Keep its
links and assets root-relative so it works at any missing URL depth. It stays
out of search indexes and preserves redirects for old API and language URLs.
The recovery page works without JavaScript; JavaScript adds the requested path
and handles legacy redirects. Query strings and fragments are never displayed.


### Why opening the .html files directly does not work
Every internal href and asset path is absolute (see URL Structure above). Under `file://`
a link to `/guides` resolves against the **root of your drive** â€” the browser asks for
`file:///guides`, which does not exist â€” so you get a blank page and no CSS. Nothing is
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

## CS2 Lua documentation

- Quick start and downloadable templates: `/docs/cs2/`; searchable reference: `/api/cs2/`.
- Automatic sync: CS2 builds and `serve.bat` / `tools/serve.py` start one hidden watcher for the sibling `Scooby-Op/CS2/v2` API, host/editor docs, canonical shared UI docs and templates. Saving a source change regenerates the reference, downloads, source manifest and CS2 search entries. Invalid or undocumented bindings report an error and wait for correction.
- Double-click `sync-cs2-docs.bat` to start sync directly. From CS2/v2 use `python tools/sync_lua_site.py --status`, `--stop`, `--check` or run without options for one sync. Logs are in CS2/v2 `build/lua-site-sync`. The watcher continues after preview closes; a CS2 build or preview launch restarts it after reboot. No startup entry is installed.
- Source override for the preview/launcher: `CS2_LUA_SOURCE_ROOT`. Use `tools/serve.py --no-lua-sync` to skip watcher startup. The source tool accepts `--site-root` / `CS2_LUA_SITE_ROOT` and `--node`; stop the watcher before changing its destination.
- Low-level generation remains `node tools/build-cs2-docs.js` with `marked` available. It reads the host docs, editor definitions and templates, plus canonical `simple-base/UI/docs`. Override its source with `--cs2-root <path>`. The automatic wrapper validates/regenerates host binding metadata before this step.
- `--check` verifies the generated pages, downloads, source hashes and scoped docs-search entries without writing files. Edit the source docs/templates or generator, not the generated reference HTML. The CS2 host contract takes precedence over shared integration examples.
- Run `node tools/validate-cs2-api.js <output-directory>` with Playwright and Edge. It starts a loopback-only static server, checks search, copy, deep links, mobile layouts and downloads, then closes the server/browser. `CS2_API_BASE` optionally targets an existing local preview.
- The site changes remain local until the normal publication process is requested.


## TF2 family

`/products/tf2/` presents both editions together with the shared screenshot gallery and Get Free Key dialog. The access card has no logo or edition dropdown; edition selection stays in Scooby Launcher. Old `?edition=` links still reach this combined page. Both editions accept a valid free-key session or signed-in paid account and are listed as released in the Source Games catalog. Portal artwork recognizes both product names without adding paid subscription IDs.

`/guides/tf2/` is the TF2 Wiki hub, with getting started, requirements, editions, menu/settings, Lua scripts and troubleshooting pages. Shared wiki navigation, `/guides/source-games/`, the homepage and product page link to it. Run `python tools/build-guide-search.py` after changing guide content to rebuild wiki search.

`/docs/tf2/` provides Lua quick start and three downloadable examples. `/api/tf2/` contains the searchable host and shared UI reference. Full source contracts and a version/hash manifest are available under `/docs/tf2/`. The two host contracts are read independently. Shared entries appear once, while differing or additional Classified entries appear in a labeled additions/overrides section. API version mismatches require a display review before generation.

Generate with `node tools/build-tf2-docs.js`, with `marked` available to Node. The default source is the sibling `Scooby-Op/source/TF2`; override it with `--tf2-root <path>`. Shared UI contracts are read from `Scooby-Op/simple-base/UI/docs`. Edit source contracts/examples or the generator, then regenerate. `node tools/build-tf2-docs.js --check` verifies generated pages, source hashes, downloads and TF2 search entries without modifying files. It preserves other games' docs-search entries.

Run `node tools/validate-tf2.js` for the free-key dialog and product gallery and `node tools/validate-tf2-docs.js` for the wiki/docs/API, with Playwright and Edge available and the site served at `http://127.0.0.1:8198`. `TF2_SITE_BASE` overrides the documentation validator's preview URL. Captures/results go under `build/tf2-validation/` and `build/tf2-site-validation/`. The docs validator covers desktop/mobile layouts, search, copy, theme, keyboard behavior, local links/anchors, example downloads and JavaScript-free navigation.

After adding routes, update `tools/seo-metadata.js`, apply page metadata using the SEO helpers, then run `node tools/seo-directory.js --apply`, `node tools/seo-sitemap.js --apply` and `node --test tools/seo.test.js`. These changes stage source/assets locally; they do not alter the existing download-page pause or publish either repository.

### TF2 product presentation and feature library

The TF2 page uses the existing shared product heading, screenshot gallery, access card, feature sections and FAQ layout. Its access card uses the standard free-key flow for both editions; no website edition selection is needed. TF2 follows L4D on the root and all translated homepages; regenerate localized pages with `node tools/seo-locales.js --apply` after changing their shared catalog.

`tools/features/features-tf2.json` records the feature catalog and source hashes for both menu implementations. Run `node tools/features/build-features-page.js --only tf2 --apply` after editing it. The page is `/features-list/tf2-features/`; standard feature navigation and the product card link to it. Edition-specific controls are labeled, and source coverage does not establish every gameplay path's runtime acceptance.

`tools/previews/tf2.json` records original and published screenshot hashes. The three Classified images are genuine application framebuffer captures from the recorded local Hydro session; the two retail images are explicitly labeled standalone interface previews. Full-size WebP copies are lossless, with responsive 640/960px thumbnails. Do not describe the retail preview application as an in-game capture. The native screenshot tool failed to initialize during this site update, so existing verified captures were used; no new game session was launched.


## More Games collection

`/more-games/` groups The Last of Us and Megabonk; their individual pages remain at `/products/last-of-us/` and `/products/megabonk/`. The root and translated homepages order the shared catalog as CS2, GMod, L4D, TF2, S&box, Source Games, then More Games. Regenerate translated homepages with `node tools/seo-locales.js --apply`.

Megabonk uses the shared product layout and the existing general free-key link/modal. Its cover is copied from the main loader artwork (provenance in `tools/previews/megabonk.json`). The product links to `/features-list/megabonk-features/` and `/guides/megabonk/`. The source-backed feature manifest includes game controls, Lua API 1.1, language catalogs, configs and hotkeys; in-game screenshots are not implied. The wiki has six topics plus downloadable Lua examples/reference. Language distributions are maintained in `Rendererrr.github.io/scooby/Megabonk/lang` and generated by the game project’s `tools/build_languages.py`; untranslated detail text falls back to English. Rebuild guide search and scoped feature/SEO outputs after changes. No new product IDs or backend entitlements are configured by these site pages. Keep its store entry and More Games card aligned when adding content.


## CS2 Web Radar

Viewer, relay, deployment examples and protocol: [web-radar/README.md](web-radar/README.md).
Keep all feature files under `web-radar/`. Live sessions require a server-side relay;
GitHub Pages and `serve.bat` cannot run one. The relay serves clean private routes
at `/web-radar/<id>` directly; no 404 redirect or public session directory is used.

Open `dogsite.sln` in Visual Studio with C++ project support and Node 22+ on PATH.
Build/Rebuild runs Node syntax checks and the relay/projection HTTP tests. Outputs
stay under `build/x64/<Configuration>/web-radar/`; Clean removes only its validation log.
The wrapper keeps the existing static-site and Node toolchain (no frontend bundler).
Browser validation requires Playwright and Edge: `node web-radar/tools/validate-browser.cjs`.
Screenshots and results are saved to `build/web-radar-validation/`; all gameplay data
in those captures is explicitly synthetic. No deployment or DNS change is implied.

Megabonk browser validation: serve with `python tools/serve.py 8207 --no-lua-sync`, then run `node tools/validate-megabonk.js` with Playwright and Edge available (`MEGABONK_SITE_BASE` overrides the URL). Captures and results are local under `build/megabonk-site-validation`. SEO walkers exclude `build/` so local previews and backups cannot enter public route lists.


## RDR2 Lua documentation

Generate the searchable `/api/rdr2/` reference, `/docs/rdr2/` quick start, Frontier ZIP/source downloads, native catalog and scoped search entries with `node tools/build-rdr2-docs.js` (`marked` required). Use `--check` for a read-only freshness check and `--rdr2-root <path>` to override the sibling host project. Sources are the host runtime/reference/porting docs, API version/input bindings, generated `build/x64/vs2022/generated/lua/lua-native-catalog.json`, and `RDR2/Lua/Frontier`. Build the Lua54 native catalog before generation. The manifest records source hashes. Edit those sources and regenerate; preserve other games' search entries.

Run `node tools/validate-rdr2-docs.js` with Playwright and Edge for local browser/download checks. Results stay under `build/rdr2-docs-validation/`. Pages remain local until publication is requested.


## CS2 custom models guide

`/guides/cs2/custom-models/` documents the v2 Custom models page: the Steam `game\csgo` install folder, complete package structure, Refresh list, previews, CT/T agent priority, Self arms/hands, weapons and resets. Its source is `guides/cs2/custom-models/index.html`; keep instructions aligned with the sibling `Scooby-Op/CS2/v2` model library, model selection and model changer. The guide is linked from the wiki hub, CS2 hub and shared static wiki sidebars. Rebuild guide search, scoped SEO metadata, the site directory and sitemap after route/content changes. Desktop/mobile, theme, search, links and JavaScript-free navigation evidence is retained under `build/cs2-custom-model-guide/`. These are local website checks, not game-model runtime acceptance or publication.


TF2 release freshness: `node tools/check-tf2-features.js` validates the manually reviewed catalog source hashes, edition labels and required current controls. Review feature descriptions before replacing a changed hash in `tools/features/features-tf2.json`. Root Scooby-Op `release.bat -Product tf2 -NoPublish` invokes this check, regenerates the TF2 feature/API pages locally, builds/tests the matching loader and cleans TF2 temporary build output. It does not publish website or loader changes. Run `node tools/validate-tf2.js` and `node tools/validate-tf2-docs.js` against `python tools/serve.py 8198 --no-lua-sync` for browser verification.

Install the pinned Node tooling once with `npm ci` (Node.js 24 or newer is used for the TF2 generator). `npm run tf2:check` checks catalog/API freshness; `npm run tf2:build` regenerates TF2 pages; `npm run tf2:test` runs the browser suites with Microsoft Edge installed and the preview server running. No Codex-specific `NODE_PATH` is required.
