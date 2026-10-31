# Failure case: Ookla Speedtest Global Performance — both tables fail `CREATE LIGHTNING FILESTORE TABLE` with a 500 error

**Status:** Superseded on 2026-10-31. Re-tested on a self-hosted Zetaris 2.4.3.1 instance (the hackathon Docker images, Path A of the installation guide). The earlier failure was recorded on a different environment, and why it no longer reproduces is not established. A public listing of `parquet/performance/type=fixed/year=2026/quarter=2/` and `type=mobile/year=2026/quarter=2/` still contained the script's files: `2026-04-01_performance_fixed_tiles.parquet` (353,986,294 bytes) and `2026-04-01_performance_mobile_tiles.parquet` (184,560,046 bytes). `year=2026` also listed `quarter=1` and `quarter=3` (`2026-07-01`). `OOKLA_S3`, `ookla_speedtest_fixed`, and `ookla_speedtest_mobile` were already registered on those exact quarter=2 paths. Re-running the three CREATE statements returned HTTP 400 `already exists`, not HTTP 500. A new table, `ookla_speedtest_fixed_probe`, with the same OPTIONS as `ookla_speedtest_fixed` registered (`timeUsed` 1523 ms) and `SELECT quadkey, tile_x, tile_y, avg_d_kbps, tests ... LIMIT 1` returned one row; that probe table was then dropped. `DESCRIBE` returned 11 columns on both kept tables. `SELECT * ... LIMIT 10` returned 10 rows on each (about 3.9–4.0 s). A Manhattan window (`tile_x` -74.02 to -73.93, `tile_y` 40.70 to 40.82) held 406 fixed tiles (77,758 tests; tests-weighted average download 385,150 kbps) and 385 mobile tiles (15,686 tests; tests-weighted average download 315,488 kbps). The fixed download-band and top-10 queries in the updated select script also succeeded. The scripts moved to [`../07_ookla_speedtest_create.sql`](../07_ookla_speedtest_create.sql) and [`../07_ookla_speedtest_select.sql`](../07_ookla_speedtest_select.sql). The writeup below is the earlier failure record.

**Source script:** [`../07_ookla_speedtest_create.sql`](../07_ookla_speedtest_create.sql) / [`../07_ookla_speedtest_select.sql`](../07_ookla_speedtest_select.sql) (moved back to `sql/` after the re-test)

**Reported by:** Michael Hay

---

## Summary

Both `CREATE LIGHTNING FILESTORE TABLE` statements in `07_ookla_speedtest_create.sql` fail with a 500 error — `ookla_speedtest_fixed` and `ookla_speedtest_mobile` alike. This fails at table-registration time, before any query is even possible, which puts Ookla in the same broad category as the earlier PUDL registration failure ([`03_pudl_create.sql`](../03_pudl_create.sql) now succeeds; see the status line at the top of this file) rather than the earlier GBIF failure (which registered and failed later, at query time). Foursquare, Overture, and GBIF were re-tested successfully on 2026-10-31. GBIF's verified script registers one snapshot file ([`08_gbif_create.sql`](../08_gbif_create.sql)). Reproduced against the exact `PATH` values as written in the script:

```
PATH "s3a://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/2026-04-01_performance_fixed_tiles.parquet"
PATH "s3a://ookla-open-data/parquet/performance/type=mobile/year=2026/quarter=2/2026-04-01_performance_mobile_tiles.parquet"
```

**Exact Zetaris error text is not yet captured in this writeup** — if you hit this again, paste the literal error message/body here so engineering has it verbatim, not just the causal summary below.

## What this is NOT

- **Not a dotted bucket name.** Ookla's bucket, `ookla-open-data`, contains no dots. The earlier PUDL writeup treated a dotted bucket as its cause; that registration succeeded on 2026-10-31 ([`03_pudl_create.sql`](../03_pudl_create.sql)). Ookla still fails at `CREATE` time by a different mechanism.
- **Not (as far as confirmed) a missing-data or access-permission problem.** Ookla's data is published as a standard public, anonymous-access S3 bucket via the AWS Open Data Registry, the same pattern NOAA (confirmed working) and AWS Public Blockchain Data (confirmed working) both use successfully. Direct `aws s3 ls`/`aws s3 cp` access to this bucket has not been independently re-verified as part of this investigation, but nothing about the bucket's public-access configuration is known to differ from the working sources.
- **Not confirmed to be a single-file `PATH` problem.** Unlike Foursquare/Overture/GBIF, Ookla's `PATH` already points at a single Parquet file, not a directory prefix — so this can't be explained by the same "multi-file directory PATH" pattern flagged as an open hypothesis for those three sources.

