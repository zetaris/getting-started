# S3-compatible object stores: probe, storage setting, materialize, verify

Scripts for using any S3-compatible object store as a Zetaris materialization
target, and for proving the result. Verified against Zetaris 2.4.3.1. Run them
from the repository root.

## Settings

Set these in `.env.local` (gitignored). The scripts never print the keys.

| Name | Meaning |
|---|---|
| `S3_ENDPOINT_URL` | Endpoint, for example `https://s3.example.com` |
| `S3_ACCESS_KEY` | Access key ID |
| `S3_SECRET_KEY` | Secret key |
| `S3_BUCKET` | Bucket name |
| `S3_PREFIX` | Optional. Your own folder in the bucket, for example `jane-usl-test`. Blank means `usl-test-` plus your login name |
| `S3_REGION` | Optional. Region name sent to the store. Default `us-east-1`; most non-AWS stores ignore it |
| `S3_ADDRESSING` | Optional. `path` (default) or `virtual`. Also sets `useS3PathStyleAccess` for Zetaris. The probe shows which one your store accepts |
| `S3_CA_BUNDLE` | Optional. PEM file of trusted CAs, for a store with a private certificate authority. Default is the CA file Python trusts |
| `S3_STORAGE_SETTING_ID` | Optional. The id printed by `storage_setting.py create`, so you can omit `--setting-id` |

Install the helpers in the venv:
`.venv/bin/pip install -r systems/object_stores/requirements.txt`.

## The scripts

| Script | What it does | Writes? |
|---|---|---|
| `probe_s3.py` | Tests TLS, the keys and the bucket, with path-style and virtual-host addressing and three region names. Then does one put, get and delete of a tiny test object, and creates your folder. | Test object (deleted again) and your folder marker; `--no-write` skips both |
| `storage_setting.py` | Lists, shows, creates or deletes a Zetaris storage setting through the REST API. | Zetaris setting |
| `materialize_usl_table.py` | Builds and runs `MATERIALIZE USL TABLE ... TO STORAGE (...)` from your settings. `--dry-run` prints it with the credentials masked. | Parquet files in your folder |
| `verify_bucket.py` | Lists your folder (or a prefix you name) and reads Parquet row counts and schemas. | No |
| `verify_chain.py` | Checks the SIC and EDGAR data end to end: live source API, Lightning view, USL table and Parquet files. | No |
| `cleanup_bucket.py` | Deletes the objects the test wrote. Dry run by default; `--yes` deletes. Only touches the folders you name (default: your own folder) and refuses an empty prefix. | Deletes, with `--yes` |

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
python3 systems/object_stores/scripts/storage_setting.py create                  # once; prints the id
python3 systems/object_stores/scripts/materialize_usl_table.py \
    lightning.metastore.usl_demo.sic_edgar_usl.sic_code --variant options-json --dry-run
python3 systems/object_stores/scripts/materialize_usl_table.py \
    lightning.metastore.usl_demo.sic_edgar_usl.sic_code --variant options-json
.venv/bin/python systems/object_stores/scripts/verify_chain.py                   # whole chain, API to Parquet
```

`verify_chain.py` prints the bucket listing, then verifies each materialized
table end to end and exits non-zero if any stage differs. `--table` picks
`sic_code`, `company` or `all` (the default). It needs the SIC and EDGAR sources
and the `sic_edgar_usl` USL from `open_data/` to exist first.

## Clearing the bucket

Clear your folder before a re-run, so old and new files cannot sit side by side
and `verify_chain.py` proves the new run, not the old one.

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
