# S3-compatible object stores: probe, storage setting, materialize, verify

Scripts for using any S3-compatible object store as a Zetaris materialization
target, and for proving the result. Verified against Zetaris 2.4.3.1. Run them
from the repository root.

## Settings

Set these in `.env.local` (gitignored). The scripts never print the keys. The table below is generated from [`settings.json`](settings.json), and [`.env.example`](.env.example) is generated from the same file, so copy that to start.

<!-- settings-table:start -->
| Setting | Required | Secret | Default | Meaning |
|---|---|---|---|---|
| `ZETARIS_USERNAME` | yes | no |  | Your Zetaris user id, normally an email address. Used for JDBC and to fetch the OpenAPI spec. |
| `ZETARIS_PASSWORD` | yes | yes |  | Your Zetaris password. |
| `ZETARIS_API_KEY` | yes | yes |  | An API key you create yourself in the Zetaris GUI. Used by storage_setting.py and by the viewer server over REST. The scripts never create one. |
| `ZETARIS_USER_AGENT` | yes | no |  | Sent to the public SEC EDGAR and company-dns APIs, which ask callers to identify themselves. Use an app name and a real contact email. The scripts refuse the placeholder. |
| `ZETARIS_JDBC_JAR` | yes | no |  | Full path to the Zetaris JDBC driver JAR. Needed for JDBC, which is the default channel. |
| `ZETARIS_JDBC_URL` | no | no | `jdbc:zetaris:lightning@localhost:10000` | JDBC URL of the instance. |
| `ZETARIS_REST_URL` | no | no | `http://localhost:8888/api/v1.0` | REST API base URL of the instance. |
| `ZETARIS_ORG_ID` | no | no | `1` | Organization id sent with REST calls. |
| `S3_ENDPOINT_URL` | yes | no |  | The S3 endpoint URL, with https:// and no bucket or path. |
| `S3_BUCKET` | yes | no |  | An existing bucket. |
| `S3_ACCESS_KEY` | yes | yes |  | Access key id. |
| `S3_SECRET_KEY` | yes | yes |  | The access key's secret. The MATERIALIZE statement carries it, and the instance may keep that statement in query history, so use a key you can rotate. |
| `S3_PREFIX` | no | no |  | Your own folder in the bucket. Everything the test writes goes under it, so people who share a bucket do not collide. Blank means usl-test- plus your login name. Letters, digits, - _ . and / only; it is lower-cased. |
| `S3_REGION` | no | no | `us-east-1` | Region name sent to the store. Most non-AWS stores ignore it, but some check it. |
| `S3_ADDRESSING` | no | no | `path` | path or virtual. Also sets useS3PathStyleAccess for Zetaris. probe_s3.py shows which one your store accepts. |
| `S3_CA_BUNDLE` | no | no |  | PEM file of trusted CAs, for a store with a private certificate authority. Default is the CA file Python trusts. TLS verification is never turned off. |
| `S3_STORAGE_SETTING_ID` | no | no |  | The Zetaris storage setting id, so materialize_usl_table.py does not need --setting-id. |
| `S3_STORE_VENDOR` | no | no |  | Vendor of the object store, shown in the viewer and the documents. Blank leaves it out. |
| `S3_STORE_PRODUCT` | no | no |  | Product name of the object store, shown in the viewer and the documents. Blank shows a generic name. |
<!-- settings-table:end -->

Install the helpers in the venv:
`.venv/bin/pip install -r systems/object_stores/requirements.txt`.

After editing `settings.json`, run `python3 systems/object_stores/scripts/settings_docs.py --write`. `--check` fails if the example env file, this table, the setting names used in the scripts, or the templates have drifted. <!--repo-only-->

## The scripts

