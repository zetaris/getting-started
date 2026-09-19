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

### Prerequisite: `CREATE LIGHTNING DATABASE` — CORRECTED, this package had this wrong

**Earlier revisions of this doc claimed the `FROM <logical_datasource_name>` value was just a label needing no prior setup. That's wrong, caught by live testing against a real Zetaris instance.** `<logical_datasource_name>` must be registered first with its own DDL statement, or `CREATE LIGHTNING FILESTORE TABLE ... FROM <name>` fails because `<name>` doesn't exist yet:

```sql
CREATE LIGHTNING DATABASE <logical_datasource_name> DESCRIBE BY "<short description>";
```

Run this once per logical datasource name **before** the first `CREATE LIGHTNING FILESTORE TABLE` statement that references it (a name used by multiple tables in the same script, e.g. `PUDL_S3`, only needs one `CREATE LIGHTNING DATABASE` call, not one per table). Every script in `sql/` has been updated with this statement. Source: the quick-start guide's own worked example (`CREATE LIGHTNING DATABASE TEST_DATABASE DESCRIBE BY " TEST_DATABASE";`), confirmed against kbase's description of the equivalent UI flow ("Virtual File Sources" — a database must be created before any tables can be assigned to it).

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
  AWSACCESSKEYID "...",
  AWSSECRETACCESSKEY "...",
  awsSessionToken "...",                  -- optional, for temporary STS creds
  s3Endpoint "https://...",               -- only for non-AWS S3-compatible storage
  useS3PathStyleAccess "true"             -- only for non-AWS S3-compatible storage
);
```

The scripts in this package use descriptive all-caps names for `<logical_datasource_name>` (`NOAA_GHCN_S3`, `PUDL_S3`, etc.) — same name in both the `CREATE LIGHTNING DATABASE` statement and the table's `FROM` clause.

---

## 2. Two things worth knowing about credentials and `PATH` before you run these

### Credentials on a public bucket — CONFIRMED: you need a real AWS key pair

All nine sources in this package live in publicly readable S3 (or S3-compatible) buckets — you can `aws s3 ls --no-sign-request` every one of them with no AWS account. That made it tempting to assume Zetaris could read them without real credentials too. **Live-tested against `sql/01_nyc_tlc.sql` (2026-09) and confirmed otherwise:**

| Tried | Result |
|---|---|
| Omit `AWSACCESSKEYID`/`AWSSECRETACCESSKEY` entirely | `403 Forbidden` from S3 (Zetaris still sends a *signed* request — it fills in something non-empty behind the scenes, just not anything this bucket accepts) |
| Empty strings (`""`, `""`) | `NoAwsCredentialsException: SimpleAWSCredentialsProvider: No AWS credentials in the Hadoop configuration` — fails Zetaris's own config validation before a request is even sent |
| Literal `"anonymous"` / `"anonymous"` | `403 Forbidden` — treated as a real (bogus) key pair, not a special anonymous-mode flag |

**Root cause:** the error text (`SimpleAWSCredentialsProvider`) confirms Zetaris's S3A connector is configured to always sign requests with a fixed, non-anonymous Hadoop credentials provider. There's no anonymous/unsigned-request mode reachable through the documented `OPTIONS` — unlike the plain `aws s3 --no-sign-request` CLI flag, which bypasses signing entirely, Zetaris always signs. A public bucket's anonymous-read ACL doesn't help if Zetaris never attempts an anonymous request in the first place.

**Confirmed path forward:** provision a free-tier AWS account with a minimal IAM user (`s3:GetObject`/`s3:ListBucket` on the relevant buckets is enough) and use that real key pair in `AWSACCESSKEYID`/`AWSSECRETACCESSKEY` — even though the bucket itself doesn't require one, Zetaris does. This applies to all nine AWS-native S3 sources in this package (everything except Foursquare's Source Cooperative/MinIO-style endpoint, which hasn't been tested this way yet and may behave differently — see `sql/04_foursquare_places.sql`).

### Plain HTTPS URLs as a `PATH` — CONFIRMED: not supported

**Live-tested (2026-09):** a plain `https://` `PATH` (the CloudFront URL, `https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet`) fails with a hard validation error — `Invalid file path to access` — not a fetch/network failure. Only `s3a://`/`wasb://`-style paths are accepted; HTTPS is rejected outright regardless of whether the file itself is reachable.

**This closes off NYC TLC's easy path entirely:** its S3 mirror (`s3://nyc-tlc`) is now also confirmed dead — `AccessDenied` on both an unsigned/anonymous request *and* a real, working IAM user's signed request (verified via `aws sts get-caller-identity` succeeding, then `aws s3 ls`/`head-object` against the bucket both failing). This isn't a credentials problem; the bucket itself no longer grants read access to anyone. See `sql/01_nyc_tlc.sql`'s updated Option B, now the only viable route: download the file from CloudFront, upload it into an S3 bucket you control, point Zetaris's `PATH` at that instead.

**This also settles the local-cache-to-Zetaris question for the pulled-forward sources (§3):** `tmp/cache/datagovsg/` and `tmp/cache/openfoodfacts/` files can't be read by Zetaris in place, and there's no HTTPS shortcut either — they need the same "upload to a bucket you control" treatment before a `CREATE LIGHTNING FILESTORE TABLE` statement can point at them.

**Practical note:** doing this requires `s3:PutObject`/`s3:CreateBucket` permissions, which a read-only IAM user (e.g. one using the `AmazonS3ReadOnlyAccess` managed policy) doesn't have — you'll need write permissions on whatever bucket you stage files in, separate from the read-only credentials used for the original public buckets.

Foursquare Places (Source Cooperative) hasn't been tested against this specific HTTPS finding yet, but given NYC TLC's result, assume its plain-HTTPS alternative (`https://data.source.coop/...`) is equally unsupported — `sql/04_foursquare_places.sql` already defaults to the S3-compatible-endpoint route, which is now confirmed as the only kind of `PATH` Zetaris accepts at all.

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
