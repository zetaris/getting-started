"""Tests for report.py with a fake S3 client and a fake Zetaris channel.

They need boto3 (the venv); without it they are skipped:

    .venv/bin/python -m unittest discover systems/object_stores/tests

Every value is invented.
"""

import json
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
try:
    import report as rp
    import probe_s3
    import s3_settings as s3
    import verify_chain as vc
    from botocore.exceptions import ClientError, EndpointConnectionError, SSLError
except SystemExit:  # boto3 is not installed in this Python
    rp = vc = None

import leaks  # noqa: E402

needs_boto = unittest.skipIf(rp is None, "boto3 is not installed in this Python; use the venv")
FOLDER = "t-folder-9/"


def client_error(code="AccessDenied", status=403, op="X"):
    return ClientError({"Error": {"Code": code, "Message": "denied"}, "ResponseMetadata": {"HTTPStatusCode": status}}, op)


class FakeS3:
    """Enough of an S3 client for the report."""

    def __init__(self, batch=True, lock=None, versioning=None, fail_get=False, fail_put=False):
        self.objs: dict[str, bytes] = {}
        self.batch, self.lock, self.versioning, self.fail_get, self.fail_put = batch, lock, versioning, fail_get, fail_put

    def head_bucket(self, Bucket):
        return {}

    def head_object(self, Bucket, Key):
        if Key not in self.objs:
            raise client_error("404", 404, "HeadObject")
        return {}

    def put_object(self, Bucket, Key, Body):
        if self.fail_put:
            raise client_error("AccessDenied", 403, "PutObject")
        self.objs[Key] = Body

    def get_object(self, Bucket, Key):
        if self.fail_get:
            raise client_error("NoSuchKey", 404, "GetObject")
        import io
        return {"Body": io.BytesIO(self.objs[Key])}

    def delete_object(self, Bucket, Key):
        self.objs.pop(Key, None)

    def delete_objects(self, Bucket, Delete):
        if not self.batch:
            raise client_error("NotImplemented", 501, "DeleteObjects")
        for o in Delete["Objects"]:
            self.objs.pop(o["Key"], None)
        return {}

    def get_paginator(self, name):
        me = self

        class P:
            def paginate(self, Bucket, Prefix=""):
                yield {"Contents": [{"Key": k, "Size": len(v)} for k, v in sorted(me.objs.items()) if k.startswith(Prefix)]}
        return P()

    def get_object_lock_configuration(self, Bucket):
        if self.lock is None:
            raise client_error("ObjectLockConfigurationNotFoundError", 404, "GetObjectLockConfiguration")
        return {"ObjectLockConfiguration": {"ObjectLockEnabled": self.lock}}

    def get_bucket_versioning(self, Bucket):
        return {"Status": self.versioning} if self.versioning else {}


def settings(addressing="path", region="us-east-1"):
    return s3.Settings("https://s3.fake-store.example:9021", "AKIAFAKE00000001", "fakesecret/0002", "fake-bucket-0003", region, addressing, None)


def attempts(good=(("path", "us-east-1"), ("path", "us-west-2"), ("virtual", "us-east-1")), client=None, bad_error=None):
    out = []
    for style in ("path", "virtual"):
        for region in ("us-east-1", "us-west-2", "eu-west-1"):
            if (style, region) in good:
                out.append(probe_s3.Attempt(style, region, client))
            else:
                out.append(probe_s3.Attempt(style, region, error=bad_error or client_error()))
    return out


def new_report(store_only=False, cleanup=False):
    r = rp.RunReport({"name": "Acme StoreX", "vendor": "Acme", "product": "StoreX"}, "store-only" if store_only else "full", cleanup)
    r.settings = {"addressing": "path", "region": "us-east-1", "ca_bundle": "default", "endpoint_scheme": "https"}
    return r


def status(rep, id):
    return rep.get(id).status