| Script | What it does | Writes? |
|---|---|---|
| `probe_s3.py` | Tests TLS, the keys and the bucket, with path-style and virtual-host addressing and three region names. Then does one put, get and delete of a tiny test object, and creates your folder. | Test object (deleted again) and your folder marker; `--no-write` skips both |
| `storage_setting.py` | Lists, shows, creates or deletes a Zetaris storage setting through the REST API. | Zetaris setting |
| `materialize_usl_table.py` | Builds and runs `MATERIALIZE USL TABLE ... TO STORAGE (...)` from your settings. `--dry-run` prints it with the credentials masked. | Parquet files in your folder |
| `verify_bucket.py` | Lists your folder (or a prefix you name) and reads Parquet row counts and schemas. | No |
| `verify_chain.py` | Checks the SIC and EDGAR data end to end: live source API, Lightning view, USL table and Parquet files. | No |
| `cleanup_bucket.py` | Deletes the objects the test wrote. Dry run by default; `--yes` deletes. Only touches the folders you name (default: your own folder) and refuses an empty prefix. | Deletes, with `--yes` |

### Helpers

| File | What it is |
|---|---|
| `report.py` | Runs the probe, storage setting, materialization, chain check and cleanup in order and writes a PASS/FAIL report (JSON and Markdown) you can send back. See "The conformance report" below. |
| `leaks.py` | Finds values from `.env.local` that must never appear in something you hand to someone else. Used by `report.py`. |
| `s3_settings.py` | Reads the settings above and builds the S3 client, so every script uses the same addressing style, region and CA trust. |
| `settings_docs.py` | Repository only. Generates `.env.example` and the settings table from `settings.json`, and checks for drift. | <!--repo-only-->
| `render.py` | Fills `{{STORE_NAME}}`-style tokens in templates such as `HOWTO.md.tmpl`. |
| `serve_viewer.py` | Serves the viewer and runs read-only SQL against your instance for its Live SQL tab. Renders the page with `S3_STORE_VENDOR` and `S3_STORE_PRODUCT` from `.env.local` on every request. |
| `check_viewer.py` | Repository only. Static checks of the viewer template: it renders, a hostile name is escaped, ids and references resolve, nothing loads from another site, and the text colors keep WCAG AA contrast. | <!--repo-only-->

For a walk-through from a clean instance to a verified Parquet file, see the HOWTO: `HOWTO.md.tmpl` in this folder in the repository (a template; `render.py` renders it by hand), or `HOWTO.md` at the root of a built package.

## The conformance report

`report.py` runs steps 8 to 11 of the HOWTO and the bucket part of step 15 (step 14 is the report) in order and records what happened, so a partner can send back one file instead of a transcript.

```bash
.venv/bin/python systems/object_stores/scripts/report.py              # everything; the cleanup is a dry run
.venv/bin/python systems/object_stores/scripts/report.py --cleanup    # also clear your own folder at the end
.venv/bin/python systems/object_stores/scripts/report.py --store-only # only the object store, before Zetaris is involved
```

It needs the USL from HOWTO step 5 (except with `--store-only`) and takes about a minute. Each check is **PASS**, **FAIL**, **SKIP** (not run, with the reason) or **INFO** (a fact, not a verdict):

| Group | Checks |
|---|---|
| Object store | bucket reachable; TLS trusted; addressing style; region name; list; put, get and delete; batch delete (INFO if only single deletes work); object lock and versioning (INFO) |
| Zetaris | connection; the `sic_edgar_usl` USL present; a storage setting created (and removed again afterwards) |
| The data | `MATERIALIZE USL TABLE` for `sic_code` and `company`; the Parquet files read back; the row counts equal at every stage from the source API to the Parquet file |
| Cleanup | your own folder cleared, only with `--cleanup` |

A failure that makes later steps meaningless (no connection to the bucket, no Zetaris, no USL) stops them, and they are recorded as SKIP. Anything unexpected goes under "observations". The result is **PASS**, **FAIL** (a required check failed) or **INCOMPLETE** (a required check was skipped); the exit code is 0, 1 or 3. It touches only your own folder, and only the objects it wrote or, with `--cleanup`, everything in that folder.

It writes `reports/<store>-<date>-<time>.json`, the contract (a `schema_version`, the checks, the stages), and a `.md` rendered from it. `reports/` is gitignored. Load the JSON in the viewer's Proof tab to see it formatted; the file is read in your browser and goes nowhere.

