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