@needs_boto
class Overall(unittest.TestCase):
    def test_pass_fail_incomplete(self):
        r = new_report()
        r.add("a", "a", "PASS")
        r.add("b", "b", "INFO", required=False)
        self.assertEqual(r.overall(), "PASS")
        r.skip("c", "c", "later", required=True)
        self.assertEqual(r.overall(), "INCOMPLETE")
        r.add("d", "d", "FAIL", required=True)
        self.assertEqual(r.overall(), "FAIL")

    def test_optional_failures_and_skips_do_not_count(self):
        r = new_report()
        r.add("a", "a", "PASS")
        r.add("b", "b", "FAIL", required=False)
        r.skip("c", "c", "x", required=False)
        self.assertEqual(r.overall(), "PASS")


@needs_boto
class StoreChecks(unittest.TestCase):
    def run_store(self, att, st=None):
        r = new_report()
        c = rp.check_store(r, st or settings(), FOLDER, att)
        return r, c

    def test_everything_works(self):
        fake = FakeS3(versioning="Enabled")
        r, c = self.run_store(attempts(client=fake))
        for id_ in ("store.connect", "store.tls", "store.addressing", "store.region", "store.list", "store.putgetdelete", "store.batch_delete"):
            self.assertEqual(status(r, id_), "PASS", id_)
        self.assertEqual(status(r, "store.retention"), "INFO")
        self.assertIn("versioning: Enabled", r.get("store.retention").detail)
        self.assertTrue(any("versioning is enabled" in n.lower() for n in r.get("store.retention").notes))
        self.assertIs(c, fake)
        self.assertEqual(fake.objs, {}, "the checks must clean up after themselves")

    def test_tls_failure_stops_the_rest(self):
        r, c = self.run_store(attempts(good=(), bad_error=SSLError(endpoint_url="x", error="CERTIFICATE_VERIFY_FAILED")))
        self.assertIsNone(c)
        self.assertEqual((status(r, "store.connect"), status(r, "store.tls")), ("FAIL", "FAIL"))
        self.assertIn("S3_CA_BUNDLE", r.get("store.tls").notes[0])
        self.assertEqual(status(r, "store.putgetdelete"), "SKIP")
        self.assertEqual(r.overall(), "FAIL")

    def test_unreachable_endpoint_does_not_blame_tls(self):
        r, _ = self.run_store(attempts(good=(), bad_error=EndpointConnectionError(endpoint_url="x")))
        self.assertEqual((status(r, "store.connect"), status(r, "store.tls")), ("FAIL", "SKIP"))

    def test_http_error_means_tls_worked(self):
        r, _ = self.run_store(attempts(good=(), bad_error=client_error("AccessDenied")))
        self.assertEqual((status(r, "store.connect"), status(r, "store.tls")), ("FAIL", "PASS"))

    def test_wrong_addressing_is_reported_with_the_fix(self):
        fake = FakeS3()
        r, c = self.run_store(attempts(good=(("virtual", "us-east-1"),), client=fake), settings("path"))
        self.assertEqual(status(r, "store.addressing"), "FAIL")
        self.assertIn("S3_ADDRESSING=virtual", r.get("store.addressing").notes[0])
        self.assertEqual(status(r, "store.region"), "FAIL")
        self.assertTrue(any("used virtual-style" in o for o in r.observations))
        self.assertIs(c, fake)  # later checks still ran, with the combination that worked

    def test_region_rejected_but_style_ok(self):
        r, _ = self.run_store(attempts(good=(("path", "us-west-2"),), client=FakeS3()), settings("path", "us-east-1"))
        self.assertEqual((status(r, "store.addressing"), status(r, "store.region")), ("PASS", "FAIL"))

    def test_batch_delete_unsupported_falls_back(self):
        fake = FakeS3(batch=False)
        r, _ = self.run_store(attempts(client=fake))
        self.assertEqual(status(r, "store.batch_delete"), "INFO")
        self.assertFalse(r.get("store.batch_delete").required)
        self.assertEqual(fake.objs, {}, "the fallback must delete the test objects")

    def test_object_lock_is_noted(self):
        r, _ = self.run_store(attempts(client=FakeS3(lock="Enabled")))
        self.assertIn("object lock: Enabled", r.get("store.retention").detail)
        self.assertTrue(any("refused" in n for n in r.get("store.retention").notes))

    def test_put_failure_is_reported_by_step(self):
        r, _ = self.run_store(attempts(client=FakeS3(fail_put=True)))
        self.assertEqual(status(r, "store.putgetdelete"), "FAIL")
        self.assertIn("put failed", r.get("store.putgetdelete").detail)

    def test_get_failure_is_reported_by_step(self):
        r, _ = self.run_store(attempts(client=FakeS3(fail_get=True)))
        self.assertIn("get failed", r.get("store.putgetdelete").detail)

    def test_all_regions_accepted_is_observed(self):
        every = tuple(("path", reg) for reg in ("us-east-1", "us-west-2", "eu-west-1"))
        r, _ = self.run_store(attempts(good=every, client=FakeS3()))
        self.assertTrue(any("ignores the region" in o for o in r.observations))


