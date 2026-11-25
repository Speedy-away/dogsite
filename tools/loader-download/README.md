# Authenticated Windows loader downloads

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
4. Set the exact HTTPS `/loader` URL in the website's
   `portal/loader-download-config.js` as `window.scoobyLoaderDownloadUrl`.
5. Run `node --test tools/loader-download/download.test.cjs` before deployment.

The site's `npm start` preview already serves the protected endpoint at
`/api/loader/download` and uses the same private executable. The production URL
is intentionally unset until the service has a real HTTPS host. Run
`project/update-loader-url.ps1 https://your-download-host/loader` to configure it.

Environment variables:

- `PORT`: default `8787`.
- `HOST`: default `127.0.0.1`. Use `0.0.0.0` if required by the chosen host.
- `SCOOBY_LOADER_PATH`: defaults to `private/ScoobyLoader.exe` beside `server.cjs`.
- `SCOOBY_ALLOWED_ORIGINS`: comma-separated exact origins; defaults to
  `https://scoobymenu.cc,https://www.scoobymenu.cc`.

No admin/API key is needed. The server validates the user's existing portal token
against the fixed portal session endpoint; the token never appears in a URL.

For a local website preview on port 8080, add `http://127.0.0.1:8080` to
`SCOOBY_ALLOWED_ORIGINS` and set the website URL to
`http://127.0.0.1:8787/loader` locally. Use HTTPS service URLs in production.

To update the loader, stop the service, replace the private executable, and
restart. A new filename is generated on every download without changing the file.
