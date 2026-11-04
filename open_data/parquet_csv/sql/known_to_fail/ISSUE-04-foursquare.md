# Failure case: Foursquare Open Source Places — table creates, but `CACHE TABLE` and every query fail with a 500 error

**Status:** Superseded on 2026-10-31. Re-tested on a self-hosted Zetaris 2.4.3.1 instance (the hackathon Docker images, Path A of the installation guide). The earlier failure was recorded on a different environment, and why it no longer reproduces is not established. The same `PATH` (`s3a://fused/fsq-os-places/2024-11-19/places/`, still listed; 81 Parquet files, 11159985690 bytes) registered already and then answered `DESCRIBE` (24 columns), `SELECT * LIMIT 10` (10 rows), and every analytical query in the updated select script. The release README says more than 100 million places, so those aggregations used a Manhattan window (`latitude` 40.70–40.82, `longitude` -74.02–-73.93): 352,530 places, 1 country, 142,272 with a website, 88,445 with `date_closed` set. Each aggregation read the prefix in about 63–75 seconds. `CREATE` of the existing database and table returned HTTP 400 already exists. `CACHE TABLE` was not re-run. The scripts moved to [`../04_foursquare_places_create.sql`](../04_foursquare_places_create.sql) and [`../04_foursquare_places_select.sql`](../04_foursquare_places_select.sql). The writeup below is the earlier failure record.

**Source script:** [`../04_foursquare_places_create.sql`](../04_foursquare_places_create.sql) / [`../04_foursquare_places_select.sql`](../04_foursquare_places_select.sql) (moved back to `sql/` after the re-test)

**Reported by:** Michael Hay

---

## Summary

Unlike the earlier PUDL registration failure ([`03_pudl_create.sql`](../03_pudl_create.sql) now succeeds; see the re-test note above), this source's `CREATE LIGHTNING FILESTORE TABLE` statement **succeeds**. The failure shows up one step later:

1. `CREATE LIGHTNING DATABASE FSQ_SOURCE_COOP ...` — succeeds.
2. `CREATE LIGHTNING FILESTORE TABLE foursquare_places FROM FSQ_SOURCE_COOP FORMAT PARQUET OPTIONS (...)` — succeeds.
3. `CACHE TABLE FSQ_SOURCE_COOP.foursquare_places;` — fails with a **500 error**.
4. Every query against the table, including a plain `SELECT * FROM FSQ_SOURCE_COOP.foursquare_places LIMIT 10;` — also fails with a **500 error**.

**Exact Zetaris error text is not yet captured in this writeup** — if you hit this again, paste the literal error message/body here so engineering has it verbatim, not just the causal summary above.

## What this is NOT

- **Not a table-registration problem.** The `CREATE LIGHTNING FILESTORE TABLE` statement itself succeeds. An earlier PUDL run failed at `CREATE` time on a dotted bucket name; that registration succeeded on 2026-10-31 ([`03_pudl_create.sql`](../03_pudl_create.sql)). Whatever's wrong here is downstream of registration.
- **Not (as far as confirmed) a missing-data or access-permission problem at the source.** Source Cooperative's endpoint (`https://data.source.coop`) is publicly reachable and the release path (`s3a://fused/fsq-os-places/2024-11-19/places/`) was confirmed to exist via the listing command in `04_foursquare_places_create.sql`'s header before this table was created — the data itself is not known to be the issue, though this hasn't been independently re-verified against the exact same shards used in the failing query.
- **Not resolved by skipping `CACHE TABLE`.** The plain uncached `SELECT * ... LIMIT 10` fails the same way, so this isn't the "large uncached table is just slow" pattern seen with NOAA GHCN-Daily (`sql/02_noaa_ghcn_create.sql`) — that case returned results, just slowly; this case returns a server error regardless of caching.

## Root-cause hypothesis

Unconfirmed. Two candidates, neither yet distinguished:

1. **The S3-compatible-endpoint path.** Foursquare is the only source in this catalog that goes through a non-AWS `s3Endpoint` (Source Cooperative's `https://data.source.coop`) rather than a direct AWS regional endpoint — every other source (NOAA, PUDL, Overture, Ookla, GBIF, AWS Public Blockchain) either uses `s3a://` against AWS S3 directly or is itself hosted on AWS. If the S3-compatible-endpoint code path has a distinct bug from the plain-AWS-S3 path, this would be the one source in the catalog positioned to expose it.
2. **The directory-prefix `PATH`.** `PATH` points at a directory prefix (`.../places/`) sharded into many Parquet files, rather than a single file — `04_foursquare_places_create.sql`'s own trailing comment already flags this as a possible compatibility concern ("If your Zetaris version requires a single-file PATH instead of a directory prefix, use one shard directly"). This has not been tested: re-running the `CREATE` against a single shard (e.g. `.../places/79.parquet`) and then retrying `CACHE TABLE` / `SELECT` against that narrower table would help isolate whether the multi-file prefix itself is what breaks downstream operations, independent of the endpoint question above.

## Recommended action for this package

Skip `CACHE TABLE` and querying for this source. The other six Parquet/CSV sources already demonstrate the onboarding pattern this package exists to show, and one of them (NOAA) is fully confirmed end to end. If Foursquare's dataset is needed for a demo:

- Retry `CREATE LIGHTNING FILESTORE TABLE` against a single Parquet shard (see hypothesis 2 above) rather than the directory prefix, and see whether `CACHE TABLE`/`SELECT` succeed against that narrower table.
- Revisit this source directly if Zetaris engineering confirms and fixes whatever is failing here, or narrows it to one of the two hypotheses above.

## Suggested engineering debugging steps

1. **Capture the literal 500 response body** from both the failing `CACHE TABLE` and the failing `SELECT * ... LIMIT 10` — a 500 with no body narrows the search far less than one with a stack trace or error code.
2. **Test a single-shard `PATH`** (e.g. `s3a://fused/fsq-os-places/2024-11-19/places/79.parquet`) instead of the directory prefix, to isolate hypothesis 2 (multi-file prefix) from hypothesis 1 (S3-compatible endpoint).
3. **Test a different S3-compatible-endpoint source** (any other public dataset on Source Cooperative, or another MinIO-style endpoint) with a single-file `PATH`, to isolate hypothesis 1 (endpoint code path) from hypothesis 2.
4. **Compare against NOAA's working CSV `CACHE TABLE`** (`sql/02_noaa_ghcn_create.sql`) — that source is native AWS S3, single file, CSV; Foursquare is S3-compatible endpoint, multi-file, Parquet. Narrowing which of those three differences (endpoint, file count, format) triggers the 500 would materially help.
5. **Surface a clearer error** if the root cause is confirmed — a generic 500 is much harder to diagnose from the user side than a specific "unsupported multi-file Parquet prefix over a custom S3 endpoint" (or whatever the actual cause turns out to be) message.

## References

- Scripts: [`04_foursquare_places_create.sql`](../04_foursquare_places_create.sql), [`04_foursquare_places_select.sql`](../04_foursquare_places_select.sql)
- [`03_pudl_create.sql`](../03_pudl_create.sql) — previously a different failure shape (failed at `CREATE` time). Re-tested 2026-10-31: registration and queries succeed.
- `../../parquet-csv-data-sources.md` — source catalog entry updated to reflect this status
