# Failure case: GBIF species occurrences — table creates and caches, but every SELECT fails with a 500 error

**Status:** Superseded on 2026-10-31. Re-tested on a self-hosted Zetaris 2.4.3.1 instance (the hackathon Docker images, Path A of the installation guide). The earlier failure was recorded on a different environment, and why it no longer reproduces is not established. The latest listed snapshot is `occurrence/2026-10-01/` (10,448 Parquet files, 302,977,702,510 bytes / 282.17 GiB). `occurrence/2026-09-01/` is still listed. A filtered `SELECT scientificname, countrycode, decimallatitude, decimallongitude, eventdate FROM GBIF_S3.gbif_occurrences WHERE countrycode = 'AU' AND class = 'Aves' LIMIT 10` against the already-registered 2026-09-01 directory returned 10 rows (`timeUsed` 2809 ms) and did not reproduce the HTTP 500. `input_file_name()` on the same filter returned `.../occurrence.parquet/004990`. Aggregates were not run on the directory. File `occurrence/2026-10-01/occurrence.parquet/004990` (47,796,744 bytes) registered as its own table: `COUNT(*)` was 538,620 rows, of which 17,402 are `countrycode = 'AU' AND class = 'Aves'` (589 distinct `scientificname`). `DESCRIBE` returned 50 columns. Every query in the updated select script succeeded on that file in about 1.0–1.6 seconds. Citation text for the snapshot: `GBIF.org (1 October 2026) GBIF Occurrence Download https://doi.org/10.15468/dl.tup2g6`. The scripts moved to [`../08_gbif_create.sql`](../08_gbif_create.sql) and [`../08_gbif_select.sql`](../08_gbif_select.sql). The writeup below is the earlier failure record.

**Source script:** [`../08_gbif_create.sql`](../08_gbif_create.sql) / [`../08_gbif_select.sql`](../08_gbif_select.sql) (moved back to `sql/` after the re-test)

**Reported by:** Michael Hay

---

## Summary

Unlike every other known-to-fail source in this package, GBIF's table **creates successfully and caches successfully** — the failure is isolated specifically to querying it, and it's total: even the single, narrowly-filtered verification query that this package otherwise treats as the baseline "does this source actually work" check fails the same way everything else does. Full per-step results from a live run:

| Step | Result |
|---|---|
| `CREATE LIGHTNING DATABASE GBIF_S3 ...` | Succeeded |
| `CREATE LIGHTNING FILESTORE TABLE gbif_occurrences ...` | Succeeded |
| Caching via the Data Explorer GUI's own cache action | Succeeded |
| Verification: `SELECT scientificname, countrycode, ... WHERE countrycode = 'AU' AND class = 'Aves' LIMIT 10;` | **Failed — 500 error** |
| Query 1: `DESCRIBE GBIF_S3.gbif_occurrences;` | Succeeded |
| Query 2: overview (`COUNT(*)`, `COUNT(DISTINCT scientificname)`, filtered) | **Failed — 500 error** |
| Query 3: top species (`GROUP BY scientificname`, filtered) | **Failed — 500 error** |
| Query 4: occurrences by year (`GROUP BY year`, filtered) | **Failed — 500 error** |
| Query 5: seasonality by month | Skipped — not run, given queries 2-4's results |
| Query 6: basis-of-record breakdown (`GROUP BY basisofrecord`, filtered) | **Failed — 500 error** |
| Query 7: coordinate completeness | Skipped — not run, given queries 2-4 and 6's results |
| Query 8: top institutions | Skipped — not run, given queries 2-4 and 6's results |

**Exact Zetaris error text is not yet captured in this writeup** — if you hit this again, paste the literal error message/body here so engineering has it verbatim, not just the pass/fail summary above.

## What this is NOT

- **Not a table-registration problem.** `CREATE LIGHTNING FILESTORE TABLE` succeeds. PUDL's earlier registration failure was re-tested on 2026-10-31 and now succeeds ([`03_pudl_create.sql`](../03_pudl_create.sql)).
- **Not (as far as tested) a caching problem.** Caching via the GUI succeeded here — this rules out "the table was never cached" as an explanation, unlike the ambiguity in AWS Public Blockchain Data's asymmetric caching story (`parquet-csv-data-sources.md` #9). GBIF fails even though a cache attempt succeeded, so whatever's wrong is downstream of caching, not caused by its absence.
- **Not explained by dropping the narrow-filter discipline.** Every failing query here already filters by `countrycode` and `class` before anything else, exactly as `08_gbif_create.sql`'s own header comment and this package's general scale guidance recommend. A full, unfiltered `SELECT *` across 1.6B+ rows was never attempted — the failure shows up on the narrowly-scoped query first, the one case that should be cheapest.
- **Not the same failure shape as the earlier Foursquare or Overture runs.** Those earlier runs failed queries after registration. On 2026-10-31 both succeeded ([`04_foursquare_places_select.sql`](../04_foursquare_places_select.sql), [`05_overture_maps_select.sql`](../05_overture_maps_select.sql)). The GBIF failure recorded below was its own pattern: caching worked, `DESCRIBE` worked, but every `SELECT` — even one with a `WHERE` filter and a `LIMIT`, no aggregation at all — failed. That SELECT failure did not reproduce on 2026-10-31; see the status line at the top of this file.

