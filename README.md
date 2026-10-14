# Scooby website

This is a static website. **`index.html` lives at the repository root**, alongside the public URL folders and assets. No compilation or Visual Studio project is needed to serve it.

- `index.html` — homepage
- `assets/`, `products/`, `guides/`, and other public folders — website content
- `tools/` — optional preview, generation, and validation scripts
- `project/` — notes, designs, exports, and maintenance scripts
- `project/build/` — temporary test output, created only when needed and ignored by Git
- `project/web-radar-dev/` — optional Visual Studio wrapper for Web Radar checks

The `.sln` and `.vcxproj` only wrap checks for the Web Radar service. They are not needed by the static website.

## Preview

Run `npm start` and open <http://127.0.0.1:8080>. Use `npm start -- 8081` for another port. Or double-click `serve.bat` for the Python preview and optional CS2 documentation watcher.

Run tools from the repository root. Use `npm ci` to install dependencies for generators and browser checks.

## Publish and validate

Serve or publish the repository root. Public URLs are unchanged; restoring the homepage does not require a new GitHub Actions publishing setup.

`npm run build` is optional packaging, not website compilation. It copies public files into `project/build/publish/`. A Pages workflow example is saved in `project/pages-workflow.example.yml`; it is not active.

`npm run test:site` verifies packaging and public routes. `npm run test:seo` verifies metadata and sitemap coverage. External documentation/release tools should use the repository root as their site root.

After generating or editing pages, run `npm run seo:links` to align navigation with canonical directory URLs, then `node tools/seo-sitemap.js --apply` and `npm run test:seo`. Keep trailing slashes on directory links (for example, `/products/gta5/`); standalone HTML pages retain their filenames.

More details: [development notes](project/DEV.md).

## Reseller page and media pack

`/resellers/become/` contains the GBP bulk calculator. GTA 5 Premium is £15 and Plus is £25 before discount. The shared order minimum is 10 keys. Discount is `30 + (min(keys, 1000) - 10) * 35 / 990` percent for eligible orders, capped at 65%. Customers can enter their own resale prices; these do not alter the bulk cost. Payments are BTC/LTC only, arranged via Discord.

- `npm run media:build` rebuilds the ZIP from current public product images and generates 1600×900 SVG product banners.
- `npm run media:banners` also exports PNG banners using Playwright (Edge on Windows, installed Chromium elsewhere).
- `npm start` builds the pack and watches product pages and image folders for additions, edits and deletions.
- `npm run build` refreshes the pack before copying the complete site into `project/build/publish/`. **Deploy this built output for the reseller download to be available.** Generated downloads are ignored by Git because the complete original-image pack exceeds GitHub's per-file limit. A raw repository upload without running the build will not include the pack.
- Banners are self-contained SVGs. PNG exports are included only when they match the current SVG; rerun `media:banners` after changing banner artwork to refresh raster versions.
- The ZIP uses `brand/` and `products/<game>/{screenshots,artwork,banners}/`, plus a SHA-256 manifest. New builds do not retain removed source images.
- `npm run test:reseller` checks pricing and ZIP encoding. `node tools/validate-reseller.cjs` checks the page and download in Edge.
