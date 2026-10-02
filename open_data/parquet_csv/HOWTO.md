# HOWTO: onboard these Parquet/CSV sources into Zetaris

This guide covers the seven current CREATE/SELECT SQL pairs in `sql/`. The catalog lists each source and its script. The two Python fetchers in `scripts/` prepare local files but do not register tables in Zetaris; see §3.

**Source folders:** two of the seven pairs live directly in `sql/`. Five live in `sql/known_to_fail/`: PUDL and Ookla both fail to register at all (`CREATE LIGHTNING FILESTORE TABLE` itself fails) for different reasons — PUDL's bucket's dotted name (`pudl.catalyst.coop`) isn't accepted by Zetaris's S3 filestore connector, Ookla's bucket has no dots and its 500 error's cause is unconfirmed; Foursquare's table creates successfully but its `CACHE TABLE` and every query fail with a 500 error; Overture's table creates successfully and its plain, bounded `SELECT` works, but its `CACHE TABLE` and every analytical query fail or hang; and GBIF's table creates and even caches successfully via the GUI, but every query against it — including the plain filtered verification SELECT — fails with a 500 error. All five are kept as documented, reproducible examples rather than deleted; none is part of the main sequence below. See `sql/known_to_fail/README.md` and its per-source `ISSUE-NN-<name>.md` files.

---

## 1. The SQL syntax these scripts use

Every active CREATE script uses `CREATE LIGHTNING FILESTORE TABLE`, Zetaris's DDL for registering a file-based external table. Use `CREATE DATASOURCE` for JDBC-backed relational sources and `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` for REST APIs. References:

