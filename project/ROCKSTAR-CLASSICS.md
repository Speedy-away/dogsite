# Rockstar Classics

The collection at `/rockstar-classics/` follows the Source Games static-page pattern. Per-title details live at `/products/gta-sa/`, `/products/gta-vc/`, `/products/gta3/`, `/products/gta4/` and `/products/rdr1/`.

All five details use the shared GTA 5 / RDR2 product layout through `tools/rockstar-product-template.cjs`: artwork, access sidebar, description and title-specific availability. The older `/rockstar-classics/<id>/` URLs redirect to the corresponding product. Artwork is labeled as artwork, not gameplay evidence. Only released SA has the existing free-key dialog, download and feature-library actions; other titles retain unavailable access.

SA's searchable feature page lives at `/features-list/gta-sa-features/`. After reviewing the current SA source and acceptance limits, run `node tools/features/build-gta-sa-manifest.cjs`, then `node tools/features/build-features-page.js --only gta-sa --apply`. The manifest records source hashes, registered controls, reviewed ESP/teleport/interface entries and explicit unavailable features. A source entry is not a gameplay acceptance claim. Review the manually described entries when their sources change.

`assets/data/rockstar-classics.json` is a reviewed public snapshot of `Scooby-Op/old-rockstar-games/catalog.json`. It preserves family/title IDs, status, sync scope, runtime acceptance, settings directories and release artifacts. Machine-local install paths are intentionally omitted. The shared contract is documented in that repository's `docs/SYNC_AND_LUA.md`. This site change does not modify or publish the loader.

SA is Online as a free beta with a reviewed ZIP, version, size and SHA-256. Live gameplay and performance acceptance remain pending; Online describes release availability, not runtime acceptance. Vice City and GTA III remain development ports; GTA IV and RDR1 remain queued with no release artifacts. MTA stays outside this family. Do not derive availability from shared sync scope or the site's generic online status feed.

After reviewing upstream catalog changes, update the snapshot and run `node tools/build-rockstar-classics.cjs`. Before publishing a release link, fetch its live public metadata and ZIP and verify the version, SHA-256 and byte count. Preserve the beta and runtime acceptance caveat. Check generated output with `node tools/build-rockstar-classics.cjs --check` and exercise it with `node tools/validate-rockstar-classics.cjs` (Microsoft Edge / Playwright).

Run the repository's site and SEO checks, and regenerate the sitemap after adding routes. Screenshots are local QA output under `project/build/rockstar-classics/`.

`node tools/verify-sa-release.cjs <expected-version>` verifies the public SA release metadata, manifest hash, ZIP hash and byte count before importing that release into the snapshot. It writes local evidence to `project/build/sa-site/release-verification.json`; regenerate pages and validate after a successful import. Only SA is updated by this command. Publish through the existing GitHub Pages source (`main`, repository root).
