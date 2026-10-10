# Rockstar Classics

The collection at `/rockstar-classics/` follows the Source Games static-page pattern. Per-title details live at `/products/gta-sa/`, `/products/gta-vc/`, `/products/gta3/`, `/products/gta4/` and `/products/rdr1/`.

`assets/data/rockstar-classics.json` is a reviewed public snapshot of `Scooby-Op/old-rockstar-games/catalog.json`. It preserves family/title IDs, status, sync scope, runtime acceptance, settings directories and release artifacts. Machine-local install paths are intentionally omitted. The shared contract is documented in that repository's `docs/SYNC_AND_LUA.md`. This site change does not modify or publish the loader.

SA is Online as a free beta with a reviewed ZIP, version, size and SHA-256. Live gameplay and performance acceptance remain pending; Online describes release availability, not runtime acceptance. Vice City and GTA III remain development ports; GTA IV and RDR1 remain queued with no release artifacts. MTA stays outside this family. Do not derive availability from shared sync scope or the site's generic online status feed.

After reviewing upstream catalog changes, update the snapshot and run `node tools/build-rockstar-classics.cjs`. Before publishing a release link, fetch its live public metadata and ZIP and verify the version, SHA-256 and byte count. Preserve the beta and runtime acceptance caveat. Check generated output with `node tools/build-rockstar-classics.cjs --check` and exercise it with `node tools/validate-rockstar-classics.cjs` (Microsoft Edge / Playwright).

Run the repository's site and SEO checks, and regenerate the sitemap after adding routes. Screenshots are local QA output under `project/build/rockstar-classics/`.

`node tools/verify-sa-release.cjs <expected-version>` verifies the public SA release metadata, manifest hash, ZIP hash and byte count before importing that release into the snapshot. It writes local evidence to `project/build/sa-site/release-verification.json`; regenerate pages and validate after a successful import. Only SA is updated by this command. Publish through the existing GitHub Pages source (`main`, repository root).
