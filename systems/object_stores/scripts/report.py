"""Run the object store test end to end and write a conformance report.

    .venv/bin/python systems/object_stores/scripts/report.py              # run everything; cleanup is a dry run
    .venv/bin/python systems/object_stores/scripts/report.py --cleanup    # also clear your folder afterwards
    .venv/bin/python systems/object_stores/scripts/report.py --store-only # only the object store, no Zetaris

It performs steps 8 to 11 of the HOWTO and the bucket part of step 15 (this is step 14) in order, using the same functions
as the individual scripts, and records each outcome as PASS, FAIL, SKIP or INFO:

    the object store    reachable, TLS trusted, addressing style, region, list, put/get/delete,
                        batch delete, object lock and versioning
    Zetaris             connection, the sic_edgar_usl USL present, a storage setting created
    the data            MATERIALIZE USL TABLE for sic_code and company, the Parquet files read
                        back, and the row counts equal from the source API to the Parquet file
    cleanup             your own folder cleared (only with --cleanup; otherwise a dry run)

A failure that makes later steps meaningless (no connection to the bucket, no
Zetaris, no USL) stops those steps; they are recorded as SKIP with the reason.
Anything unexpected goes in "observations".

It writes reports/<store>-<date>-<time>.json (the contract: a schema version, the
checks) and a .md rendered from it. Both are meant to be sent to someone else, so
nothing from .env.local may appear in them: keys, passwords, bucket, endpoint,
folder, user agent, your login name and home folder are replaced with
placeholders, and the report is not written at all if one is still found.

Needs the USL from the HOWTO (step 5). Exit code: 0 PASS, 1 FAIL, 3 INCOMPLETE
(a required step was skipped), 2 the report could not be written safely.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import platform
import re
import sys
import uuid
from dataclasses import asdict, dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import leaks  # noqa: E402
import render as renderer  # noqa: E402
import s3_settings as s3  # noqa: E402
import zetaris_sql as z  # noqa: E402
from botocore.exceptions import BotoCoreError, ClientError, SSLError  # noqa: E402
from quiet import quiet_stderr  # noqa: E402

import cleanup_bucket  # noqa: E402
import materialize_usl_table as mat  # noqa: E402
import probe_s3  # noqa: E402
import storage_setting  # noqa: E402
import verify_chain as vc  # noqa: E402

SCHEMA_VERSION = 1
STATUSES = ("PASS", "FAIL", "SKIP", "INFO")
DEFAULT_USL = vc.DEFAULT_USL
TABLES = ("sic_code", "company")
SCHEMA_FILE = HERE.parent / "settings.json"


# --- the record -------------------------------------------------------------

@dataclass
class Check:
    id: str
    title: str
    status: str
    detail: str = ""
    required: bool = True
    notes: list[str] = field(default_factory=list)
    data: dict = field(default_factory=dict)


class RunReport:
    def __init__(self, store: dict, scope: str, cleanup_requested: bool) -> None:
        self.store, self.scope, self.cleanup_requested = store, scope, cleanup_requested
        self.checks: list[Check] = []
        self.observations: list[str] = []
        self.settings: dict = {}

    def add(self, id: str, title: str, status: str, detail: str = "", *, required: bool = True,
            notes: list[str] | None = None, data: dict | None = None) -> Check:
        assert status in STATUSES, status
        c = Check(id, title, status, detail, required, notes or [], data or {})
        self.checks.append(c)
        return c

    def skip(self, id: str, title: str, reason: str, required: bool = True) -> Check:
        return self.add(id, title, "SKIP", reason, required=required)

    def get(self, id: str) -> Check | None:
        return next((c for c in self.checks if c.id == id), None)

    def passed(self, *ids: str) -> bool:
        return all((c := self.get(i)) is not None and c.status == "PASS" for i in ids)

    def observe(self, text: str) -> None:
        self.observations.append(text)

    def overall(self) -> str:
        if any(c.status == "FAIL" and c.required for c in self.checks):
            return "FAIL"
        if any(c.status == "SKIP" and c.required for c in self.checks):
            return "INCOMPLETE"
        return "PASS"

    def to_dict(self, when: datetime.datetime, environment: dict) -> dict:
        counts = {s.lower(): sum(1 for c in self.checks if c.status == s) for s in STATUSES}
        return {
            "schema_version": SCHEMA_VERSION,
            "kind": "zetaris-object-store-report",
            "generated_at": when.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "store": self.store,
            "scope": self.scope,
            "cleanup_requested": self.cleanup_requested,
            "settings": self.settings,
            "environment": environment,
            "result": self.overall(),
            "summary": counts,
            "checks": [asdict(c) for c in self.checks],
            "observations": self.observations,
        }


def tls_error(e: BaseException) -> bool:
    return isinstance(e, SSLError) or "CERTIFICATE_VERIFY_FAILED" in str(e) or "self-signed certificate" in str(e)


def short(e: BaseException) -> str:
    return s3.short(e)


# --- the object store -------------------------------------------------------

def check_store(rep: RunReport, st: s3.Settings, folder: str, attempts: list) -> object | None:
    """The store checks. Returns a working client, or None if the bucket cannot be reached."""
    good = [a for a in attempts if a.ok]
    https = st.endpoint.lower().startswith("https://")
    if not good:
        errs = [a.error for a in attempts]
        if all(tls_error(e) for e in errs):
            rep.add("store.connect", "Reach the bucket (head_bucket and list)", "FAIL", f"no combination connected: {short(errs[0])}")
            rep.add("store.tls", "TLS certificate trusted", "FAIL", "the endpoint's certificate chain is not trusted by this Python",
                    notes=["Set S3_CA_BUNDLE to a PEM file with the store's CA. Never disable verification."])
        else:
            rep.add("store.connect", "Reach the bucket (head_bucket and list)", "FAIL", f"no combination connected: {short(errs[0])}",
                    data={"errors": sorted({short(e)[:80] for e in errs})})
            rep.add("store.tls", "TLS certificate trusted", "PASS" if any(isinstance(e, ClientError) for e in errs) and https else "SKIP",
                    "the TLS handshake worked and the store answered with an HTTP error" if any(isinstance(e, ClientError) for e in errs) and https
                    else "could not reach the endpoint, so TLS was not tested")
        for id_, title in (("store.addressing", "Addressing style"), ("store.region", "Region name accepted"), ("store.list", "List objects"),
                           ("store.putgetdelete", "Put, get and delete an object"), ("store.batch_delete", "Batch delete"),
                           ("store.retention", "Object lock and versioning")):
            rep.skip(id_, title, "the bucket could not be reached", required=id_ not in ("store.batch_delete", "store.retention"))
        return None

    rep.add("store.connect", "Reach the bucket (head_bucket and list)", "PASS", f"{len(good)} of {len(attempts)} style and region combinations worked")
    rep.add("store.tls", "TLS certificate trusted", "PASS" if https else "INFO",
            "the certificate chain was verified" if https else "the endpoint is http://, so no TLS is used and the keys travel unencrypted")

    worked: dict[str, list[str]] = {}
    for a in good:
        worked.setdefault(a.style, []).append(a.region)
    configured = next((a for a in good if (a.style, a.region) == (st.addressing, st.region)), None)
    if st.addressing in worked:
        rep.add("store.addressing", "Addressing style", "PASS", f"{st.addressing}-style works", data={"configured": st.addressing, "worked": sorted(worked)})
    else:
        rep.add("store.addressing", "Addressing style", "FAIL", f"{st.addressing}-style did not work; {', '.join(sorted(worked))} did",
                notes=[f"Set S3_ADDRESSING={sorted(worked)[0]} in .env.local."], data={"configured": st.addressing, "worked": sorted(worked)})
    if configured:
        rep.add("store.region", "Region name accepted", "PASS", f"{st.region} accepted",
                data={"configured": st.region, "accepted": {k: sorted(v) for k, v in worked.items()}})
    else:
        rep.add("store.region", "Region name accepted", "FAIL", f"{st.region} with {st.addressing}-style did not work",
                notes=["Set S3_REGION and S3_ADDRESSING to a combination that worked."], data={"configured": st.region, "accepted": {k: sorted(v) for k, v in worked.items()}})
    chosen = configured or good[0]
    if not configured:
        rep.observe(f"The configured settings did not work, so the remaining store checks used {chosen.style}-style with region {chosen.region}.")
    elif len({a.region for a in good if a.style == st.addressing}) == len(probe_s3.REGIONS) + (0 if st.region in probe_s3.REGIONS else 1):
        rep.observe("The store accepted every region name tried, so it most likely ignores the region.")
    c, bucket = chosen.client, st.bucket

    try:
        n = len(cleanup_bucket.list_prefix(c, bucket, folder))
        rep.add("store.list", "List objects (ListObjectsV2)", "PASS", f"listed your folder ({n} objects)")
    except (ClientError, BotoCoreError) as e:
        rep.add("store.list", "List objects (ListObjectsV2)", "FAIL", short(e))

    key, body, step = f"{folder}zetaris-report/{uuid.uuid4()}.txt", b"zetaris report", "put"
    try:
        c.put_object(Bucket=bucket, Key=key, Body=body)
        step = "get"
        same = c.get_object(Bucket=bucket, Key=key)["Body"].read() == body
        step = "delete"
        c.delete_object(Bucket=bucket, Key=key)
        rep.add("store.putgetdelete", "Put, get and delete an object", "PASS" if same else "FAIL",
                "an object was written, read back identical and deleted" if same else "the object read back different")
    except (ClientError, BotoCoreError) as e:
        rep.add("store.putgetdelete", "Put, get and delete an object", "FAIL", f"{step} failed: {short(e)}")

    batch_prefix = f"{folder}zetaris-report/batch-{uuid.uuid4()}/"
    keys = [f"{batch_prefix}{i}.txt" for i in range(3)]
    try:
        for k in keys:
            c.put_object(Bucket=bucket, Key=k, Body=b"x")
        try:
            r = c.delete_objects(Bucket=bucket, Delete={"Objects": [{"Key": k} for k in keys], "Quiet": True})
            left = cleanup_bucket.list_prefix(c, bucket, batch_prefix)
            if r.get("Errors") or left:
                raise ClientError({"Error": {"Code": "PartialBatch", "Message": "batch delete left objects"}}, "DeleteObjects")
            rep.add("store.batch_delete", "Batch delete", "PASS", "DeleteObjects removed 3 objects in one call", required=False)
        except (ClientError, BotoCoreError) as e:
            for k in keys:
                c.delete_object(Bucket=bucket, Key=k)
            rep.add("store.batch_delete", "Batch delete", "INFO", f"DeleteObjects is not usable ({short(e)}); single deletes work",
                    required=False, notes=["cleanup_bucket.py falls back to single deletes by itself."])
    except (ClientError, BotoCoreError) as e:
        rep.add("store.batch_delete", "Batch delete", "FAIL", f"could not set up the test: {short(e)}", required=False)

    facts, notes = {}, []
    try:
        lock = c.get_object_lock_configuration(Bucket=bucket).get("ObjectLockConfiguration", {})
        facts["object_lock"] = lock.get("ObjectLockEnabled", "unknown")
        if facts["object_lock"] == "Enabled":
            notes.append("Object lock is enabled: deletes under retention are refused, and no script works around that.")
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        facts["object_lock"] = "not configured" if "ObjectLockConfigurationNotFound" in code else f"not reported ({code or 'error'})"
    except BotoCoreError as e:
        facts["object_lock"] = f"not reported ({type(e).__name__})"
    try:
        v = c.get_bucket_versioning(Bucket=bucket).get("Status")
        facts["versioning"] = v or "never enabled"
        if v == "Enabled":
            notes.append("Versioning is enabled: after a cleanup, old versions and delete markers may remain.")
    except (ClientError, BotoCoreError) as e:
        facts["versioning"] = f"not reported ({short(e)[:40]})"
    rep.add("store.retention", "Object lock and versioning", "INFO", f"object lock: {facts['object_lock']}; versioning: {facts['versioning']}",
            required=False, notes=notes, data=facts)
    return c


# --- Zetaris and the data ---------------------------------------------------

SKIPPED_ZETARIS = (
    ("zetaris.connect", "Connect to Zetaris and run SELECT 1"), ("zetaris.usl", "The sic_edgar_usl USL is present"),
    ("zetaris.setting", "Create a storage setting"), ("materialize.sic_code", "MATERIALIZE USL TABLE sic_code"),
    ("materialize.company", "MATERIALIZE USL TABLE company"), ("parquet.sic_code", "Parquet files for sic_code are readable"),
    ("parquet.company", "Parquet files for company are readable"), ("chain.sic_code", "sic_code: row counts equal, API to Parquet"),
    ("chain.company", "company: row counts equal, API to Parquet"),
)


def skip_zetaris(rep: RunReport, reason: str, required: bool) -> None:
    for id_, title in SKIPPED_ZETARIS:
        if rep.get(id_) is None:
            rep.skip(id_, title, reason, required=required)


def stages(report: vc.Report) -> list[dict]:
    return [{"stage": n.strip(), "rows": c.strip(), "result": r.strip()} for n, c, r in report.rows]


def check_zetaris(rep: RunReport, st: s3.Settings, c, folder: str, usl: str, channel_factory, api_call) -> None:
    """Zetaris checks, the materialization and the chain. `c` is the working S3 client."""
    try:
        with quiet_stderr():
            ch = channel_factory()
        ch.run("SELECT 1", limit=1)
        rep.add("zetaris.connect", "Connect to Zetaris and run SELECT 1", "PASS", f"connected over {ch.name.upper()}")
    except Exception as e:  # noqa: BLE001
        rep.add("zetaris.connect", "Connect to Zetaris and run SELECT 1", "FAIL", f"{type(e).__name__}: {str(e)[:160]}")
        skip_zetaris(rep, "no connection to Zetaris", True)
        return
    try:
        counts = {t: int(ch.run(f"SELECT COUNT(*) FROM {usl}.{t}", limit=1).rows[0][0]) for t in TABLES}
        if all(n > 0 for n in counts.values()):
            rep.add("zetaris.usl", "The sic_edgar_usl USL is present", "PASS", ", ".join(f"{t}: {n:,} rows" for t, n in counts.items()), data=counts)
        else:
            raise ValueError(f"empty tables: {counts}")
    except Exception as e:  # noqa: BLE001
        rep.add("zetaris.usl", "The sic_edgar_usl USL is present", "FAIL", f"{type(e).__name__}: {str(e)[:160]}",
                notes=["Build the USL first (HOWTO step 5)."])
        skip_zetaris(rep, "the USL is not present", True)
        ch.close()
        return

    setting_id = None
    try:
        status, body = api_call("POST", "/storage-setting", storage_setting.create_body(st, name=f"s3-compat-report-{uuid.uuid4().hex[:8]}"))
        setting_id = body.get("id") if isinstance(body, dict) else None
        if status == 200 and setting_id:
            rep.add("zetaris.setting", "Create a storage setting", "PASS", "HTTP 200")
        else:
            raise RuntimeError(f"HTTP {status} {str(body)[:120]}")
    except Exception as e:  # noqa: BLE001
        rep.add("zetaris.setting", "Create a storage setting", "FAIL", f"{type(e).__name__}: {str(e)[:160]}",
                notes=["The storage setting is not needed to materialize, so the test continued without it."])

    try:
        s3.ensure_folder(c, st.bucket, folder)
    except (ClientError, BotoCoreError):
        pass  # the write creates the folder
    ns = usl.split(".")
    for t in TABLES:
        fqn, path = f"{usl}.{t}", f"s3a://{st.bucket}/{folder}{ns[-2]}/{ns[-1]}/{t}"
        try:
            row = ch.run(mat.build(st, fqn, path, "options-json", setting_id, "parquet", "all"), limit=5).rows
            result = [str(x) for x in (row[0] if row else [])]
            if len(result) > 1 and result[1] == "SUCCESS":
                rep.add(f"materialize.{t}", f"MATERIALIZE USL TABLE {t}", "PASS", "the statement returned SUCCESS")
            else:
                msg = mat.mask(" | ".join(result))[:300] if result else "no result row"
                rep.add(f"materialize.{t}", f"MATERIALIZE USL TABLE {t}", "FAIL", msg,
                        notes=["See issues/ISSUE-01 if the message mentions No AWS Credentials provided."])
        except Exception as e:  # noqa: BLE001
            rep.add(f"materialize.{t}", f"MATERIALIZE USL TABLE {t}", "FAIL", mat.mask(f"{type(e).__name__}: {e}")[:300])

    try:
        objs = cleanup_bucket.list_prefix(c, st.bucket, folder)
    except (ClientError, BotoCoreError) as e:
        for t in TABLES:
            rep.add(f"parquet.{t}", f"Parquet files for {t} are readable", "FAIL", f"could not list the folder: {short(e)}")
            rep.skip(f"chain.{t}", f"{t}: row counts equal, API to Parquet", "could not list the folder")
        _finish_zetaris(rep, ch, api_call, setting_id)
        return
    for t in TABLES:
        try:
            found = vc.parquet_rows(c, st.bucket, objs, t)
            files = sum(1 for o in objs if o["Key"].endswith(".parquet") and t in o["Key"].lower().split("/"))
            if found:
                rows = sum(len(r) for _, r in found.values())
                cols = next(iter(found.values()))[0]
                rep.add(f"parquet.{t}", f"Parquet files for {t} are readable", "PASS", f"{files} file(s), {rows:,} rows, {len(cols)} columns",
                        data={"files": files, "rows": rows, "columns": cols})
                if files > 1:
                    rep.observe(f"{t} was written as {files} Parquet files (one per source query); that is expected for a UNION ALL.")
            else:
                rep.add(f"parquet.{t}", f"Parquet files for {t} are readable", "FAIL", "no Parquet file found under the table's folder")
        except Exception as e:  # noqa: BLE001
            rep.add(f"parquet.{t}", f"Parquet files for {t} are readable", "FAIL", f"{type(e).__name__}: {str(e)[:160]}")

    codes: set = set()
    try:
        sic_report, codes = vc.chain_sic_code(ch, c, st.bucket, objs, usl)
        rep.add("chain.sic_code", "sic_code: row counts equal, API to Parquet", "PASS" if sic_report.ok else "FAIL",
                "every stage matched" if sic_report.ok else "a stage differs; see the stages", data={"stages": stages(sic_report)})
    except Exception as e:  # noqa: BLE001
        rep.add("chain.sic_code", "sic_code: row counts equal, API to Parquet", "FAIL", f"{type(e).__name__}: {str(e)[:160]}")
    if rep.get("chain.sic_code").status == "FAIL" and not codes:
        rep.skip("chain.company", "company: row counts equal, API to Parquet", "needs the SIC codes from the sic_code chain")
    else:
        try:
            company_report = vc.chain_company(ch, c, st.bucket, objs, usl, codes)
            rep.add("chain.company", "company: row counts equal, API to Parquet", "PASS" if company_report.ok else "FAIL",
                    "every stage matched" if company_report.ok else "a stage differs; see the stages", data={"stages": stages(company_report)})
        except Exception as e:  # noqa: BLE001
            rep.add("chain.company", "company: row counts equal, API to Parquet", "FAIL", f"{type(e).__name__}: {str(e)[:160]}")
    _finish_zetaris(rep, ch, api_call, setting_id)


def _finish_zetaris(rep: RunReport, ch, api_call, setting_id) -> None:
    try:
        ch.close()
    except Exception:  # noqa: BLE001
        pass
    if setting_id:
        try:
            status, _ = api_call("DELETE", f"/storage-setting/{setting_id}")
            rep.add("zetaris.setting_removed", "Remove the storage setting this run created", "PASS" if status == 200 else "FAIL",
                    f"HTTP {status}", required=False)
        except Exception as e:  # noqa: BLE001
            rep.add("zetaris.setting_removed", "Remove the storage setting this run created", "FAIL", f"{type(e).__name__}: {str(e)[:120]}", required=False)


# --- cleanup ----------------------------------------------------------------

def check_cleanup(rep: RunReport, st: s3.Settings, c, folder: str, do_cleanup: bool) -> None:
    title = "Clear your folder in the bucket"
    if c is None:
        rep.skip("cleanup", title, "the bucket could not be reached", required=do_cleanup)
        return
    try:
        objs = cleanup_bucket.list_prefix(c, st.bucket, folder)
    except (ClientError, BotoCoreError) as e:
        rep.add("cleanup", title, "FAIL" if do_cleanup else "SKIP", f"could not list the folder: {short(e)}", required=do_cleanup)
        return
    size = sum(o["Size"] for o in objs)
    if not do_cleanup:
        rep.skip("cleanup", title, f"not requested: {len(objs)} object(s), {size:,} bytes would be deleted. Run with --cleanup.", required=False)
        return
    failed = cleanup_bucket.delete_keys(c, st.bucket, [o["Key"] for o in objs])
    try:
        left = len(cleanup_bucket.list_prefix(c, st.bucket, folder))
    except (ClientError, BotoCoreError):
        left = -1
    if left == 0 and not failed:
        rep.add("cleanup", title, "PASS", f"{len(objs)} object(s), {size:,} bytes deleted; the folder is empty", data={"deleted": len(objs), "bytes": size})
    else:
        rep.add("cleanup", title, "FAIL", f"{max(left, 0)} object(s) remain ({len(failed)} could not be deleted)",
                notes=["On a versioned or locked bucket, old versions or retention can keep objects. Check the store's console."])


# --- orchestration ----------------------------------------------------------

def build_report(st: s3.Settings, *, names: dict, folder: str, usl: str, verify, do_cleanup: bool, store_only: bool,
                 attempts_fn=probe_s3.probe_attempts, channel_factory=None, api_call=storage_setting.call) -> RunReport:
    values = renderer.store_values(names.get("S3_STORE_VENDOR", ""), names.get("S3_STORE_PRODUCT", ""))
    store = {"name": values["STORE_NAME"], "vendor": values["STORE_VENDOR"], "product": values["STORE_PRODUCT"]}
    rep = RunReport(store, "store-only" if store_only else "full", do_cleanup)
    rep.settings = {"addressing": st.addressing, "region": st.region, "ca_bundle": "custom" if st.ca_bundle else "default",
                    "endpoint_scheme": st.endpoint.split("://")[0].lower() if "://" in st.endpoint else "unknown"}
    c = check_store(rep, st, folder, attempts_fn(st, verify))
    if store_only:
        skip_zetaris(rep, "not run: store-only report", False)
    elif c is None:
        skip_zetaris(rep, "the bucket could not be reached", True)
    else:
        check_zetaris(rep, st, c, folder, usl, channel_factory, api_call)
    check_cleanup(rep, st, c, folder, do_cleanup)
    return rep


# --- output -----------------------------------------------------------------

def environment() -> dict:
    env = {"python": platform.python_version(), "platform": f"{platform.system()} {platform.machine()}"}
    for mod in ("boto3", "botocore", "pyarrow"):
        try:
            env[mod] = __import__(mod).__version__
        except Exception:  # noqa: BLE001
            env[mod] = "not installed"
    return env


def render_markdown(doc: dict) -> str:
    """The readable report, rendered only from the JSON document."""
    s, cfg = doc["summary"], doc.get("settings", {})
    lines = [f"# Object store conformance report: {doc['store']['name']}", "",
             f"- **Result:** {doc['result']}",
             f"- **Generated:** {doc['generated_at']}",
             f"- **Scope:** {doc['scope']}" + ("; cleanup requested" if doc["cleanup_requested"] else "; cleanup not requested"),
             f"- **Settings:** {cfg.get('addressing', 'unknown')}-style addressing, region {cfg.get('region', 'unknown')}, "
             f"{cfg.get('endpoint_scheme', 'unknown')} endpoint, CA {cfg.get('ca_bundle', 'unknown')}",
             f"- **Counts:** {s['pass']} PASS, {s['fail']} FAIL, {s['skip']} SKIP, {s['info']} INFO", "",
             "| Status | Check | Detail |", "|---|---|---|"]
    for c in doc["checks"]:
        req = "" if c["required"] else " (optional)"
        lines.append(f"| {c['status']} | {c['title']}{req} | {c['detail'].replace('|', '/').replace(chr(10), ' ')} |")
    for c in doc["checks"]:
        stg = c["data"].get("stages")
        if stg:
            lines += ["", f"### {c['title']}", "", "| Stage | Rows | Result |", "|---|---|---|"]
            lines += [f"| {x['stage']} | {x['rows']} | {x['result']} |" for x in stg]
    notes = [(c["title"], n) for c in doc["checks"] for n in c["notes"]]
    if notes or doc["observations"]:
        lines += ["", "## Observations", ""]
        lines += [f"- {t}: {n}" for t, n in notes] + [f"- {o}" for o in doc["observations"]]
    e = doc["environment"]
    lines += ["", "## Environment", "", f"Python {e['python']} on {e['platform']}; boto3 {e['boto3']}, pyarrow {e['pyarrow']}.", "",
              "This report holds no keys, passwords, bucket name, endpoint, folder name, user agent or login name.", ""]
    return "\n".join(lines)


def redact_doc(node, values):
    if isinstance(node, str):
        return leaks.redact(node, values)
    if isinstance(node, list):
        return [redact_doc(x, values) for x in node]
    if isinstance(node, dict):
        return {k: redact_doc(v, values) for k, v in node.items()}
    return node


def safe_outputs(doc: dict, values: list[tuple[str, str]]) -> tuple[str, str, list[str]]:
    """(json text, markdown text, problems). Values are redacted first; anything
    still found afterwards is a problem and the files must not be written."""
    clean = redact_doc(doc, values)
    js, md = json.dumps(clean, indent=2, ensure_ascii=False) + "\n", render_markdown(clean)
    return js, md, sorted(set(leaks.found_in(js, values) + leaks.found_in(md, values)))


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:40] or "object-store"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0], formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cleanup", action="store_true", help="also clear your own folder in the bucket at the end")
    ap.add_argument("--store-only", action="store_true", help="test only the object store; skip Zetaris and the data")
    ap.add_argument("--usl", default=DEFAULT_USL, help=f"the USL to materialize (default {DEFAULT_USL})")
    ap.add_argument("--channel", default="jdbc", choices=["jdbc", "rest"])
    ap.add_argument("--jar", help="driver JAR for JDBC (default: ZETARIS_JDBC_JAR)")
    ap.add_argument("--ca-bundle", help="PEM file of trusted CAs (default: S3_CA_BUNDLE, then the CA file Python trusts)")
    ap.add_argument("--env-file", help="settings file (default: .env.local)")
    ap.add_argument("--out", default=str(s3.ROOT / "reports"), help="folder for the report (default: reports/)")
    a = ap.parse_args()

    env_file = z.load_env(a.env_file)
    if not a.store_only:
        z.reexec_in_venv_if_needed(a.channel)
    st = s3.load()
    schema = json.loads(SCHEMA_FILE.read_text(encoding="utf-8"))
    env = leaks.read_env(env_file) if env_file else {}
    env.update({s_["name"]: os.environ[s_["name"]] for s_ in schema["settings"] if os.environ.get(s_["name"])})
    values, short_names = leaks.forbidden_values(env, schema)
    names = {k: env.get(k, "") for k in ("S3_STORE_VENDOR", "S3_STORE_PRODUCT")}
    folder = s3.base_prefix()

    print(f"Running the object store test ({'store only' if a.store_only else 'full'}; cleanup {'on' if a.cleanup else 'is a dry run'}). This takes about a minute.", flush=True)
    rep = build_report(st, names=names, folder=folder, usl=a.usl, verify=s3.tls_verify(st, a.ca_bundle), do_cleanup=a.cleanup,
                       store_only=a.store_only, channel_factory=lambda: z.open_channel(a.channel, a.jar or os.environ.get("ZETARIS_JDBC_JAR")))
    when = datetime.datetime.now(datetime.timezone.utc)
    doc = rep.to_dict(when, environment())
    js, md, problems = safe_outputs(doc, values)
    if problems:
        print("\nNOT WRITTEN: the report still contains values from .env.local after redaction: " + ", ".join(problems), file=sys.stderr)
        return 2
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    stem = f"{slug(doc['store']['name'] if doc['store']['vendor'] or doc['store']['product'] else '')}-{when:%Y%m%d-%H%M%S}"
    (out / f"{stem}.json").write_text(js, encoding="utf-8")
    (out / f"{stem}.md").write_text(md, encoding="utf-8")
    print("\n" + md)
    if short_names:
        print(f"(Too short to check for leaks: {', '.join(short_names)})")
    print(f"Wrote {out / (stem + '.json')}\nWrote {out / (stem + '.md')}\nResult: {doc['result']}")
    print("To see it formatted, start the viewer (serve_viewer.py) and open the Proof and recipe tab: it shows the newest report in reports/ by itself.")
    return {"PASS": 0, "FAIL": 1, "INCOMPLETE": 3}[doc["result"]]


if __name__ == "__main__":
    raise SystemExit(main())