## Root-cause hypothesis

Unconfirmed, and the least evidence-backed of the known-to-fail sources in this package, since the usual distinguishing factors found in the others (dotted bucket name, directory-prefix `PATH`, nested struct/array columns) don't apply here at all. Candidates:

1. **The quarter-dated filename pattern itself being stale or wrong.** `07_ookla_speedtest_create.sql`'s own trailing comment already flags that the filename date reflects the *first day of the quarter*, not the publish date, and that the current quarter's exact filename should be confirmed with a bucket listing before running the script. If `2026-04-01_performance_fixed_tiles.parquet` no longer exists at that exact path (a newer quarter has since been published, or the naming pattern itself changed), a 500 rather than a clearer "file not found" error would be a connector-side limitation worth flagging on its own, independent of whatever broader issue (if any) exists.
2. **A GeoParquet-specific or large-single-file characteristic of Ookla's export** that AWS Public Blockchain Data's and NOAA's working single/few-file sources don't share. Ookla's tiles are a large (country/region-wide) single-file Parquet export per quarter per type; whether its internal schema, row-group structure, or file size specifically trips something in Zetaris's connector is untested.
3. **Transient infrastructure issue, not a structural incompatibility at all.** A 500 at `CREATE` time, with no dotted-bucket-name or nested-schema explanation available, is also consistent with a one-off server-side error unrelated to Ookla specifically. This hasn't been ruled out by a retry on a different day/session.

## Recommended action for this package

Skip this source. The other sources in this catalog already demonstrate the onboarding pattern this package exists to show, and two of them (NOAA, AWS Public Blockchain Data) are confirmed working end to end. If Ookla's dataset is needed for a demo:

- First re-run the bucket-listing command in the script's header comment to confirm the exact current filename exists at the expected path (ruling out hypothesis 1) before assuming anything structural is wrong.
- Retry the identical `CREATE` statement in a separate session, to rule out hypothesis 3 (a transient failure).
- Revisit this source directly if Zetaris engineering confirms and fixes whatever is failing here, or narrows it to one of the hypotheses above.

## Suggested engineering debugging steps

1. **Capture the literal 500 response body** from the `CREATE LIGHTNING FILESTORE TABLE` statement — a 500 with no body narrows the search far less than one with a stack trace or error code.
2. **Confirm the exact file exists at the stated `PATH`** via `aws s3 ls --no-sign-request s3://ookla-open-data/parquet/performance/type=fixed/year=2026/quarter=2/` before assuming a connector problem — rule out hypothesis 1 first, since it's the cheapest to check.
3. **Retry the identical statement in a fresh session**, to rule out hypothesis 3 (transient infrastructure issue) before investing further debugging time.
4. **Compare against NOAA's and AWS Public Blockchain Data's working single/few-file S3 registrations** — both are plain AWS S3, public, anonymous-access Parquet/CSV, same general shape as Ookla's `PATH`. Narrowing what's actually different about Ookla's export (file size, internal Parquet structure, something else) would materially help, since none of the usual suspects from other known-to-fail sources apply here.
5. **Surface a clearer error** if the root cause is confirmed — a generic 500 is much harder to diagnose from the user side than a specific message (e.g. "file not found at PATH" vs. an actual connector/parsing failure).

## References

- Scripts: [`07_ookla_speedtest_create.sql`](../07_ookla_speedtest_create.sql), [`07_ookla_speedtest_select.sql`](../07_ookla_speedtest_select.sql)
- [`03_pudl_create.sql`](../03_pudl_create.sql) — previously also failed at `CREATE` time. Re-tested 2026-10-31: registration and queries succeed. Ookla's bucket name has no dots.
- [`ISSUE-04-foursquare.md`](ISSUE-04-foursquare.md), [`04_foursquare_places_create.sql`](../04_foursquare_places_create.sql), [`05_overture_maps_create.sql`](../05_overture_maps_create.sql), [`ISSUE-08-gbif.md`](ISSUE-08-gbif.md), [`08_gbif_create.sql`](../08_gbif_create.sql) — Foursquare, Overture, and GBIF succeeded on 2026-10-31. GBIF's example queries ran against one file of snapshot 2026-10-01.
- `../../parquet-csv-data-sources.md` — source catalog entry updated to reflect this status
