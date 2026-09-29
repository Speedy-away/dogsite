"""Routing checks for the local static preview server."""

from functools import partial
from http.client import HTTPConnection
from http.server import ThreadingHTTPServer
from pathlib import Path
from tempfile import TemporaryDirectory
from threading import Thread
import unittest

from serve import PreviewHandler


class QuietHandler(PreviewHandler):
    def log_message(self, *args):
        pass


class PreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = TemporaryDirectory()
        cls.root = Path(cls.temp.name)
        cls.error_page = b"<!doctype html><title>Not found</title><h1>404</h1>"
        (cls.root / "404.html").write_bytes(cls.error_page)
        (cls.root / "index.html").write_text("Home", encoding="utf-8")
        (cls.root / "guides").mkdir()
        (cls.root / "guides" / "index.html").write_text("Guides", encoding="utf-8")
        (cls.root / "empty").mkdir()
        (cls.root / "style.css").write_text("body { color: white; }", encoding="utf-8")
        cls.server = ThreadingHTTPServer(
            ("127.0.0.1", 0), partial(QuietHandler, directory=str(cls.root))
        )
        cls.thread = Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()
        cls.temp.cleanup()

    def request(self, path, method="GET"):
        connection = HTTPConnection(*self.server.server_address, timeout=5)
        try:
            connection.request(method, path)
            response = connection.getresponse()
            return response.status, dict(response.getheaders()), response.read()
        finally:
            connection.close()

    def test_missing_urls_use_custom_page_with_404_status(self):
        for path in ("/missing", "/missing/nested/?q=test", "/assets/missing.css", "/empty/"):
            with self.subTest(path=path):
                status, headers, body = self.request(path)
                self.assertEqual(status, 404)
                self.assertEqual(headers["Content-Type"], "text/html; charset=utf-8")
                self.assertEqual(body, self.error_page)

    def test_head_returns_404_headers_without_body(self):
        status, headers, body = self.request("/missing/nested/", "HEAD")
        self.assertEqual(status, 404)
        self.assertEqual(int(headers["Content-Length"]), len(self.error_page))
        self.assertEqual(body, b"")

    def test_existing_pages_and_assets_are_unchanged(self):
        for path, expected in (("/", b"Home"), ("/guides/", b"Guides"),
                               ("/404.html", self.error_page),
                               ("/style.css", b"body { color: white; }")):
            with self.subTest(path=path):
                status, _, body = self.request(path)
                self.assertEqual(status, 200)
                self.assertEqual(body, expected)

    def test_directory_redirect_preserves_query(self):
        status, headers, _ = self.request("/guides?q=setup")
        self.assertEqual(status, 301)
        self.assertEqual(headers["Location"], "/guides/?q=setup")

    def test_missing_error_document_uses_standard_fallback(self):
        page = self.root / "404.html"
        page.unlink()
        try:
            status, _, body = self.request("/missing")
            self.assertEqual(status, 404)
            self.assertIn(b"Error code: 404", body)
        finally:
            page.write_bytes(self.error_page)


if __name__ == "__main__":
    unittest.main()

