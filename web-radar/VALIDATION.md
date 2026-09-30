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
