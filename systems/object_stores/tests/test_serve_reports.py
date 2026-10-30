"""The viewer server's report route: newest report only, and nothing unsafe is served."""

import json
import os
import sys
import tempfile
import threading
import unittest
import urllib.request
import urllib.error
from http.server import HTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "scripts"))
try:
    import serve_viewer as sv  # noqa: E402
    SKIP = ""
except SystemExit as e:  # pragma: no cover
    SKIP = str(e)

SECRET = "s3cr3t-value-123"
VALUES = [("S3_SECRET_KEY", SECRET)]


def report(name="Store A", result="PASS"):
    return {"kind": sv.REPORT_KIND, "schema_version": 1, "result": result, "store": {"name": name}, "checks": []}


def put(d: Path, name: str, doc, mtime=None):
    f = d / name
    f.write_text(doc if isinstance(doc, str) else json.dumps(doc), encoding="utf-8")
    if mtime:
        os.utime(f, (mtime, mtime))
    return f


class Latest(unittest.TestCase):
    def setUp(self):
        self._t = tempfile.TemporaryDirectory()
        self.d = Path(self._t.name)

    def tearDown(self):
        self._t.cleanup()

    def test_no_folder_or_no_files_is_404(self):
        self.assertEqual(sv.latest_report(self.d / "nope", VALUES)[0], 404)
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 404)

    def test_newest_file_wins(self):
        put(self.d, "a-20260101-000000.json", report("Old"), 1000)
        put(self.d, "b-20260102-000000.json", report("New"), 2000)
        code, body = sv.latest_report(self.d, VALUES)
        self.assertEqual((code, body["name"], body["report"]["store"]["name"]), (200, "b-20260102-000000.json", "New"))

    def test_other_names_and_markdown_are_ignored(self):
        put(self.d, "notes.json", report())
        put(self.d, "a-20260101-000000.md", "# x")
        put(self.d, "Bad Name-20260101-000000.json", report())
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 404)

    def test_symlink_is_ignored(self):
        outside = Path(tempfile.mkdtemp()) / "x.json"
        outside.write_text(json.dumps(report()))
        (self.d / "a-20260101-000000.json").symlink_to(outside)
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 404)

    def test_not_json_wrong_kind_and_too_big_are_refused(self):
        put(self.d, "a-20260101-000000.json", "not json")
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 422)
        put(self.d, "a-20260101-000000.json", {"kind": "something-else"})
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 422)
        put(self.d, "a-20260101-000000.json", json.dumps(report()) + " " * sv.MAX_REPORT)
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 422)

    def test_leaked_value_is_refused_and_not_in_the_reply(self):
        doc = report()
        doc["checks"] = [{"detail": f"key {SECRET}"}]
        put(self.d, "a-20260101-000000.json", doc)
        code, body = sv.latest_report(self.d, VALUES)
        self.assertEqual(code, 409)
        self.assertNotIn(SECRET, json.dumps(body))

    def test_newest_leaky_file_does_not_fall_back_to_an_older_clean_one(self):
        put(self.d, "a-20260101-000000.json", report("Old"), 1000)
        doc = report()
        doc["checks"] = [{"detail": SECRET}]
        put(self.d, "b-20260102-000000.json", doc, 2000)
        self.assertEqual(sv.latest_report(self.d, VALUES)[0], 409)


class Http(unittest.TestCase):
    def test_route_over_http(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            put(d, "a-20260101-000000.json", report("Over HTTP"))
            handler = sv.make_handler(sv.App("jdbc", None, False, 10), 0, None, {}, d)
            srv = HTTPServer(("127.0.0.1", 0), handler)
            port = srv.server_address[1]
            th = threading.Thread(target=srv.serve_forever, daemon=True)
            th.start()
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{port}/api/report/latest") as r:
                    self.assertEqual(r.status, 200)
                    self.assertEqual(json.loads(r.read())["report"]["store"]["name"], "Over HTTP")
                    self.assertEqual(r.headers["Cache-Control"], "no-store")
                req = urllib.request.Request(f"http://127.0.0.1:{port}/api/report/latest", headers={"Host": "evil.example"})
                with self.assertRaises(urllib.error.HTTPError) as cm:
                    urllib.request.urlopen(req)
                self.assertEqual(cm.exception.code, 403)
                cm.exception.close()
            finally:
                srv.shutdown()
                srv.server_close()


if SKIP:
    Latest = Http = None  # type: ignore

if __name__ == "__main__":
    unittest.main()