class Res:
    def __init__(self, rows):
        self.rows, self.columns = rows, []


class FakeChannel:
    name = "jdbc"

    def __init__(self, counts=None, materialize="SUCCESS", boom=None):
        self.counts = counts if counts is not None else {"sic_code": 1005, "company": 7}
        self.materialize, self.boom, self.closed, self.sql = materialize, boom, False, []

    def run(self, sql, limit=100):
        self.sql.append(sql)
        if self.boom:
            raise self.boom
        if sql.startswith("SELECT 1"):
            return Res([[1]])
        if sql.startswith("SELECT COUNT(*)"):
            return Res([[self.counts[sql.rsplit(".", 1)[1]]]])
        if sql.startswith("MATERIALIZE"):
            return Res([["s3a://x", self.materialize, None, None]])
        raise AssertionError(sql)

    def close(self):
        self.closed = True


def chain(ok=True):
    r = vc.Report("x")
    r.stage("4  USL table", 7, 7 if ok else 8)
    return r


class Api:
    def __init__(self, create=(200, {"id": "abc-123"}), delete=(200, None)):
        self.calls, self.create, self.delete = [], create, delete

    def __call__(self, method, path, body=None):
        self.calls.append((method, path))
        return self.create if method == "POST" else self.delete


@needs_boto
class ZetarisChecks(unittest.TestCase):
    def run_z(self, channel=None, api=None, chain_sic=None, chain_co=None, parquet=True):
        fake = FakeS3()
        rep = new_report()
        ch = channel or FakeChannel()
        api = api or Api()
        pq = {f"{FOLDER}usl_demo/sic_edgar_usl/t": (["a", "b"], [("1", "2")])} if parquet else {}
        with mock.patch.object(vc, "chain_sic_code", chain_sic or (lambda *a: (chain(), {"1"}))), \
             mock.patch.object(vc, "chain_company", chain_co or (lambda *a: chain())), \
             mock.patch.object(vc, "parquet_rows", lambda *a: pq):
            rp.check_zetaris(rep, settings(), fake, FOLDER, rp.DEFAULT_USL, lambda: ch, api)
        return rep, ch, api

    def test_all_good(self):
        r, ch, api = self.run_z()
        for id_ in ("zetaris.connect", "zetaris.usl", "zetaris.setting", "materialize.sic_code", "materialize.company",
                    "parquet.sic_code", "parquet.company", "chain.sic_code", "chain.company", "zetaris.setting_removed"):
            self.assertEqual(status(r, id_), "PASS", id_)
        self.assertEqual(api.calls, [("POST", "/storage-setting"), ("DELETE", "/storage-setting/abc-123")])
        self.assertTrue(ch.closed)
        self.assertEqual(sum(1 for s in ch.sql if s.startswith("MATERIALIZE")), 2)

    def test_no_connection_skips_everything_after(self):
        r, _, api = self.run_z(channel=FakeChannel(boom=RuntimeError("refused")))
        self.assertEqual(status(r, "zetaris.connect"), "FAIL")
        for id_ in ("zetaris.usl", "materialize.sic_code", "chain.company"):
            self.assertEqual(status(r, id_), "SKIP", id_)
        self.assertEqual(api.calls, [])

    def test_missing_usl_skips_materialize(self):
        r, ch, api = self.run_z(channel=FakeChannel(counts={"sic_code": 0, "company": 0}))
        self.assertEqual(status(r, "zetaris.usl"), "FAIL")
        self.assertIn("HOWTO step 5", r.get("zetaris.usl").notes[0])
        self.assertEqual(status(r, "materialize.sic_code"), "SKIP")
        self.assertFalse(any(s.startswith("MATERIALIZE") for s in ch.sql))
        self.assertEqual(api.calls, [], "no storage setting is created when the test cannot go on")

    def test_setting_failure_does_not_stop_the_test(self):
        r, _, api = self.run_z(api=Api(create=(400, {"msg": "already exists"})))
        self.assertEqual(status(r, "zetaris.setting"), "FAIL")
        self.assertEqual(status(r, "materialize.sic_code"), "PASS")
        self.assertIsNone(r.get("zetaris.setting_removed"))
        self.assertEqual(api.calls, [("POST", "/storage-setting")])

    def test_failed_materialize_is_recorded_and_chain_still_runs(self):
        r, _, _ = self.run_z(channel=FakeChannel(materialize="Error"))
        self.assertEqual(status(r, "materialize.sic_code"), "FAIL")
        self.assertEqual(status(r, "chain.sic_code"), "PASS")

    def test_no_parquet_found(self):
        r, _, _ = self.run_z(parquet=False)
        self.assertEqual(status(r, "parquet.sic_code"), "FAIL")

    def test_a_broken_chain_fails(self):
        r, _, _ = self.run_z(chain_co=lambda *a: chain(ok=False))
        self.assertEqual(status(r, "chain.company"), "FAIL")
        self.assertEqual(status(r, "chain.sic_code"), "PASS")
        self.assertIn("stages", r.get("chain.company").data)

    def test_sic_chain_error_skips_company(self):
        def boom(*a):
            raise OSError("api down")
        r, _, _ = self.run_z(chain_sic=boom)
        self.assertEqual(status(r, "chain.sic_code"), "FAIL")
        self.assertEqual(status(r, "chain.company"), "SKIP")