**The report is safe to send.** Keys, passwords, bucket, endpoint, folder, user agent, login name and home folder from `.env.local` are replaced by placeholders such as `<bucket>`, and the report is not written at all (exit code 2) if one is still found afterwards. The store is named only by `S3_STORE_VENDOR` and `S3_STORE_PRODUCT`.

<!--repo-only-start-->
## Building a package for a partner

`scripts/package.py` builds a test package of this kit for one partner, as a folder and a ZIP under `dist/` (gitignored). It reads `.env.local`; add these lines to it:

```
PACKAGE_PARTNER=acme              # required: letters, digits, hyphens; part of the ZIP name
S3_STORE_VENDOR=Acme              # optional: names shown in the documents and the viewer
S3_STORE_PRODUCT=StoreX
S3_ADDRESSING=path                # optional: baked into the example env file as the default
S3_REGION=us-east-1
PACKAGE_LOGO=/path/to/logo.svg    # optional: a logo file supplied for this package
PACKAGE_DENY_WORDS=Other,Names    # optional: words that must not appear anywhere
```

```bash
python3 systems/object_stores/scripts/package.py --dry-run   # build and check in memory; write nothing
python3 systems/object_stores/scripts/package.py             # write dist/zetaris-<partner>-object-store-test/ and the ZIP
```

The package keeps this repository's paths, so every command in its documents runs the same there. It holds the kit, the helper scripts it uses, the SQL for the `sic_edgar_usl` USL and its sources (resolved from `open_data/manifest.json`), the Zetaris font and logo, and a `MANIFEST.txt` and `SHA256SUMS`. The same inputs and `--date` give the same ZIP.

Only the settings above shape the package. Every other value in `.env.local` (keys, passwords, bucket, endpoint, folder, your login name, home folder) is never copied, and **the build fails and writes nothing if any of them appears in any file**, in memory or in the ZIP read back from disk. It also fails on a file that must never be packaged (`.env.local`, `.venv`, `__pycache__` and the like), on an unresolved template token, and on a denied word. Values shorter than five characters are too likely to match ordinary words, so they are reported as skipped.

Tests (no instance and no `.env.local`). The report tests use a fake S3 client and a fake Zetaris channel, and need `boto3`, so run them with the venv; without it they are skipped:

```bash
.venv/bin/python -m unittest discover systems/object_stores/tests
```

<!--repo-only-end-->

## The viewer

`viewer/index.html.tmpl` is a four-tab page about the `sic_edgar_usl` USL: analysis of its tables, topology and entity relationship diagram, the proof and recipe for this test, and a live SQL tab. It uses the Zetaris light theme and a self-hosted Plus Jakarta Sans font and Zetaris logo.

```bash
.venv/bin/python systems/object_stores/scripts/serve_viewer.py      # then open http://127.0.0.1:8765
```

The page names your object store from `S3_STORE_VENDOR` and `S3_STORE_PRODUCT` in `.env.local` (both optional; blank shows "S3 object store"). Edit them and reload the page; no restart is needed. The Proof tab shows `viewer/fixtures/verify_chain_example.txt`, an example run with placeholder names, clearly labeled as an example.

<!--repo-only-start-->
Two checks keep the page honest:

- `scripts/check_viewer.py` runs without a browser. Repository only.
- `viewer/check_fit.js` runs in a browser. Repository only. Open the page, paste the file into the console and run `await checkViewerFit()`. It must say `ok: true` at desktop and phone width and with a long store name. It checks that every diagram label stays inside its box, that no connector crosses a label, that no two labels overlap, and that the page does not scroll sideways.
<!--repo-only-end-->

## Your own folder in the bucket

Everything the test writes goes under **your own folder**, so several people can
use one bucket without colliding. The folder name is `S3_PREFIX` when you set it,
otherwise `usl-test-` plus your login name (for example `usl-test-jane/`). It is
lower-cased and limited to letters, digits, `.`, `_`, `-` and `/`.

```
s3://<bucket>/<your folder>/zetaris-probe/        probe test object (deleted again)
s3://<bucket>/<your folder>/usl_demo/<usl>/<table>/   materialized Parquet
```

