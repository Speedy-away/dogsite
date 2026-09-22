# Half-Life feature sync

Run from the website repository with Node.js:

```powershell
node tools/features/sync-half-life.js --apply
node tools/features/sync-half-life.js --check
node tools/features/test-half-life-sync.js
```

By default, the game source is the sibling `Scooby-Op` repository. Set `SCOOBY_SOURCE_ROOT` or pass `--source "C:/path/to/Scooby-Op"` to use another checkout. Running with no flags previews changes. `--check` returns a failing exit code when output is stale.

The sync reads the GoldSrc feature registrations, original Half-Life Lua pages and shared UI registry. It extracts feature IDs, labels, visible aim/material modes, slider ranges and campaign controls. Shared menu capabilities use explicit source anchors. It excludes controls removed by the GoldSrc host and session telemetry. A new registration in the supported source syntax appears automatically; an unfamiliar registration module, unresolved public control or changed source contract stops the run for review instead of silently dropping entries.

`half-life-copy.js` contains readable descriptions, public label overrides and product summaries. It is the only hand-maintained feature-copy file. Do not hand-edit the generated manifest. New controls can appear with their actual source label before custom explanatory copy is added.

Only these three files are generated:

- `tools/features/features-half-life-1.json`
- `products/half-life-1/index.html` (feature highlights, intro, details and SEO metadata)
- `features-list/half-life-1-features/index.html`

The manifest supplies both pages' descriptions and search keywords. The existing SEO and feature-page generators also read it, so later builds preserve synchronized content. Source hashes are recorded in the manifest; local machine paths and timestamps are omitted to keep output deterministic. Runs recheck source and destination content before writing, stage temporary files, and restore their own writes if a write fails. Keep only one writer active; retry if an editor changes a file mid-run.

Navigation, Free badge, key access, guide links, screenshots, captions and the screenshot layout remain outside the generated region. The product summary shows the new counts; the searchable feature page contains the individual controls. A feature appearing in source is not proof of final runtime acceptance or release availability. Never infer verified builds or add hidden aim modes from capability declarations.

The requested Codex heartbeat checks this source-to-site sync every 30 minutes. It updates the local website files while the desktop automation can run. It does not build game DLLs, update downloads, commit, push or deploy the website. A changed source format requires reviewing and updating the extractor/copy before rerunning. Use the same script manually for an immediate update.

Active Codex automation: `sync-half-life-site-features` (30-minute heartbeat on Site and Loader Master). Created and enabled on 2026-09-22.