- **Data source overview** (file formats supported — CSV, JSON, Parquet, ORC, Delta, Avro, plus AWS S3/Azure Blob as storage locations): [kbase.zetaris.com/knowledge/connect](https://kbase.zetaris.com/knowledge/connect)
- **AWS S3 connection syntax** (`PATH`, `inferSchema`, `header`, `isS3BucketPublic`, `useS3PathStyleAccess`, `s3Endpoint`): [kbase.zetaris.com/knowledge/amazon-s3-storage](https://kbase.zetaris.com/knowledge/amazon-s3-storage), [kbase.zetaris.com/knowledge/connection-to-aws-s3](https://kbase.zetaris.com/knowledge/connection-to-aws-s3)
- **S3-compatible endpoint syntax** (`s3Endpoint`, `useS3PathStyleAccess`) — the pattern used for Foursquare's Source Cooperative hosting: [kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3](https://kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3)
- **`FORMAT PARQUET`**: the MinIO and Amazon S3 how-to pages both show working `FORMAT PARQUET` examples, alongside CSV/JSON.
- **Quick-start walkthrough / UI equivalent**: [data-fabric.readthedocs.io Cloud Data Fabric Quick-Start Guide](https://data-fabric.readthedocs.io/en/latest/clouddatafabric/cloud-data-fabric-quick-start-guide.html)

### Prerequisite: register the logical database first

Register `<logical_datasource_name>` before a file table uses it in `FROM`. Otherwise the table statement fails because the logical database does not exist:

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";
```

Run this once per logical database name, before the first table that references it. If one script creates several tables from the same source, one database registration covers them all. Each current `_create.sql` pair includes this prerequisite.

The general pattern is:

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";

CREATE LIGHTNING FILESTORE TABLE <table_name>
FROM <logical_datasource_name>
FORMAT <CSV | JSON | PARQUET>
OPTIONS (
  PATH "s3a://bucket/prefix/or/file.parquet",
  inferSchema "true",
  header "true",                          -- CSV only, omit for Parquet/JSON
  isS3BucketPublic "true",
  useS3PathStyleAccess "true",
  s3Endpoint "s3.<region>.amazonaws.com"
);
```

The current SQL pairs target public S3 or S3-compatible locations and set `isS3BucketPublic "true"`; they do not include AWS credentials. NOAA GHCN-Daily has been confirmed live against a real Zetaris instance with no AWS credentials needed (`sql/02_noaa_ghcn_create.sql` / `_select.sql`). The [installation test record](../../docs/install/zetaris-installation-test-record.md) separately records an earlier successful PUDL run against the same no-credentials pattern — that specific source is now known to fail (`sql/known_to_fail/03_pudl_create.sql`, dotted bucket name; see its `ISSUE-03-pudl.md`), a contradiction not yet reconciled. AWS sources use the regional endpoint in each script. Foursquare uses Source Cooperative's S3-compatible endpoint, and its table registration succeeds, but querying it is also known to fail — see `sql/known_to_fail/ISSUE-04-foursquare.md`. Each script uses the same logical database name in `CREATE LIGHTNING DATABASE` and the table's `FROM` clause.

---

## 2. Public S3 access and `PATH`

### Use the public-bucket options in the scripts

The seven current SQL pairs use public-source options. The endpoint and region vary by source:

| Option | Use |
|---|---|
| `isS3BucketPublic "true"` | Tells Zetaris that the source is publicly readable. |
| `useS3PathStyleAccess "true"` | Enables the path-style S3 access used by these scripts. |
| `s3Endpoint "..."` | Selects the AWS regional endpoint or the S3-compatible host. |

The scripts do not contain AWS credential values. For a private bucket, use the credential options in Zetaris's S3 documentation instead. NOAA GHCN-Daily's confirmed live run shows one source works without credentials; the catalog and test record keep source-specific runtime evidence separate.

**A bucket name containing a `.` is confirmed to fail, even with `useS3PathStyleAccess "true"` set.** PUDL's `pudl.catalyst.coop` bucket is the one dotted name in this catalog, and it's the one source that fails `CREATE LIGHTNING FILESTORE TABLE` — see `sql/known_to_fail/03_pudl_create.sql` and its `ISSUE.md`. Path-style addressing is the standard S3-client fix for dotted bucket names elsewhere, but it doesn't appear to fix this in Zetaris. Check a new source's bucket name for dots before assuming the syntax here will just work.

### Keep source URLs separate from the Zetaris `PATH`

The catalog may show a browser or download URL for a source. The runnable SQL scripts use an `s3a://` value in `PATH`. Put an S3-compatible HTTPS host in `s3Endpoint`, as the Foursquare script does, rather than replacing `PATH` with the catalog's browser URL.

---

## 3. Sources that need a local fetch step first

These fetchers prepare local files only. They do not create Zetaris tables, and neither source has an onboarding SQL pair yet. They live in the repo's top-level [`scripts/`](../../scripts/) directory alongside the Zetaris API helpers, not under this package — run the commands from the repository root.

### `scripts/fetch_datagovsg.py` — a data.gov.sg CSV dataset (Singapore)

data.gov.sg doesn't serve a static file per dataset. It hands back a **presigned, expiring S3 URL** through a REST call, so there's nothing stable to put in a `PATH` directly.

```bash
python3 scripts/fetch_datagovsg.py
```

- Calls the `initiate-download` / `poll-download` API (no key needed for casual use) and saves the result to `tmp/cache/datagovsg/<dataset_id>.csv` at the repo root — gitignored, never commit what lands there.
- Default dataset: `d_8b84c4ee58e3cfc0ece0d773c8ca6abc` — "Resale flat prices based on registration date from Jan-2017 onwards." Live-tested: a real, comma-separated, header-included CSV, ~24 MB / ~240k rows.
- The API may return the download URL directly (`code: 0`) or require a separate poll (`code: 201`). The script handles both responses.
- Prints the required Singapore Open Data Licence (SODL) v1.0 attribution line on completion — copy it into whatever you publish.
- Re-run before each use rather than reusing an old cached copy: the download URL is presigned with an expiry, and the underlying dataset itself updates periodically.
- Zetaris cannot read this local cache through a documented `PATH` scheme. To add an SQL registration, first make the file available from storage that Zetaris can reach.

### `scripts/fetch_openfoodfacts.py` — Open Food Facts bulk export

The bulk export is suitable for large downloads; the live API is intended for individual product lookups.

```bash
python3 scripts/fetch_openfoodfacts.py                    # full export, ~0.9 GB compressed
python3 scripts/fetch_openfoodfacts.py --sample-rows 5000  # + a small quickstart-sized sample
```

- Downloads `https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz` (nightly-generated) to `tmp/cache/openfoodfacts/` at the repo root.
- `--sample-rows N` streams a small `sample_<N>rows.csv` out of the gzip without a full decompress first — useful since the full export is ~9 GB uncompressed, far more than a quickstart demo needs.
- **Important:** despite the `.csv` extension, this export is **tab-separated**, not comma-separated. Whatever reads it downstream needs to know that.
- Prints the required ODbL attribution + share-alike note on completion.
- There is no Zetaris SQL registration for this local file. The export is tab-separated, so confirm delimiter support or convert it before adding a table script.

---

## 4. Running the scripts

Each current source has two files sharing a numeric prefix: `sql/NN_<name>_create.sql` (setup DDL) and `sql/NN_<name>_select.sql` (verification and example queries). Run the CREATE file first. The primary verification query runs when you execute the SELECT file; queries for optional tables and examples remain commented until those tables are created.

1. Open the Zetaris **SQL Editor** ([SQL Editor overview](https://kbase.zetaris.com/knowledge/sql-editor-overview), [How to Save and Re-use SQL](https://kbase.zetaris.com/knowledge/how-to-save-and-re-use-sql)).
2. Choose a source from the [catalog](parquet-csv-data-sources.md), then:
   - Read the header comment in `_create.sql` — it names the listing command (`aws s3 ls --no-sign-request s3://...`) that confirms the current partition/release/version before you run the statement.
   - Check that the `PATH` and `s3Endpoint` values still point at the intended current source.
   - Run the `CREATE LIGHTNING FILESTORE TABLE` statement(s) in `_create.sql`.
   - Open and run the matching `_select.sql` verification query.
3. Once created, a table shows up in Zetaris's Schema Browser and is queryable from the Query Builder UI as well as the SQL Editor.

Suggested order — confirmed-working, simplest license first, in case you want to stop partway through:

| Order | Script | Why here |
|---|---|---|
| 1 | `02_noaa_ghcn_create.sql` | Live-tested and confirmed working. CC0, and shows CSV onboarding specifically — remember to `CACHE TABLE` before the analytical queries (see its own header). |
| 2 | `09_aws_public_blockchain_create.sql` | Live-tested and confirmed working (both BTC and ETH tables). License genuinely unresolved — good "how we handle an ambiguous one" example. Caching is also confirmed to work here, but asymmetrically between tables and mechanisms — see its own header. |

**Not in this sequence:** `sql/known_to_fail/03_pudl_create.sql` is excluded — its bucket's dotted name isn't accepted by Zetaris's S3 filestore connector. `sql/known_to_fail/04_foursquare_places_create.sql` is also excluded — its table creates successfully, but `CACHE TABLE` and every query against it fail with a 500 error. `sql/known_to_fail/05_overture_maps_create.sql` is also excluded — its table creates successfully and a plain, bounded `SELECT` works, but `CACHE TABLE` and every analytical query fail or hang. `sql/known_to_fail/07_ookla_speedtest_create.sql` is also excluded — both its `CREATE LIGHTNING FILESTORE TABLE` statements fail with a 500 error, and unlike PUDL its bucket name has no dots to explain it. `sql/known_to_fail/08_gbif_create.sql` is also excluded — its table creates and even caches successfully via the GUI, but every query against it, including the plain filtered verification SELECT, fails with a 500 error. See "Source folders" above and `sql/known_to_fail/ISSUE-03-pudl.md` / `ISSUE-04-foursquare.md` / `ISSUE-05-overture.md` / `ISSUE-07-ookla.md` / `ISSUE-08-gbif.md`.

---

## 5. Verifying a table actually has data

For every runnable script:

1. `SELECT COUNT(*) FROM <logical_datasource_name>.<table_name>;` — a zero count with no error usually means an empty `PATH` match, wrong prefix, or a source configuration problem that didn't hard-fail. Check row count, not just that `CREATE TABLE` succeeded.
2. Spot-check a couple of column values against the schema described in that source's docs (linked in `parquet-csv-data-sources.md`) — this catches a wrong `inferSchema` result (every column coming back as a string, for example).
3. For the date/version/release-partitioned sources (PUDL, Foursquare, Overture, Ookla, GBIF, AWS Public Blockchain), re-run the bucket-listing command from that script's header comment shortly before you need the source. A path can stop working when a new release replaces an old one.
4. For a large single-file source, expect uncached queries to be slow — each one re-scans the underlying file over S3. `CACHE TABLE <logical_datasource_name>.<table_name>;` is confirmed to help (see `sql/02_noaa_ghcn_create.sql`, where it's required rather than optional); see [`docs/guides/zetaris-lightning-sql-companion.md` section 5](../../docs/guides/zetaris-lightning-sql-companion.md#5-operational-limitations-confirmed-live-not-documentation-guesses) for what's confirmed about `CACHE TABLE` generally, including its known gaps.

---

## 6. Going further

- **Adding another source:** find the bucket/endpoint, confirm the license by reading the actual license page, write the `CREATE LIGHTNING FILESTORE TABLE` statement using this document's syntax reference, and add a verification query.
- **JDBC/relational sources instead of files:** that's `CREATE DATASOURCE` syntax — see [kbase.zetaris.com/knowledge/connection-to-sql-server](https://kbase.zetaris.com/knowledge/connection-to-sql-server) and the "Registering Logical Datasources" example in the Lightning SQL Manual (`CREATE DATASOURCE ORACLE DESCRIBE BY "..." OPTIONS (jdbcdriver ..., jdbcurl ..., username ..., password ...)`). That's the right tool for the main guide's §5 (Postgres/Chinook/Pagila) sources, not this package.
- **REST APIs instead of files:** use `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW`; see [`../rest_apis/HOWTO.md`](../rest_apis/HOWTO.md).

---

## 7. Everything else

For license details, direct data URLs, and per-source docs links, see `parquet-csv-data-sources.md` in this package. For every other category (Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections for Singapore/US/EU/UK/Canada/Australia/Mexico/Africa), see `docs/plans/FUTURES.md` and its `recipes/*.md` files.
