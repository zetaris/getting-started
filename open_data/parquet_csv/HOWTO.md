# HOWTO: onboard these Parquet/CSV sources into Zetaris

Start with [Start here](../../START-HERE.md) and the [PokéAPI starter](../../docs/guides/first-dataset.md). On your own local or AWS instance, use your chosen database names. File sources are optional follow-up work.

This guide covers the current CREATE/SELECT SQL pairs. All seven are in `sql/`. Earlier failure records stay under `sql/known_to_fail/`. The catalog lists each source and its script. The two Python fetchers in `scripts/` prepare local files but do not register tables in Zetaris; see §3.

**Source folders:** NOAA, PUDL, Foursquare, Overture Maps, Ookla, GBIF, and AWS Public Blockchain are in `sql/`. Earlier failure records for sources that now verify stay in `sql/known_to_fail/`. See the [catalog](parquet-csv-data-sources.md).

---

## 1. The SQL syntax these scripts use

These scripts register files with `CREATE LIGHTNING FILESTORE TABLE`. Use `CREATE DATASOURCE` for JDBC sources and `CREATE LIGHTNING REST TABLE` plus `CREATE SCHEMASTORE VIEW` for REST APIs. References:

- **Formats and storage:** [data source overview](https://kbase.zetaris.com/knowledge/connect)
- **S3 paths and options:** [Amazon S3](https://kbase.zetaris.com/knowledge/amazon-s3-storage), [S3 connection](https://kbase.zetaris.com/knowledge/connection-to-aws-s3), and [S3-compatible endpoints](https://kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3)
- **Parquet syntax:** the MinIO and Amazon S3 guides include `FORMAT PARQUET` examples.
- **UI walkthrough:** [Cloud Data Fabric Quick-Start Guide](https://data-fabric.readthedocs.io/en/latest/clouddatafabric/cloud-data-fabric-quick-start-guide.html)

### Prerequisite: register the logical database first

Register `<logical_datasource_name>` before referencing it in a file table's `FROM` clause. Otherwise table creation fails:

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";
```

Run this once per logical database, before its first table. One registration covers multiple tables from the same source. Each current `_create.sql` pair includes it.

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

These scripts use public S3 or S3-compatible paths and contain no AWS credentials. NOAA, PUDL, and Foursquare registration and queries were confirmed live without credentials. On 2026-10-31 a new table on `pudl.catalyst.coop` registered with `useS3PathStyleAccess "true"` and both PUDL verification queries returned rows. The same day, Foursquare's Source Cooperative endpoint (`https://data.source.coop`, path-style) answered a bounded `SELECT` and the analytical queries. Scripts use each source's regional endpoint and the same logical database name in `CREATE LIGHTNING DATABASE` and `FROM`.

---

## 2. Public S3 access and `PATH`

### Use the public-bucket options in the scripts

The seven SQL pairs use public-source options; endpoints and regions vary:

| Option | Use |
|---|---|
| `isS3BucketPublic "true"` | Tells Zetaris that the source is publicly readable. |
| `useS3PathStyleAccess "true"` | Enables the path-style S3 access used by these scripts. |
| `s3Endpoint "..."` | Selects the AWS regional endpoint or the S3-compatible host. |

The scripts contain no AWS credentials. For private buckets, use Zetaris's S3 credential options. NOAA's live run confirms that source works without credentials.

**Dotted bucket names.** PUDL's `pudl.catalyst.coop` bucket registered and queried on 2026-10-31 with `useS3PathStyleAccess "true"` and `s3Endpoint "s3.us-west-2.amazonaws.com"`. Keep path-style access on for a bucket name that contains dots.

### Keep source URLs separate from the Zetaris `PATH`

Use the `s3a://` path from the SQL script in `PATH`. Put an S3-compatible HTTPS host, such as Foursquare's, in `s3Endpoint`; a browser or download URL is not a replacement for `PATH`.

---

## 3. Sources that need a local fetch step first

These repository-root [`scripts/`](../../scripts/) fetchers save local files; they do not register Zetaris tables, and neither source has a SQL pair yet. Run them from the repository root.

### `scripts/fetch_datagovsg.py` — a data.gov.sg CSV dataset (Singapore)

data.gov.sg returns a **presigned, expiring S3 URL** through its API, not a stable dataset path.

```bash
python3 scripts/fetch_datagovsg.py
```

- Saves `tmp/cache/datagovsg/<dataset_id>.csv` (gitignored). Default dataset `d_8b84c4ee58e3cfc0ece0d773c8ca6abc` ("Resale flat prices based on registration date from Jan-2017 onwards") was live-tested as a comma-separated, headered CSV, about 24 MB and 240,000 rows.
- Handles both direct (`code: 0`) and polled (`code: 201`) downloads; no key is needed for casual use.
- Prints the SODL v1.0 attribution line. Re-fetch before use because URLs expire and the dataset updates.
- Zetaris cannot read this local cache by a documented `PATH`; move the file to reachable storage before registering it.

### `scripts/fetch_openfoodfacts.py` — Open Food Facts bulk export

Use the bulk export for larger downloads; the live API is for individual products.

```bash
python3 scripts/fetch_openfoodfacts.py                    # full export, ~0.9 GB compressed
python3 scripts/fetch_openfoodfacts.py --sample-rows 5000  # + a small quickstart-sized sample
```

- Downloads the [nightly export](https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz) to `tmp/cache/openfoodfacts/`. `--sample-rows N` extracts a small sample without decompressing the full file (about 9 GB uncompressed).
- Despite the `.csv` extension, the file is tab-separated. Confirm delimiter support or convert it before adding a Zetaris table script.
- Prints the ODbL attribution and share-alike note. No Zetaris SQL registration exists for this local file.

---

## 4. Running the scripts

Each source has a numbered `_create.sql` and `_select.sql` pair. Run complete CREATE statements separately. The SELECT file runs its primary verification query; optional-table and example queries stay commented until those tables exist.

1. Open the Zetaris [SQL Editor](https://kbase.zetaris.com/knowledge/sql-editor-overview).
2. Choose a source from the [catalog](parquet-csv-data-sources.md), then:
   - Run the header's listing command (`aws s3 ls --no-sign-request s3://...`) to confirm the current partition or release.
   - Check that the `PATH` and `s3Endpoint` values still point at the intended current source.
   - Run the complete `CREATE LIGHTNING FILESTORE TABLE` statement(s) in `_create.sql`.
   - Open and run the matching `_select.sql` verification query.
3. The created table appears in the Schema Browser and can be queried from Query Builder or the SQL Editor.

Suggested order — confirmed-working, simplest license first, in case you want to stop partway through:

| Order | Script | Why here |
|---|---|---|
| 1 | `02_noaa_ghcn_create.sql` | Live-tested and confirmed working. CC0, and shows CSV onboarding specifically — remember to `CACHE TABLE` before the analytical queries (see its own header). |
| 2 | `03_pudl_create.sql` | Live-tested 2026-10-31. CC-BY-4.0. Two small public Parquet files, including a dotted bucket name that works with path-style access. |
| 3 | `09_aws_public_blockchain_create.sql` | Live-tested and confirmed working (both BTC and ETH tables). License genuinely unresolved — good "how we handle an ambiguous one" example. Caching is also confirmed to work here, but asymmetrically between tables and mechanisms — see its own header. |
| 4 | `04_foursquare_places_create.sql` | Live-tested 2026-10-31 on release `2024-11-19`. Apache-2.0. Example queries keep a Manhattan lat/lon window. Each one still reads the release prefix (about 10.4 GiB, more than 100 million places in the full release) and took about 63–75 seconds. |
| 5 | `05_overture_maps_create.sql` | Live-tested 2026-10-31 on release `2026-10-21.0`. Places theme is CDLA-Permissive-2.0. Example queries keep a Manhattan bbox. Each one still reads the release prefix (about 11 GB) and took about 84–95 seconds. |
| 6 | `08_gbif_create.sql` | Live-tested 2026-10-31 on snapshot `2026-10-01`, file `004990` only. Aggregate CC-BY-NC. The snapshot directory is 10,448 files and 282.17 GiB, so the script does not register it. Example queries filter to Australian birds in that one file (17,402 rows) and took about 1.0–1.6 seconds. |
| 7 | `07_ookla_speedtest_create.sql` | Live-tested 2026-10-31 on 2026 quarter=2, one file each for fixed and mobile. CC BY-NC-SA 4.0, non-commercial. Example queries keep a Manhattan window on `tile_x`/`tile_y`. Each one reads that one file and took about 4–19 seconds. |

Earlier failure records for sources that now verify stay in [sql/known_to_fail/](sql/known_to_fail/README.md).

---

## 5. Verifying a table actually has data

For each runnable script:

1. Start with `SELECT * FROM <logical_datasource_name>.<table_name> LIMIT 10;`. Check row counts only after checking the source size and query scope. A zero count may mean the `PATH` matched no files or the configuration is wrong.
2. Compare sample values with the source schema to catch incorrect `inferSchema` results.
3. Re-run each partitioned source's header listing command shortly before use; releases and snapshots change.
4. Large uncached files may be slow because each query scans S3 again. `CACHE TABLE` helped on NOAA and is required by its example; see the [SQL companion](../../docs/guides/zetaris-lightning-sql-companion.md#5-operational-limitations-confirmed-live-not-documentation-guesses) for cache limits.

---

## 6. Going further

- **Add a source:** verify its license, bucket/path, and current release, then add a CREATE statement and verification query.
- **JDBC sources:** use `CREATE DATASOURCE`; see [SQL Server connection syntax](https://kbase.zetaris.com/knowledge/connection-to-sql-server).
- **REST APIs:** use `CREATE LIGHTNING REST TABLE` and `CREATE SCHEMASTORE VIEW`; see [`../rest_apis/HOWTO.md`](../rest_apis/HOWTO.md).

---

## 7. Everything else

For licenses, paths, and source links, see [`parquet-csv-data-sources.md`](parquet-csv-data-sources.md). Other categories are tracked in [`docs/plans/FUTURES.md`](../../docs/plans/FUTURES.md).
