# HOWTO: onboard these Parquet/CSV sources into Zetaris

The general walkthrough for the `sql/` scripts in this package — read this once before running any of them. A couple of sources also need a `scripts/` fetch step first — see §3.

---

## 1. The SQL syntax these scripts use

Every script uses `CREATE LIGHTNING FILESTORE TABLE`, Zetaris's DDL for registering a file-based external table (as opposed to `CREATE DATASOURCE`, for JDBC-backed relational sources, or `REGISTER REST DATASOURCE TABLE`, for REST APIs). References:

- **Data source overview** (file formats supported — CSV, JSON, Parquet, ORC, Delta, Avro, plus AWS S3/Azure Blob as storage locations): [kbase.zetaris.com/knowledge/connect](https://kbase.zetaris.com/knowledge/connect)
- **AWS S3 connection syntax** (`PATH`, `inferSchema`, `header`, `AWSACCESSKEYID`, `AWSSECRETACCESSKEY`, `awsSessionToken`): [kbase.zetaris.com/knowledge/amazon-s3-storage](https://kbase.zetaris.com/knowledge/amazon-s3-storage), [kbase.zetaris.com/knowledge/connection-to-aws-s3](https://kbase.zetaris.com/knowledge/connection-to-aws-s3)
- **S3-compatible (non-AWS) endpoint syntax** (`s3Endpoint`, `useS3PathStyleAccess`) — the pattern used for Foursquare's Source Cooperative hosting: [kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3](https://kbase.zetaris.com/knowledge/how-to-connect-to-minio-s3)
- **`FORMAT PARQUET`**: the MinIO and Amazon S3 how-to pages both show working `FORMAT PARQUET` examples, alongside CSV/JSON.
- **Quick-start walkthrough / UI equivalent**: [data-fabric.readthedocs.io Cloud Data Fabric Quick-Start Guide](https://data-fabric.readthedocs.io/en/latest/clouddatafabric/cloud-data-fabric-quick-start-guide.html)

The general shape:

```sql
CREATE LIGHTNING FILESTORE TABLE <table_name>
FROM <logical_datasource_name>
FORMAT <CSV | JSON | PARQUET>
OPTIONS (
  PATH "s3a://bucket/prefix/or/file.parquet",
  inferSchema "true",
  header "true",                          -- CSV only, omit for Parquet/JSON
  AWSACCESSKEYID "...",
  AWSSECRETACCESSKEY "...",
  awsSessionToken "...",                  -- optional, for temporary STS creds
  s3Endpoint "https://...",               -- only for non-AWS S3-compatible storage
  useS3PathStyleAccess "true"             -- only for non-AWS S3-compatible storage
);
```

`<logical_datasource_name>` (the `FROM ...` value) is just a label — it doesn't need a separate `CREATE DATASOURCE` statement first for filestore tables. The scripts in this package use descriptive all-caps names (`NOAA_GHCN_S3`, `PUDL_S3`, etc.).

---

## 2. Two things worth testing yourself before you assume they don't work

### Credentials on a public bucket

All nine sources in this package live in publicly readable S3 (or S3-compatible) buckets — you can `aws s3 ls --no-sign-request` every one of them with no AWS account. The Zetaris filestore syntax, as documented, always includes `AWSACCESSKEYID` and `AWSSECRETACCESSKEY` in `OPTIONS`, with no separately documented "skip auth" flag.

Three things worth trying, in order, before provisioning AWS credentials for buckets you don't own:

1. **Omit the credential keys entirely** and see what happens.
2. **Pass empty strings or a placeholder like `"anonymous"`** for both keys — this is a common pattern in `s3a://`-based connectors (Zetaris's `s3a://` scheme suggests it's built on the same Hadoop connector family), where an empty credential pair often means "use anonymous/unsigned requests."
3. **If neither works**, a free-tier AWS account with a minimal IAM user (`s3:GetObject`/`s3:ListBucket`) will get you a valid credential pair to authenticate with, even though the bucket itself doesn't require one.

### Plain HTTPS URLs (CloudFront, Source Cooperative's proxy) as a `PATH`

Every documented `PATH` example uses `s3a://`, `s3n://`, or `wasb://` — not a generic `https://` file URL. Two sources here are more naturally reached over HTTPS:

- **NYC TLC**'s primary distribution channel is a CloudFront URL (`https://d37ci6vzurychx.cloudfront.net/...`), not the S3 mirror (which has a history of intermittent availability — see `sql/01_nyc_tlc.sql`).
- **Foursquare Places** is reachable both via Source Cooperative's S3-compatible endpoint (what `sql/04_foursquare_places.sql` uses) and via plain HTTPS at `https://data.source.coop/...`.

Both affected scripts default to the S3-protocol route. If your Zetaris SQL Editor gives a clear error when you try an `https://` `PATH`, that will tell you directly whether it's supported.

---

## 3. Sources that need a local fetch step first

Two sources — pulled forward from later categories in the main manifest rather than being part of the original nine — don't expose a stable, hardcodable bucket/URL `PATH` the way the rest of this package does. `scripts/` has a small, dependency-free Python fetcher for each; run these *before* the corresponding `sql/` script, not instead of it.

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
2. For each script in `sql/`, in order:
   - Read the header comment — it names the listing command (`aws s3 ls --no-sign-request s3://...`) that confirms the current partition/release/version before you run the statement.
   - Fill in `AWSACCESSKEYID`/`AWSSECRETACCESSKEY` per the credentials guidance above.
   - Run the `CREATE LIGHTNING FILESTORE TABLE` statement(s).
   - Run the `SELECT ... LIMIT 10` verification query right after.
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
| 7 | `06_common_crawl_index.sql` | Different shape of data entirely (web metadata) |
| 8 | `09_aws_public_blockchain.sql` | License genuinely unresolved — good "how we handle an ambiguous one" example |
| 9 | `01_nyc_tlc.sql` | Optional — the one most likely to need troubleshooting |

---

## 5. Verifying a table actually has data

For every script:

1. `SELECT COUNT(*) FROM <table_name>;` — a zero count with no error usually means an empty `PATH` match, wrong prefix, or a credentials problem that didn't hard-fail. Check row count, not just that `CREATE TABLE` succeeded.
2. Spot-check a couple of column values against the schema described in that source's docs (linked in `parquet-csv-data-sources.md`) — this catches a wrong `inferSchema` result (every column coming back as a string, for example).
3. For the date/version-partitioned sources (Overture, Common Crawl, Ookla, GBIF, AWS Public Blockchain), re-run the bucket-listing command from that script's header comment shortly before you need it — a path that worked last week can 404 today if a new release rotated out the old one.

---

## 6. Going further

- **Adding another source:** find the bucket/endpoint, confirm the license by reading the actual license page, write the `CREATE LIGHTNING FILESTORE TABLE` statement using this document's syntax reference, and add a verification query.
- **JDBC/relational sources instead of files:** that's `CREATE DATASOURCE` syntax — see [kbase.zetaris.com/knowledge/connection-to-sql-server](https://kbase.zetaris.com/knowledge/connection-to-sql-server) and the "Registering Logical Datasources" example in the Lightning SQL Manual (`CREATE DATASOURCE ORACLE DESCRIBE BY "..." OPTIONS (jdbcdriver ..., jdbcurl ..., username ..., password ...)`). That's the right tool for the main guide's §5 (Postgres/Chinook/Pagila) sources, not this package.
- **REST APIs instead of files:** that's `REGISTER REST DATASOURCE TABLE`, e.g. `REGISTER REST DATASOURCE TABLE <name> FROM <datasource> SCHEMA (...) OPTIONS (endpoint "...", method "GET", requesttype "URLENCODED")` — relevant for the main guide's §4 (JSONPlaceholder, PokéAPI, Open Food Facts) and the NASA/data.gov/Singapore REST APIs, not covered by this package.

---

## 7. Everything else

For license details, direct data URLs, and per-source docs links, see `parquet-csv-data-sources.md` in this package. For every other category (Kafka, logs, JSON/REST, SQL RDBMS, PDFs, and the government open-data sections for Singapore/US/EU/UK/Canada/Australia/Mexico/Africa), see the main `quickstart-data-manifest.md`.
