# SCOOBYsite Dev Notes

## URL Structure
All pages use folder-based routing (`page/index.html`) for clean URLs on GitHub Pages.
- `/store` → `store/index.html`
- `/products/gta5` → `products/gta5/index.html`
- No `.html` extensions anywhere in internal links.
- All internal hrefs and asset paths are **absolute** (start with `/`).

## Local Development
`file://` does not work — use `serve.bat` (double-click) to launch a local server at `http://localhost:8080`.

## Adding New Pages
Always create `newpage/index.html`, never `newpage.html`.
