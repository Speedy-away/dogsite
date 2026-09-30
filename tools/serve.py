"""Preview the static site, including the GitHub Pages custom 404 fallback."""

import argparse
import os
import subprocess
import sys
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class PreviewHandler(SimpleHTTPRequestHandler):
    # Windows MIME registries may omit WebP; match static hosting in previews.
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".webp": "image/webp"}

    def send_error(self, code, message=None, explain=None):
        if code == HTTPStatus.NOT_FOUND:
            try:
                body = (Path(self.directory) / "404.html").read_bytes()
            except OSError:
                # Still return a valid 404 if the custom page is unavailable.
                return super().send_error(code, message, explain)
            self.send_response(code)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)
            return
        return super().send_error(code, message, explain)

    def list_directory(self, path):
        self.send_error(HTTPStatus.NOT_FOUND)
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("port", nargs="?", type=int, default=8080)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--no-lua-sync", action="store_true", help="Do not start CS2 docs auto-sync")
    args = parser.parse_args()
    if not args.no_lua_sync:
        source = Path(os.environ.get("CS2_LUA_SOURCE_ROOT", ROOT.parent / "Scooby-Op/CS2/v2"))
        sync = source / "tools/sync_lua_site.py"
        if sync.is_file():
            result = subprocess.run([sys.executable, str(sync), "--background", "--site-root", str(ROOT)], check=False)
            if result.returncode:
                print("CS2 Lua docs sync failed; serving the last generated docs. See the error above.", flush=True)
    handler = partial(PreviewHandler, directory=str(ROOT))
    with ThreadingHTTPServer((args.bind, args.port), handler) as server:
        print(f"Serving {ROOT} at http://{args.bind}:{server.server_port}/", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")


if __name__ == "__main__":
    main()

