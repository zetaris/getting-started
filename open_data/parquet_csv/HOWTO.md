# HOWTO: onboard these Parquet/CSV sources into Zetaris

The general walkthrough for the `sql/` scripts in this package. Seven are current runnable examples. The two SQL files marked `-- ! Forbidden` remain here as reference files and will be updated later. A couple of sources also need a `scripts/` fetch step first. See §3.

---

## 1. The SQL syntax these scripts use

Every runnable script uses `CREATE LIGHTNING FILESTORE TABLE`, Zetaris's DDL for registering a file-based external table (as opposed to `CREATE DATASOURCE`, for JDBC-backed relational sources, or `REGISTER REST DATASOURCE TABLE`, for REST APIs). References:

- **Data source overview** (file formats supported — CSV, JSON, Parquet, ORC, Delta, Avro, plus AWS S3/Azure Blob as storage locations): [kbase.zetaris.com/knowledge/connect](https://kbase.zetaris.com/knowledge/connect)
- **AWS S3 connection syntax** (`PATH`, `inferSchema`, `header`, `isS3BucketPublic`, `useS3PathStyleAccess`, `s3Endpoint`): [kbase.zetaris.com/knowledge/amazon-s3-storage](https://kbase.zetaris.com/knowledge/amazon-s3-storage), [kbase.zetaris.com/knowledge/connection-to-aws-s3](https://kbase.zetaris.com/knowledge/connection-to-aws-s3)
- **S3-compatible endpoint syntax** (`s3Endpoint`, `useS3PathStyleAccess`) — the pattern used for Foursquare's Source Cooperative hosting: [kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3](https://kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3)
- **`FORMAT PARQUET`**: the MinIO and Amazon S3 how-to pages both show working `FORMAT PARQUET` examples, alongside CSV/JSON.
- **Quick-start walkthrough / UI equivalent**: [data-fabric.readthedocs.io Cloud Data Fabric Quick-Start Guide](https://data-fabric.readthedocs.io/en/latest/clouddatafabric/cloud-data-fabric-quick-start-guide.html)

### Prerequisite: `CREATE LIGHTNING DATABASE` — CORRECTED, this package had this wrong

**Earlier revisions of this doc claimed the `FROM <logical_datasource_name>` value was just a label needing no prior setup. That's wrong, caught by live testing against a real Zetaris instance.** `<logical_datasource_name>` must be registered first with its own DDL statement, or `CREATE LIGHTNING FILESTORE TABLE ... FROM <name>` fails because `<name>` doesn't exist yet:

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";
```

Run this once per logical datasource name **before** the first `CREATE LIGHTNING FILESTORE TABLE` statement that references it (a name used by multiple tables in the same script, e.g. `PUDL_S3`, only needs one `CREATE LIGHTNING DATABASE` call, not one per table). Every runnable script in `sql/` includes this prerequisite. Source: the quick-start guide's own worked example (`CREATE LIGHTNING DATABASE TEST_DATABASE DESCRIBE BY " TEST_DATABASE";`), confirmed against kbase's description of the equivalent UI flow ("Virtual File Sources". A database must be created before any tables can be assigned to it).

The general shape, now with the prerequisite included:

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

The runnable scripts target public S3 or S3-compatible locations. They set `isS3BucketPublic "true"` and do not include AWS credential values. AWS-native sources use the regional S3 endpoint shown in each script. Foursquare uses `https://data.source.coop` as its S3-compatible endpoint. The scripts use descriptive all-caps names for `<logical_datasource_name>` (`NOAA_GHCN_S3`, `PUDL_S3`, etc.), with the same name in the `CREATE LIGHTNING DATABASE` statement and the table's `FROM` clause.

---

## 2. Public S3 access and `PATH`

### Use the public-bucket options in the scripts

The seven runnable sources are public S3 or S3-compatible sources. Their current SQL uses the same access pattern:

| Option | Use |
|---|---|
| `isS3BucketPublic "true"` | Tells Zetaris that the source is publicly readable. |
| `useS3PathStyleAccess "true"` | Enables the path-style S3 access used by these scripts. |
| `s3Endpoint "..."` | Selects the AWS regional endpoint or the S3-compatible host. |

These public-source examples do not need AWS credential values. If you adapt the pattern for a private bucket, use the credential options in Zetaris's S3 documentation instead.

### Keep source URLs separate from the Zetaris `PATH`

The catalog may show a browser or download URL for a source. The runnable SQL scripts use an `s3a://` value in `PATH`. Put an S3-compatible HTTPS host in `s3Endpoint`, as the Foursquare script does, rather than replacing `PATH` with the catalog's browser URL.

---

## 3. Sources that need a local fetch step first

Two sources pulled forward from later categories in the main manifest do not expose a stable, hardcodable bucket/URL `PATH` like the seven runnable sources do. `scripts/` has a small, dependency-free Python fetcher for each. Run these before attempting to create a corresponding SQL registration. Neither source has an onboarding SQL script yet.

### `scripts/fetch_datagovsg.py` — a data.gov.sg CSV dataset (Singapore)

data.gov.sg doesn't serve a static file per dataset. It hands back a **presigned, expiring S3 URL** through a REST call, so there's nothing stable to put in a `PATH` directly.

```bash
python3 scripts/fetch_datagovsg.py
```

- Calls the `initiate-download` / `poll-download` API (no key needed for casual use) and saves the result to `../../tmp/cache/datagovsg/<dataset_id>.csv` (i.e. `tmp/cache/datagovsg/` at the repo root — gitignored, never commit what lands there).
- Default dataset: `d_8b84c4ee58e3cfc0ece0d773c8ca6abc` — "Resale flat prices based on registration date from Jan-2017 onwards." Live-tested: a real, comma-separated, header-included CSV, ~24 MB / ~240k rows.
- **Live-behavior note:** the published API docs describe a `code: 201` response requiring a separate poll step. In practice (tested 2026-09) the API returns `code: 0` with the download URL already included in the `initiate-download` response — the script handles both, but don't be surprised if you see `code: 0` while reading the docs.
- Prints the required Singapore Open Data Licence (SODL) v1.0 attribution line on completion — copy it into whatever you publish.
- Re-run before each use rather than reusing an old cached copy: the download URL is presigned with an expiry, and the underlying dataset itself updates periodically.
- **Not yet resolved:** how Zetaris should actually read the cached file. Every other script in this package points `PATH` at a stable `s3a://`/`wasb://` location; a local cache directory isn't one of the documented `PATH` schemes (see §1). Until that's confirmed — either Zetaris accepts a local/mounted filesystem path, or the cached file needs to be re-uploaded somewhere Zetaris can reach — there's no `sql/10_datagovsg_*.sql` yet. Treat the fetch step as done and the registration step as open.

### `scripts/fetch_openfoodfacts.py` — Open Food Facts bulk export

The manifest recommends the bulk export over the live API for anything beyond single-product lookups (custom `User-Agent` + per-endpoint rate limits make the live API a poor fit for bulk pulls).

```bash
python3 scripts/fetch_openfoodfacts.py                    # full export, ~0.9 GB compressed
python3 scripts/fetch_openfoodfacts.py --sample-rows 5000  # + a small quickstart-sized sample
```

- Downloads `https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz` (nightly-generated) to `tmp/cache/openfoodfacts/`.
- `--sample-rows N` streams a small `sample_<N>rows.csv` out of the gzip without a full decompress first — useful since the full export is ~9 GB uncompressed, far more than a quickstart demo needs.
- **Important:** despite the `.csv` extension, this export is **tab-separated**, not comma-separated. Whatever reads it downstream needs to know that.
- Prints the required ODbL attribution + share-alike note on completion.
- **Not yet resolved, same as above:** the local-cache-to-Zetaris `PATH` question, plus whether Zetaris's `FORMAT CSV` options support a custom delimiter for the tab-separated file. No `sql/11_openfoodfacts.sql` yet.

---

## 4. Running the scripts

1. Open the Zetaris **SQL Editor** ([SQL Editor overview](https://kbase.zetaris.com/knowledge/sql-editor-overview), [How to Save and Re-use SQL](https://kbase.zetaris.com/knowledge/how-to-save-and-re-use-sql)).
2. For each runnable script in `sql/`, in order. Skip any file containing the `-- ! Forbidden` marker:
   - Read the header comment — it names the listing command (`aws s3 ls --no-sign-request s3://...`) that confirms the current partition/release/version before you run the statement.
   - Check that the `PATH` and `s3Endpoint` values still point at the intended current source.
   - Run the `CREATE LIGHTNING FILESTORE TABLE` statement(s).
   - Run the fully qualified `SELECT ... LIMIT 10` verification query included in the script right after.
3. Once created, a table shows up in Zetaris's Schema Browser and is queryable from the Query Builder UI as well as the SQL Editor.

Suggested order — cleanest license first, in case you want to stop partway through:

| Order | Script | Why here |
|---|---|---|
| 1 | `03_pudl.sql` | Cleanest license (CC-BY-4.0), reliable AWS-native bucket |
| 2 | `04_foursquare_places.sql` | Cleanest license (Apache-2.0), shows the S3-compatible-endpoint pattern |
| 3 | `02_noaa_ghcn.sql` | CC0, and shows CSV onboarding specifically |
| 4 | `05_overture_maps.sql` | Large-scale GeoParquet, simple caveat ("stick to Places theme") |
| 5 | `08_gbif.sql` | Biggest scale (1.6B+ rows), good "filter before SELECT *" example |
| 6 | `07_ookla_speedtest.sql` | Same non-commercial caveat pattern as GBIF, different domain |
| 7 | `09_aws_public_blockchain.sql` | License genuinely unresolved — good "how we handle an ambiguous one" example |

The following scripts remain in the package for later update. Do not run them while they carry the forbidden marker:

- `sql/01_nyc_tlc.sql`
- `sql/06_common_crawl_index.sql`

---

## 5. Verifying a table actually has data

For every runnable script:

1. `SELECT COUNT(*) FROM <logical_datasource_name>.<table_name>;` — a zero count with no error usually means an empty `PATH` match, wrong prefix, or a source configuration problem that didn't hard-fail. Check row count, not just that `CREATE TABLE` succeeded.
2. Spot-check a couple of column values against the schema described in that source's docs (linked in `parquet-csv-data-sources.md`) — this catches a wrong `inferSchema` result (every column coming back as a string, for example).
3. For the date/version/release-partitioned sources (PUDL, Foursquare, Overture, Ookla, GBIF, AWS Public Blockchain), re-run the bucket-listing command from that script's header comment shortly before you need the source. A path can stop working when a new release replaces an old one.

---

## 6. Going further

- **Adding another source:** find the bucket/endpoint, confirm the license by reading the actual license page, write the `CREATE LIGHTNING FILESTORE TABLE` statement using this document's syntax reference, and add a verification query.
- **JDBC/relational sources instead of files:** that's `CREATE DATASOURCE` syntax — see [kbase.zetaris.com/knowledge/connection-to-sql-server](https://kbase.zetaris.com/knowledge/connection-to-sql-server) and the "Registering Logical Datasources" example in the Lightning SQL Manual (`CREATE DATASOURCE ORACLE DESCRIBE BY "..." OPTIONS (jdbcdriver ..., jdbcurl ..., username ..., password ...)`). That's the right tool for the main guide's §5 (Postgres/Chinook/Pagila) sources, not this package.
- **REST APIs instead of files:** that's `REGISTER REST DATASOURCE TABLE`, e.g. `REGISTER REST DATASOURCE TABLE <name> FROM <datasource> SCHEMA (...) OPTIONS (endpoint "...", method "GET", requesttype "URLENCODED")` — relevant for the main guide's §4 (JSONPlaceholder, PokéAPI, Open Food Facts) and the NASA/data.gov/Singapore REST APIs, not covered by this package.

---

## 7. Everything else

For license details, direct data URLs, and per-source docs links, see `parquet-csv-data-sources.md` in this package. For every other category (Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections for Singapore/US/EU/UK/Canada/Australia/Mexico/Africa), see the main `quickstart-data-manifest.md`.