@needs_boto
class Cleanup(unittest.TestCase):
    def test_dry_run_counts_and_skips(self):
        fake = FakeS3()
        fake.objs = {FOLDER + "a": b"1234", FOLDER + "b": b"12"}
        r = new_report()
        rp.check_cleanup(r, settings(), fake, FOLDER, False)
        c = r.get("cleanup")
        self.assertEqual((c.status, c.required), ("SKIP", False))
        self.assertIn("2 object(s), 6 bytes", c.detail)
        self.assertEqual(len(fake.objs), 2, "a dry run deletes nothing")

    def test_cleanup_deletes_only_the_folder(self):
        fake = FakeS3()
        fake.objs = {FOLDER + "a": b"1", FOLDER + "sub/b": b"1", "someone-else/x": b"1", "t-folder-90/y": b"1"}
        r = new_report(cleanup=True)
        rp.check_cleanup(r, settings(), fake, FOLDER, True)
        self.assertEqual(status(r, "cleanup"), "PASS")
        self.assertEqual(sorted(fake.objs), ["someone-else/x", "t-folder-90/y"])

    def test_leftovers_fail(self):
        fake = FakeS3()
        fake.objs = {FOLDER + "a": b"1"}
        fake.delete_objects = lambda **k: {"Errors": [{"Key": FOLDER + "a"}]}
        fake.delete_object = lambda **k: (_ for _ in ()).throw(client_error("AccessDenied", 403, "DeleteObject"))
        r = new_report(cleanup=True)
        rp.check_cleanup(r, settings(), fake, FOLDER, True)
        self.assertEqual(status(r, "cleanup"), "FAIL")

    def test_unreachable_store(self):
        r = new_report()
        rp.check_cleanup(r, settings(), None, FOLDER, True)
        self.assertEqual((status(r, "cleanup"), r.get("cleanup").required), ("SKIP", True))


