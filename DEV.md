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
