# Object store cookbook

Test whether an S3-compatible object store works as the storage for a Zetaris Unified Semantic Layer (USL). You build a small USL, write its tables to a bucket as Parquet with `MATERIALIZE USL TABLE`, and check the result from the source API to the Parquet file. A conformance report records what happened and is safe to send to someone else.

Verified on Zetaris 2.4.3.1 against one S3-compatible store. Check it on your instance and your store too.

## What it proves

- Zetaris can reach your store: endpoint, TLS trust, addressing style, keys and bucket.
- `MATERIALIZE USL TABLE` writes Parquet files to your own folder in the bucket.
- The row counts match at every stage: the live API, the Lightning view, the USL table and the Parquet files read back.
- Cleanup touches only your own folder in the bucket.

The data is public and small: `sic_code` (1,005 rows) and `company` (7 rows) from the SIC and SEC EDGAR sources in the [USL cookbook](../../open_data/usl/HOWTO.md).

## What you need

- A Zetaris instance (2.4.3.1 or later) with JDBC on port 10000 and the REST API on port 8888, and a user who can create USLs and storage settings. See [install choices](../install/choose-install.md).
- The Zetaris JDBC driver JAR, JDK 11 or later and Python 3.10 or later.
- A Zetaris API key that you create in the Zetaris GUI.
- Your store's S3 endpoint, an access key, a secret key and an existing bucket. Use a key you can rotate.

## Run it

Follow the [step-by-step guide](../../systems/object_stores/HOWTO.md.tmpl). Each step has the command to copy and the output to expect.

1. Steps 1 to 7: create the Python environment, put your settings in `.env.local`, run the preflight, onboard the sources, build the USL and check the helper packages.
2. Steps 8 to 11: probe the store, create the storage setting, materialize both tables and verify the whole chain.
3. Step 12: explore the data in a local viewer with a read-only SQL tab.
4. Step 14: record the run. One command repeats the test and writes a report you can send back.
5. Step 15: clean up the Zetaris objects and your folder in the bucket. Do this after step 14, because the report needs the USL.

Everything the test writes goes under your own folder in the bucket, so several people can share one bucket. That is a naming convention, not access control.

## Know before you start

- `MATERIALIZE USL TABLE` ignores the credentials of a saved storage setting on 2.4.3.1, so the statement carries the keys. The instance may keep it in query history. See the [write-up for Zetaris engineering](../../systems/object_stores/issues/ISSUE-01-materialize-ignores-storage-setting.md).
- A second `MATERIALIZE` into a folder you did not clear replaces its output. The guide clears the folder first.
- A bucket with object lock or a retention policy refuses the cleanup. No script works around that.
- Not yet checked on a real store: virtual-host addressing only, a private certificate authority, object lock or versioning switched on, and no batch delete.

## Testing a store for someone else

The [object store kit](../../systems/object_stores/README.md) builds a package for one partner. It puts the store's name in the documents and the viewer, checks that no key, bucket, endpoint or login name is in any file, and writes a ZIP. The person running it follows the same step-by-step guide and sends back the report.

If something fails, see the failure table in the guide (step 13) and [troubleshooting](troubleshooting.md).