## Root-cause hypothesis

Unconfirmed, and arguably the least narrowed of the four known-to-fail sources, since the usual distinguishing factors (structs/arrays, directory-prefix `PATH`, dotted bucket name) don't obviously set GBIF apart from working sources the way they did for Foursquare/Overture/PUDL. Candidates:

1. **Partition/file-count scale specifically, distinct from working-set scale.** `gbif_occurrences` is read from a directory prefix (`s3a://gbif-open-data-us-east-1/occurrence/2026-09-01/occurrence.parquet/`) covering the entire 1.6B+ row global snapshot, likely split across many more underlying Parquet files than any other source in this catalog (NOAA is one file per year; Overture and Foursquare are large but smaller datasets). If Zetaris's query planner needs to enumerate or plan against every file in the prefix before a predicate pushdown can narrow the scan — rather than pruning at the directory level the way Hive-style partitioning would — even a filtered query could still hit whatever resource or timeout limit produces a 500, despite the `WHERE` clause being present in the SQL text.
2. **A schema-inference quirk specific to this snapshot.** `DESCRIBE` succeeding shows Zetaris can read *some* metadata about the table without failure, but `DESCRIBE` in Spark/Zetaris typically reads only the schema (from Parquet footers or a cached catalog entry), not actual row data — so this doesn't rule out a problem that only surfaces once a real scan begins. GBIF's occurrence schema is unusually wide (Darwin Core occurrence records commonly carry 50+ columns including some long free-text fields) compared to the other sources here; a wide-schema interaction with filtering/predicate-pushdown is untested.
3. **The GUI-created cache interacting badly with a SQL-issued query**, similar in spirit to the AWS Public Blockchain Data cross-mechanism asymmetry (`parquet-csv-data-sources.md` #9), but here producing a worse outcome (every query fails) rather than a milder one (some queries just run uncached). Not tested: whether querying `gbif_occurrences` fails identically without ever invoking the GUI's cache action first.

## Recommended action for this package

Skip querying this source entirely — not just analytical queries, but the plain filtered verification SELECT too. The other sources in this catalog already demonstrate the onboarding pattern this package exists to show, and two of them (NOAA, AWS Public Blockchain Data) are confirmed working end to end. If GBIF's dataset is needed for a demo:

- Try a single-file `PATH` instead of the whole `occurrence.parquet/` directory prefix (see hypothesis 1), to test whether file-count/partition scale specifically is the trigger, independent of total row count.
- Try querying without ever caching the table first (see hypothesis 3), to rule the GUI cache interaction in or out.
- Revisit this source directly if Zetaris engineering narrows which of the hypotheses above (or another cause entirely) is the actual trigger.

## Suggested engineering debugging steps

1. **Capture the literal 500 response body** from the plain filtered verification SELECT — the simplest failing query here, with no aggregation, no `GROUP BY`, and no nested-column access, which makes it the best isolated repro case across all four known-to-fail sources in this package.
2. **Test a single-file `PATH`** (one Parquet file inside the `occurrence.parquet/` prefix, found via a bucket listing) instead of the full directory, re-running the same filtered verification SELECT against that narrower table, to isolate file-count/partition scale (hypothesis 1) from total snapshot size.
3. **Test the same filtered SELECT without first caching the table via the GUI**, to rule hypothesis 3 (a GUI-cache/SQL-query interaction) in or out independently of hypothesis 1.
4. **Compare against NOAA's confirmed-working large single-file CSV case** (`sql/02_noaa_ghcn_create.sql`) and AWS Public Blockchain Data's confirmed-working date-partitioned Parquet case (`sql/09_aws_public_blockchain_create.sql`) — both are large, both require `CACHE TABLE` or benefit from it, and both work. Narrowing what's different about GBIF's specific partition layout or file count relative to those two would materially help.
5. **Surface a clearer error** if the root cause is confirmed — a generic 500 on a simple, filtered, bounded query is much harder to diagnose from the user side than a specific message (e.g. a partition-enumeration timeout, or a planner resource limit).

## References

- Scripts: [`08_gbif_create.sql`](../08_gbif_create.sql), [`08_gbif_select.sql`](../08_gbif_select.sql)
- [`03_pudl_create.sql`](../03_pudl_create.sql) — previously failed at `CREATE` time (dotted bucket name). Re-tested 2026-10-31: registration and queries succeed.
- [`ISSUE-04-foursquare.md`](ISSUE-04-foursquare.md) — earlier query-time failure, same symptom as GBIF. Re-tested 2026-10-31: bounded queries succeed ([`04_foursquare_places_select.sql`](../04_foursquare_places_select.sql)). Caching was never confirmed either way there.
- [`05_overture_maps_select.sql`](../05_overture_maps_select.sql) — re-tested 2026-10-31: bounded analytical queries succeed. GBIF's filtered SELECT also succeeded that day; see the status line above.
- `../../parquet-csv-data-sources.md` — source catalog entry updated to reflect this status
