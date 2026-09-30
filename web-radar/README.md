# Scooby Web Radar

The CS2 host publishes snapshots over HTTPS to this relay. Viewers open
`https://scoobymenu.cc/web-radar/<32-random-hex-characters>`. The host never
opens an inbound port, and viewers never connect to localhost or the host's IP.
Your server relays data; the game client remains the only source of live state.
This uses outbound HTTPS and server-sent events, not peer-to-peer hosting.

## Files

- `index.html`, `radar.css`, `app.mjs`, `render.mjs`: responsive viewer, no framework/CDN.
- `maps/`: exact PNGs extracted from the existing CS2 radar source; provenance hashes in `manifest.json`.
- `relay/`: Node service and real HTTP/SSE regression tests. No npm packages required.
- `deploy/`: example Caddy reverse proxy and systemd unit for a VPS.
- `tools/`: map export and build/validation helpers.

## Run locally

Use Node 22 or newer. From the dogsite root:

```powershell
node --test web-radar/relay/server.test.mjs
node web-radar/relay/server.mjs
```

Open `http://127.0.0.1:8787/web-radar/`. Generate a session using the integration
fixture in the tests when validating without CS2. The production DLL uses only
`https://scoobymenu.cc`; there is deliberately no arbitrary host/token setting.
Local testing does not make the public domain work.

## Deployment needed

The current site uses GitHub Pages. Pages serves static files and cannot execute
this service or maintain live connections. A production relay and HTTPS path
route must be deployed before **Generate link** can succeed in the game.

One complete option is a VPS:

1. Copy the complete dogsite checkout to `/srv/dogsite`, with Node 22+ and Caddy
   installed. Keep the checkout current through the existing release workflow.
2. Install `deploy/scooby-web-radar.service` in the systemd unit directory, then
   enable/start it. The service binds **only** to `127.0.0.1:8787`.
3. Merge `deploy/Caddyfile` into the server configuration. It serves your existing
   site and forwards only `/web-radar` and `/web-radar/*` to the relay. Do not put
   CDN caching or response buffering on the API/events paths.
4. After testing the host, point `scoobymenu.cc` DNS to that server. This changes
   the site hosting from GitHub Pages; it is an explicit deployment decision.
   Alternatively retain Pages behind an edge path proxy to the VPS. Configure
   that proxy to bypass caching and replace forwarded IP headers. A static Pages
   upload by itself is insufficient. A Cloudflare-only deployment would need a
   Worker/Durable Object adapter; the Node relay is not a Worker script.
5. Verify HTTPS, generate/copy a link in CS2, open it on a separate device/network,
   test Stop, disconnect, match end, map/gamemode change and game exit.

No DNS, account settings, deployments or site publication are performed by these files.
The ordinary static preview (`serve.bat`) does not run the live relay.

## Session behavior

- Generate rotates the 128-bit viewer ID and separate 256-bit publisher key.
  The publisher key stays in memory and is sent only in an Authorization header.
  Viewer links cannot publish or stop a session. Treat viewer links as private.
- Only the auto reconnect preference is saved. Loading a config never starts
  sharing, and no session credentials/links are written into configs or logs.
- Auto reconnect keeps the link while maps/modes change. Waiting snapshots have
  no entities. With auto reconnect off, leaving a match ends sharing after a
  two-second transition grace; changing maps ends it immediately.
- Match-end detection uses the replicated `m_nMatchEndCount`, latched until a
  new rules/map identity or game phase. Ordinary round endings and dying do not
  intentionally close a session. Native game behavior still needs acceptance.
- The host samples at most 10 Hz. Network/JSON work runs on a joined worker;
  it retains one latest frame and never queues historical positions. If Present
  stops for 1.5 seconds, it sends empty waiting frames.
- The relay clears stale data after 3 seconds without publishing and expires the
  link after 30 seconds. It also expires after 30 minutes without a live match,
  or 12 hours total. A new Generate is required after expiry or a server restart.
