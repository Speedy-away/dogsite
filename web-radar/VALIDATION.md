# Validation — 2026-10-01

Local implementation checks passed; the production relay is not deployed.

- `dogsite.sln` Release x64 Build succeeded using the Node/PowerShell wrapper.
- Six Node tests exercise actual HTTP publishing and SSE viewers, source isolation,
  publisher authentication, concurrent ownership, malformed/oversized payloads,
  per-room/creation limits, stale clearing, map transitions, Stop, tombstones and expiry.
- Canonical map projection and floor threshold tests passed.
- Headless Edge passed the scenarios recorded in
  `build/web-radar-validation/browser-results.json` (relative to dogsite).
- Desktop, 375px phone, landscape, waiting and ended captures are in that folder.
  Gameplay data is synthetic and player labels carry `[TEST]`.
- All 24 exported PNG hashes match the recorded CS2 source bytes.
- Both CS2 Release DLL candidates compile under their project
  `build/web-radar-20261001/x64/Release/` folders; their protocol/lifecycle and radar
  regression suites passed. Refer to each project's dated Web Radar guide for hashes.

Not tested: deployed HTTPS path, production DNS/CDN/proxy behavior, Caddy/systemd
on a Linux server, real CS2 game/session transitions, remote viewing from another
network, foreground FPS or native Linux/Proton. No site publication occurred.

## Steam profile follow-up

- Website Release x64 solution Build passed all eight Node tests, including strict
  string Steam IDs, canonical fixed-size avatar payloads, PNG pixel round-trip,
  separate SSE image events, new-viewer cache, stale recovery and roster pruning.
- Headless Edge passed profile URL/new-tab navigation with a locally intercepted
  Steam response, `window.opener === null`, keyboard focus through stat updates,
  loaded avatar display, bot/broken-image fallbacks, identity-slot replacement,
  avatar restoration after match transitions and the existing live radar flows.
- Desktop/375px screenshots were visually checked after correcting SVG fallback
  visibility. Images and all player data are synthetic; the test contacts no
  public Steam account. Results/captures replace the previous browser fixture run
  under `build/web-radar-validation/`.
- New native candidates are under each CS2 edition's
  `build/web-radar-steam-20261001/x64/Release/`. The base build passed normally.
  v2's normal build is blocked by an unrelated existing merge conflict in
  `tools/build-cs2-docs.js`; its native-only build passed with a generated override
  that skips the documentation sync. Both editions' expanded protocol tests passed.
- Real Steam image retrieval in CS2, actual game performance, direct peer hosting
  and external-network operation remain untested. No service was deployed.