@needs_boto
class Orchestration(unittest.TestCase):
    def test_store_only_needs_no_zetaris(self):
        rep = rp.build_report(settings(), names={"S3_STORE_PRODUCT": "StoreX"}, folder=FOLDER, usl=rp.DEFAULT_USL, verify=True,
                              do_cleanup=False, store_only=True, attempts_fn=lambda st, v: attempts(client=FakeS3()))
        self.assertEqual(rep.overall(), "PASS")
        self.assertEqual(rep.scope, "store-only")
        self.assertEqual(status(rep, "materialize.sic_code"), "SKIP")
        self.assertFalse(rep.get("materialize.sic_code").required)
        self.assertEqual(rep.store["name"], "StoreX")

    def test_unreachable_bucket_skips_zetaris_and_fails(self):
        rep = rp.build_report(settings(), names={}, folder=FOLDER, usl=rp.DEFAULT_USL, verify=True, do_cleanup=True, store_only=False,
                              attempts_fn=lambda st, v: attempts(good=()), channel_factory=lambda: self.fail("must not connect"))
        self.assertEqual(rep.overall(), "FAIL")
        self.assertEqual(status(rep, "zetaris.connect"), "SKIP")
        self.assertEqual(rep.store["name"], "your S3-compatible object store")


@needs_boto
class Output(unittest.TestCase):
    SECRET = "fakesecret/0002"
    BUCKET = "fake-bucket-0003"

    def doc(self, detail="ok", data=None):
        r = new_report()
        r.add("store.connect", "Reach the bucket", "FAIL", detail, data=data or {})
        return r.to_dict(__import__("datetime").datetime(2026, 10, 30), rp.environment())

    def values(self):
        return [("S3_SECRET_KEY", self.SECRET), ("S3_BUCKET", self.BUCKET), ("S3_ENDPOINT_URL", "https://s3.fake-store.example:9021"),
                ("S3_ENDPOINT_URL (host)", "s3.fake-store.example"), ("your login name", "testuser-zzz")]

    def test_values_in_text_are_redacted_not_leaked(self):
        js, md, problems = rp.safe_outputs(self.doc(f"HTTP 403 on {self.BUCKET} at https://s3.fake-store.example:9021 with {self.SECRET}"), self.values())
        self.assertEqual(problems, [])
        for text in (js, md):
            self.assertNotIn(self.SECRET, text)
            self.assertNotIn(self.BUCKET, text)
            self.assertNotIn("fake-store.example", text)
        self.assertIn("<bucket>", js)
        self.assertIn("<endpoint>", js)

    def test_a_value_the_redactor_cannot_reach_blocks_the_write(self):
        # dictionary keys are not redacted, so a secret used as a key must be caught by the final check
        _, _, problems = rp.safe_outputs(self.doc(data={self.SECRET: 1}), self.values())
        self.assertEqual(problems, ["S3_SECRET_KEY"])

    def test_json_is_the_contract(self):
        js, md, _ = rp.safe_outputs(self.doc(), self.values())
        d = json.loads(js)
        self.assertEqual((d["schema_version"], d["kind"]), (1, "zetaris-object-store-report"))
        self.assertEqual(set(d["summary"]), {"pass", "fail", "skip", "info"})
        self.assertEqual(d["checks"][0]["status"], "FAIL")
        self.assertIn("**Result:** FAIL", md)

    def test_markdown_is_rendered_from_the_json_and_escapes_pipes(self):
        md = rp.render_markdown(json.loads(rp.safe_outputs(self.doc("a | b\nc"), [])[0]))
        self.assertIn("| FAIL | Reach the bucket | a / b c |", md)

    def test_slug(self):
        self.assertEqual(rp.slug("Acme StoreX 9000!"), "acme-storex-9000")
        self.assertEqual(rp.slug(""), "object-store")
        self.assertLessEqual(len(rp.slug("x" * 100)), 40)


class LeaksModule(unittest.TestCase):
    def test_redact_longest_first(self):
        vals = [("your home folder", "/Users/jane"), ("your login name", "jane")]
        self.assertEqual(leaks.redact("/Users/jane/x for jane", vals), "<home>/x for <user>")

    def test_found_in_reports_names_only(self):
        self.assertEqual(leaks.found_in("a secret-value-1 b", [("S3_SECRET_KEY", "secret-value-1"), ("S3_BUCKET", "nope-nope")]), ["S3_SECRET_KEY"])


if __name__ == "__main__":
    unittest.main()
