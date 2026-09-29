"""Preview the static site, including the GitHub Pages custom 404 fallback."""

import argparse
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class PreviewHandler(SimpleHTTPRequestHandler):
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
    args = parser.parse_args()
    handler = partial(PreviewHandler, directory=str(ROOT))
    with ThreadingHTTPServer((args.bind, args.port), handler) as server:
        print(f"Serving {ROOT} at http://{args.bind}:{server.server_port}/", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")


if __name__ == "__main__":
    main()

