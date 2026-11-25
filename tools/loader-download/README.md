# Portal loader downloads

The live GitHub Pages setup uses `assets/downloads/ScoobyLoader.exe`. The portal
requires a valid Scooby session before its download button fetches that public
file. Each click rechecks the session and generates a fresh cryptographically
random 32-character `.exe` filename. The executable bytes do not change.

The file URL itself is public, as requested. This is a portal login gate, not
server access control on the static file. `/download/` continues to direct users
to the portal; the actual loader download action is on the signed-in dashboard.

To update the live loader, replace `assets/downloads/ScoobyLoader.exe`, commit and
push to `main`, and wait for the Pages deployment. The config is in
`portal/loader-download-config.js`. Prefer a same-origin file URL; an external
file host must allow the site's CORS requests.

Run `node tools/test-loader-download.cjs` to check the portal flow, random
filenames, file checksum, expired sessions, and download page. Set
`LOADER_TEST_ORIGIN=https://scoobymenu.cc` to test the published files with mocked
portal sessions; this does not use a real customer's account.

## Optional protected download service

This is a separate Node.js 22+ service. GitHub Pages cannot run it. The public PS4
update manifests and packages are unchanged.

`GET /loader` requires the portal's `Authorization: Bearer <session token>` header.
Every request checks the session with ProudlyAuthentication before opening the
executable. Missing or expired sessions receive HTTP 401. An unavailable auth
service or loader returns HTTP 503; neither falls back to a public file link.

Every successful response uses a new cryptographically random 32-character `.exe`
filename through `Content-Disposition`. The executable bytes are unchanged.
Responses are never cached. CORS allows only the configured website origins.

## Run

1. Keep `ScoobyLoader.exe` in `tools/loader-download/private/`. That directory is ignored
   by Git. Never force-add it, upload it as a public GitHub release, or put it in
   a GitHub Pages assets folder. Alternatively, set `SCOOBY_LOADER_PATH` to a
   private absolute path outside the checkout.
2. Run `node tools/loader-download/server.cjs` from the repository root.
3. Place an HTTPS reverse proxy in front of `127.0.0.1:8787`, or deploy the service
   to a Node host that supplies TLS. The proxy must forward `Authorization` and
   `Origin`, preserve `Content-Disposition`, and never cache responses. Restrict
   the host to this service; do not serve its source/private directories as files.
4. Switching to this service requires a frontend handler that sends the portal
   bearer token to this endpoint and uses the response's `Content-Disposition`.
   The current frontend fetches a public static file without an auth header;
   changing its URL alone does not enable this optional service.
5. Run `node --test tools/loader-download/download.test.cjs` before deployment.

The site's `npm start` preview also serves this optional protected endpoint at
`/api/loader/download`. The current portal uses the public file instead.

Environment variables:

- `PORT`: default `8787`.
- `HOST`: default `127.0.0.1`. Use `0.0.0.0` if required by the chosen host.
- `SCOOBY_LOADER_PATH`: defaults to `private/ScoobyLoader.exe` beside `server.cjs`.
- `SCOOBY_ALLOWED_ORIGINS`: comma-separated exact origins; defaults to
  `https://scoobymenu.cc,https://www.scoobymenu.cc`.

No admin/API key is needed. The server validates the user's existing portal token
against the fixed portal session endpoint; the token never appears in a URL.

For testing the standalone service from a local website preview on port 8080,
add `http://127.0.0.1:8080` to `SCOOBY_ALLOWED_ORIGINS`.

To update the loader, stop the service, replace the private executable, and
restart. A new filename is generated on every download without changing the file.
