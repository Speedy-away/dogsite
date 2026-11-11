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

## Resources

`/resources/` is the Resources browser for GTA 5, RDR2, CS2, FiveM, RedM and Left 4 Dead, with a visible category sidebar, game-specific filters, search, previews and downloads. `/resources/guides/` provides game-specific installation instructions. Both pages include the requested advertisement placement. Imported Lua examples are excluded from the catalog and download repository.

The original 22,100 GTA vehicle/outfit records remain in `community/data/vehicles/` and `community/data/outfits/`. The extended Scooby asset catalog is `community/data/library.json`. Download payloads, CS2 model catalog metadata and model previews are organized in the sibling `cool-repo` checkout. Its `index.html` redirects to `https://scoobymenu.cc/resources/`; direct file URLs still work. Third-party CS2 model packages retain their author download URLs and credit/license metadata. Donor-generated variants are installed through the in-game Repo. Nenyoo-only theme bundles are kept separately in `cool-repo/catalog/source-theme-packs.json`, outside the active Scooby catalog.

Rebuild from the local game asset folders with:

```powershell
npm run community:inventory
npm run community:build -- --target C:\Users\whatw\Documents\GitHub\cool-repo
node tools/build-community-library.cjs --target C:\Users\whatw\Documents\GitHub\cool-repo --check
npm run test:community
```

Use `--refresh-catalog` to update the native theme exports and source catalog separation after an initial import, without regenerating the full preset collection. ClickUI color presets are derived from each game's implemented palette definitions; back up the current appearance before loading them. ListUI interface/style filters are limited to GTA 5 and RDR2.

Only verified source screenshots or original theme artwork appear as theme previews; generated UI illustrations remain disabled. Complete native collections retain their files, shared images, fonts and dependencies. Verified downloads use an in-page Download action with the actual file extension shown in color beside the name. Creator credits and installation requirements remain in Details; unresolved mod-page links are excluded from active downloads. Built-in styles and model variants without a separate file show Details. Previously removed broken Lua examples remain excluded from the base library.

GTA 5 defaults to **Scooby's GTA 5 resources** and offers Nenyoo, Cherax, Stand and X-Force collections. Yim is deferred. `resources/menus.js` shares menu selection and discovery rules between the browser and generated directories. `supportedMenus` records established format/API support; `listedMenus` allows requested cross-menu discovery while preserving the required source format or compatibility layer in Details. The guides retain the chosen menu.

`community/data/menu-resources.json` supplements the original catalog with source-audited entries and compact overrides, preserving original download identities. Lua entries currently have disabled **Download — Coming soon** buttons and in-page changelogs. Script source updates remain labelled separately from author release versions, and no Discord links are exposed on Lua entries. The acquired snapshots do not establish complete current/old Discord history coverage; channel-level gaps remain recorded in `project/community-menu-sources/`.

After updating those source manifests, run `node tools/build-menu-resources.cjs --target C:\Users\whatw\Documents\GitHub\cool-repo --publish-assets`, then `npm run resources:seo`. This copies staged original previews and the supplement catalog to `cool-repo`; the normal website build consumes the prepared catalog without accessing Discord or local game checkouts.

Native LSC PaintJobs use the original JSON presets from `C:\scooby\GTA5\LSC\PaintJobs`; vehicle texture liveries have their own category. The main Maps category contains Menyoo/XML and Simple Trainer/INI placement maps, while streamed map packages belong under Addons. RDR2 ped packs and RedM server object assets retain separate game requirements.

`resources/taxonomy.js` supplies shared normalized tags and search aliases. Tags are shown in resource details. `npm run resources:seo` regenerates crawlable game/category directories, metadata, structured collection data and both sitemaps from the current catalog. Empty categories do not receive indexable pages. `npm run build` runs this update automatically before packaging the public site. Check it with `npm run test:resources`.

### Automatic resource updates

`npm start` also starts the resource watcher. Changes to the configured CS2 model
repo, GTA/RDR asset sources, menu share manifests or the resource inbox regenerate
the affected catalogs, original preview files, resource directories and sitemaps.
`npm run build` performs the same local change check before packaging. A host
without the sibling game/download checkouts uses the prepared catalogs instead.

The source registry is `project/resource-sources.json`. Add new files under
`project/resource-inbox/GAME/MENU/CATEGORY/` for direct ingestion; its README
describes single files, complete bundles, previews and optional author metadata.
Files keep stable catalog IDs when their contents change. Lua resources retain
pending Download buttons, and RedM PM bypass/faster scope are excluded.

- `npm run resources:check` reports changed and unavailable inputs without writes.
- `npm run resources:sync` imports local changes once.
- `npm run resources:watch` watches without starting the preview server.
- `npm run resources:refresh` also checks the registered public feeds; it honors
  provider rate limits. Ordinary preview/build runs do not fetch remote feeds.

Private Discord history still requires an authorized visible client or a saved
export; a filesystem watcher does not independently discover private shares. A
monthly Codex check is scheduled for the first day at 09:00 in the app's local
timezone. It reviews configured sources, imports verified additions, tests the
result and reports unavailable sources. Local scheduled work needs the computer
and app running. Changes remain local until the normal publication workflow is
requested; publish `cool-repo` downloads before the website. Reports and sync
state live under the ignored `project/build/resource-sync/` directory. Failed
imports restore the last prepared catalogs and remain pending for retry.

Use `--source-root <GitHub-directory>` if the source projects are elsewhere. The importer reads explicit asset folders, extracts outfit/map data, preserves package dependencies, and excludes game-project implementation files and build outputs. It does not delete existing download-repository files. New downloads require publishing `cool-repo` to its `main` branch before publishing the website. The website build packages its generated library manifest; it does not need the source game repositories. `npm start` previews imported relative downloads through an allowlisted `/community-files/` route while production uses the raw GitHub download base.

For the original GTA preview media only, run `python tools/prepare-community-media.py` with Pillow and the sibling `INF_DATA` checkout available. Existing cached presets and previews remain a fallback for the original catalog.
