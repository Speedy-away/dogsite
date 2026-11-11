# X-Force source manifest

Audited 11 November 2026. This source preparation does not change the shared
library, importer, website UI or download repository. No push or deployment was
performed. Discord was not opened or controlled by this worker; the main chat's
integration note records that Discord Computer Use was stopped with Escape.

`../xforce.json` contains **36 resource records**:

| Record family | Count | Representation |
| --- | ---: | --- |
| Existing X-Force v6 UI presets | 17 unique | `libraryOverrides` with exact existing library IDs |
| Included custom headers | 15 | New `items`, referencing the existing complete collection ZIP |
| Public author Lua scripts | 4 | New `items`, all pending with `files: []` |

The UI audit inspected 18 preset files. `Presets/.ui` and `Presets/cool.ui` are
byte-identical; the latter is an alias of Default. `duplicateAliases` records the
existing duplicate ID for the parent normalizer to reconcile. All 17 override IDs
are already in the site's library. The 15 header IDs and four Lua IDs are new.
Do not append a second copy of the 17 existing UI entries.

Three ZIPs were checked against the published local pack index, and every member
was checked against each archive's embedded SHA-256 manifest. Together they
contain 133 entries including their three manifests. The selected All-02 ZIP has
61 asset entries. The existing sibling download copy was independently hashed
and matches `19a04697a1ca5680863f6d0f39661e0cae6505038e634237b0f0af6773ad6956`.
No second ZIP was created. ZIP timestamps are normalized by the packager and are
not original publication dates.

Nine of the 17 unique presets are retained v6 resources. Eight presets under
`Collection/Originals` are local Scooby adaptations. The two image assets for LSD
Lucid and Space Nebula have local image-generation provenance in
`Scooby-Op/GTA5/EE/GTA - Main Src/assets/listui/xforce-v6-original-artwork.json`.
These are explicitly distinguished from original community releases and their
previews do not set `previewVerified: true`.

The other previews are actual included image/GIF assets extracted under
`previews/`. Their captions describe included artwork, not full-menu screenshots.
Presets with a plain built-in header use the included header asset as a reference;
the old `xforce.xf_cnfg` points at a missing `C:/X-Folder/textures/xforce.gif`, so
no preview was invented for it. Five retained WebP sources also have PNG
counterparts in the archive; each pair is grouped as one header choice. Preserve
the website's separate theme-preview display policy when normalizing these paths.

The source-verified compatibility claim is specifically **Scooby GTA5's native
X-Force v6 ListUI adapter**. Its loader accepts `.ui` and `.xf_cnfg`, resolves
bundled fonts and reads PNG/JPG/JPEG/GIF/BMP headers. Retained upstream entries
also record their historical X-Force format requirement, not a current X-Force
runtime test. Local adaptations list only Scooby. This evidence does not establish
Nenyoo or RDR2 theme compatibility. No vehicle/outfit/DLC samples were acquired,
so none are cross-labelled from filenames or channel names alone.

The public Lua candidates are 22's Business Manager, DadMenuProTo21.1.69, Casino
Bypass and Snacks. Their original X-Force APIs remain required. The last three
are archival 2023–24 source records; the Business Manager source was uploaded in
2026. These flags describe the inspected source collection, not successful runtime
tests. Public author links are GitHub links. No Discord link is exposed on a Lua
card, no Lua download URL is supplied, and no formerly removed local Lua example
is reintroduced. The old scripts still need current host/build testing before
any later download acquisition.

Individual release versions, original Discord publication dates and detailed
author changelogs were not established. Versions remain `null` and `changelog`
arrays stay empty. Verified Git commit dates are stored as commit dates in
`sourceHistory`, not converted to claimed release notes. The official menu image
is kept separately as reference evidence, not reused as any Lua's preview.

## Requested channel coverage

| Media channel | Acquired evidence | Remaining gap |
| --- | --- | --- |
| ui-configs | Local v6 archives: 17 unique presets | Original/current Discord shares and author dates |
| custom-header | Local collection: 15 header choices | Original/current Discord shares and author dates |
| asi-scripts | None | Filenames, author source, dependencies, preview, version, host/build support |
| outfits | None | Actual payload and schema; model/character/build requirements |
| translations | None | Language, host schema/version and author evidence |
| custom-dlc-addons | None | Actual assets, author release, game edition and install requirements |
| xml-vehicles | None | Actual XML payload/schema and source message |
| xml-maps | None | Actual placement XML and model/edition requirements |
| misc-files | None | Actual channel posts and attachments |

The archive includes four fonts, a WAV sound and two instruction text files.
They are listed as supporting assets, not inflated into seven independent
misc-files shares. Zero X-Force Discord messages were inspected. No claim that
every share was collected is made. Public research found no additional verified
author media collection, and the historical forum failed DNS resolution. Yim is
explicitly deferred.

## Reproduction and integration

Run from the dogsite checkout:

```powershell
node tools/menu-sources/xforce.cjs
node tools/menu-sources/xforce.cjs --write
node tools/menu-sources/xforce.cjs --check
```

The default is a read-only audit. `--write` only writes `xforce.json` and generated
X-Force evidence/previews in this directory. `--source-root DIR` can select a
different parent directory containing the sibling source checkouts. The helper
reads pinned public author metadata from `public-lua-candidates.json`, validates
pending-download/API-scope invariants and does not execute scripts or inspect any
Discord app data. `public-source-responses.json` records the exact public source
revisions, raw response URLs, sizes and hashes for repeat acquisition.

The parent can merge `items`, apply `libraryOverrides`, reconcile the duplicate
alias, and copy verified previews through its normal source-preparation path.
Resource files reference an already-existing `downloads/shared/themes/x-force/`
archive, relative to the existing download base. This worker has not modified the
sibling repository. New Discord evidence, if later provided through normal visible
app use, needs a separate bounded reconciliation; it must not overwrite these
explicit acquisition gaps with a claim of complete channel coverage.