- Stop, panic mode and clean DLL unload close the room. Crashes use server expiry.
- Limits: 200 rooms, 5 per IP, 10 creates/minute/IP, 32 viewers/room, 256 total viewers, 25 publish
  requests/second, 256 KiB/frame, 512 entities/frame. Slow readers are disconnected.
  Behind another proxy, review the forwarded-IP trust chain before enabling
  `RADAR_TRUST_PROXY=1`. No account/license service was added to the public relay.

## Snapshot protocol v1

`PUT /web-radar/api/session/:id` creates a session idempotently, `POST` updates it,
and `DELETE` closes it. Each requires `Authorization: Bearer <64 hex chars>`.
`GET /web-radar/api/session/:id/events` receives `frame`, `avatar`, `status`,
`heartbeat`, and `ended` events. All API responses use `no-store`; sessions remain in RAM only.
An expired ID cannot be revived during the bounded tombstone retention period.

`frame` fields are `version`, increasing `seq`, `state` (`live`/`waiting`),
`keepLink`, `map`, `layer`, `calibration`, and `entities`. Calibration is the exact
host Quick Map transform (`x`, `y`, `scale`, `size`, `offsetX`, `offsetY`, `zoom`).
Kinds: 0 player, 1 planted bomb, 2 dropped bomb, 3 smoke, 4 fire, 5 grenade,
6 dropped weapon, 7 hostage. There are at most 64 player markers. Team numbers are native 2=T and 3=CT, independent
of the host's team. The viewer also shows active weapon, HP, armor, money,
local-player marker, bomb carrier, defuse state and planted timer when available.
Upper/lower layers use the same Nuke/Train/Vertigo/Baggage thresholds as Quick Map.
Uncalibrated maps show the roster without fabricated map positioning.

Map images come from this project's existing assets. The linked clauadv project
was consulted for the sharing concept; no GPL implementation was copied.

## Refresh maps

```powershell
python web-radar/tools/export-maps.py --source ../Scooby-Op/CS2/v2/src/GUI/overlay/map_images
```

Re-run after updating CS2 overview assets, then compare `maps/manifest.json`.
New map calibration remains owned by the CS2 source.

## Steam avatars and profile links

Player `steamId` is an optional decimal string. It must identify a public
individual desktop Steam account; zero/bot IDs become an empty string. JSON
numbers are rejected to avoid losing precision. The avatar, name and Steam
profile label open `https://steamcommunity.com/profiles/<steamId>/` with a new-tab
native link and `noopener noreferrer`. Bots/unavailable identities show a generic
avatar and no link; valid accounts without an image keep their profile link.

The host obtains small avatars from Steam's native friends/utilities APIs. No
Steam Web API key is required and the website makes no Steam profile/API fetches.
Optional publisher `avatars` contains up to two `{steamId, rgba}` entries per
snapshot: exactly 32x32 RGBA pixels, canonical base64 (4096 bytes / 5464 characters),
and only IDs present in that snapshot's player roster. The relay converts the
fixed-size pixels into PNG; it does not fetch publisher URLs or decode supplied
image formats. Regular `frame` events exclude avatar uploads. Separate `avatar`
events carry `{steamId, image}` with a `data:image/png;base64,...` image.

Images are sent only when changed, cached in the current room, delivered once to
new viewers, and pruned when their player leaves or the host sends a waiting
snapshot. A host acknowledges images only after successful publishing. Stale
reconnects restore the cache without changing its ownership. Cards preserve DOM
nodes when stats change, keeping profile keyboard focus and loaded images stable.

## Direct PC hosting alternative

The current transport above forwards all snapshots through the relay. Direct
PC-to-viewer hosting is a separate transport change and is not implemented here.
For that model the PC owns each live session, the site serves the viewer at the
same clean share URL, a small signaling service associates that random ID with
the connected host, and WebRTC data channels carry updates directly where possible.
A TURN relay is needed as fallback for networks that prevent direct connections.
GitHub Pages can continue serving static assets but cannot perform signaling or
TURN. This design still needs a deployed connection service; a random site URL
alone cannot discover and connect to a private PC through arbitrary routers.

References: [WebRTC connectivity](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API/Connectivity),
[GitHub Pages hosting](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages),
and [Steam friends/avatar API](https://partner.steamgames.com/doc/api/ISteamFriends?l=english).