- `probe_s3.py` creates the folder for you, and `materialize_usl_table.py` makes
  sure it exists before it writes. S3 has no real directories: a folder is a key
  prefix, and the scripts create the empty marker object that consoles show as a
  folder. Once data is written under it the folder is visible through its objects,
  and the storage engine normally removes the empty marker. That is expected.
- `storage_setting.py create` sets the setting's path to your folder, so even the
  REST export (which chooses its own sub-path) stays inside it.
- `verify_bucket.py`, `verify_chain.py` and `cleanup_bucket.py` default to your
  folder only. Output left elsewhere in the bucket, by older runs or by other
  people, is neither checked nor deleted.

## What was found

- **TLS.** botocore ships its own CA list, which can lag behind a newer public
  root and fail with "self-signed certificate in certificate chain". The probe
  uses the CA file your Python trusts, which keeps verification on. For a private
  CA, pass `--ca-bundle`. Do not turn verification off. The Zetaris engine host
  must also trust the endpoint's certificate chain.
- **Addressing.** Use path-style (`useS3PathStyleAccess "true"`) unless the store
  needs virtual-host style. The probe tells you which work. Region names are
  usually ignored by non-AWS stores.
- **No SQL creates a storage setting.** Use `POST /storage-setting` (see
  `storage_setting.py`). Creating one does not test connectivity.
- **`MATERIALIZE USL TABLE` ignores the saved setting's credentials.** With only
  `storageSettingId` it fails with `NoAuthWithAWSException: No AWS Credentials
  provided`. Extra top-level keys (`awsAccessKeyId` and so on) and `fs.s3a.*`
  names are ignored too. The S3 credentials, endpoint and path-style flag must be
  inside the `optionsBase64` JSON (`--variant options-json`).
- The REST export `POST /usl/{uslId}/tables/{table}/export` does use the saved
  setting. It chooses its own sub-path (`materialized/usl/<id>/<TABLE>/`) below the
  setting's path, which is your folder.

## Run order

```bash
.venv/bin/python systems/object_stores/scripts/probe_s3.py                       # TLS, keys, addressing; creates your folder
.venv/bin/python systems/object_stores/scripts/storage_setting.py create                  # once; prints the id
.venv/bin/python systems/object_stores/scripts/materialize_usl_table.py \
    lightning.metastore.usl_demo.sic_edgar_usl.sic_code --variant options-json --dry-run
.venv/bin/python systems/object_stores/scripts/materialize_usl_table.py \
    lightning.metastore.usl_demo.sic_edgar_usl.sic_code --variant options-json
.venv/bin/python systems/object_stores/scripts/verify_chain.py                   # whole chain, API to Parquet
```

`verify_chain.py` prints the bucket listing, then verifies each materialized
table end to end and exits non-zero if any stage differs. `--table` picks
`sic_code`, `company` or `all` (the default). It needs the SIC and EDGAR sources
and the `sic_edgar_usl` USL from `open_data/` to exist first.

## Clearing the bucket

A second `MATERIALIZE` replaces a table's output; it does not append (tested on Zetaris 2.4.3.1 with both tables), so a re-run needs no clearing first. Clear your folder to remove files from earlier runs that the new run does not write, such as a table you no longer materialize, so that `verify_chain.py` proves this run and nothing else.

```bash
.venv/bin/python systems/object_stores/scripts/cleanup_bucket.py          # dry run: lists what would go
.venv/bin/python systems/object_stores/scripts/cleanup_bucket.py --yes    # delete your folder's contents
.venv/bin/python systems/object_stores/scripts/cleanup_bucket.py --prefix usl_demo/ --yes   # output from an older run, written without a folder
```

It prints the target bucket first, treats every prefix as a folder (so `usl_demo`
cannot match `usl_demo_backup/`), refuses an empty prefix so the whole bucket can
never be emptied, and lists the prefixes again afterwards. It ends with `CLEAN`
when they are empty and exits non-zero if anything remains. On a versioned bucket,
old versions and delete markers may stay; check your store's console.

The materialize statement puts credentials in SQL, which the instance may keep
in query history. Use a key that can be rotated.
