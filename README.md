# 

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

Serve the repository root for local previews. Production must publish the generated site so that the reseller media ZIP is included.

`.github/workflows/pages.yml` builds and publishes `project/build/publish/` on pushes to `main` or manual runs. Set **Settings → Pages → Build and deployment → Source → GitHub Actions** once in GitHub, then push/run the workflow. It rebuilds the reseller ZIP from current images, verifies that the packaged download returns HTTP 200, and deploys it with the website. No large ZIP needs to be committed to Git. For other hosts, run `npm run build` and upload `project/build/publish/`.

`npm run test:site` verifies packaging and public routes. `npm run test:seo` verifies metadata and sitemap coverage. External documentation/release tools should use the repository root as their site root.

After generating or editing pages, run `npm run seo:links` to align navigation with canonical directory URLs, then `node tools/seo-sitemap.js --apply` and `npm run test:seo`. Keep trailing slashes on directory links (for example, `/products/gta5/`); standalone HTML pages retain their filenames.

More details: [development notes](project/DEV.md).

## Reseller page and media pack

`/resellers/become/` contains the GBP bulk calculator for GTA 5 Premium (£15), GTA 5 Plus (£25), RDR2 (£10), FiveM (£15) and RedM (£25). The shared minimum is 10 keys. Discounts increase linearly from 25% at 10 keys to 40% at 50, then linearly to 65% at 1,000; larger orders keep 65%. Brazil's base prices are 20% lower before the bulk discount. Other countries use standard pricing. Selling-price presets add 10% or 25% to the selected market's base; custom prices are also available. Gross profit is sales revenue minus bulk cost, excluding fees and taxes. Orders are arranged on Discord or Telegram @whatwhatboy; payment is BTC/LTC only.
