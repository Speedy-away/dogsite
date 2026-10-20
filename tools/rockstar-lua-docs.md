# GTA5 and RDR2 Lua documentation

Run `npm run docs:rockstar` to regenerate both games from the current local
Scooby-Op checkout. Use `npm run docs:rockstar:check` to detect stale outputs,
and `npm run docs:rockstar:test` for browser, links, availability, ZIP, clipboard,
responsive layout and source/download hash checks. Test evidence stays under
`build/rockstar-lua-docs/`.

The generator accepts `--game GTA5` or `--game RDR2`, optional `--gta-root PATH`
and `--rdr2-root PATH`, and `--python PATH`. The game build trees provide the
pinned Python path; configure their supported dependencies first. Generated
working files stay under each game project's `build/site-lua-docs/`.

Public API routes remain `/api/gta5_api_reference.html` and `/api/rdr2/`.
Each game's `docs/` folder has source catalogs, an offline HTML browser,
custom UI/porting/developer-file guides, three working Lua examples and ZIP
downloads. Documentation.json, DataNodes.lua and natives.lua come directly
from the game generator; the Lua references intentionally refuse execution.
RDR2 uses RDR2 bindings and does not reuse GTA5 raw node layouts.

The site search index merges only these games' rows, preserving other games.
The existing RDR2 build/validation commands delegate to the shared tooling.
The older GTA Studio-only sync tool is superseded by this generator.
Existing Vesper packages remain available. Sovereign is still being ported
and is not included in these site downloads.

Generation and validation are local operations. They do not commit, push,
publish, deploy, or establish live game/input/performance acceptance.
