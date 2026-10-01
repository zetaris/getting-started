# Failure case: GBIF species occurrences — table creates and caches, but every SELECT fails with a 500 error

**Status:** Known to fail — kept out of `sql/`'s main sequence. Not required for this package's goals (the other sources already cover the Parquet/CSV onboarding pattern needed); kept here as a flagged item for engineering to debug rather than dropped silently.

**Source script:** [`08_gbif_create.sql`](08_gbif_create.sql) / [`08_gbif_select.sql`](08_gbif_select.sql) (unchanged from their last working state, moved here as-is)

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

- **Not a table-registration problem.** `CREATE LIGHTNING FILESTORE TABLE` succeeds, same as every other source in this catalog except PUDL (`ISSUE-03-pudl.md`).
- **Not (as far as tested) a caching problem.** Caching via the GUI succeeded here — this rules out "the table was never cached" as an explanation, unlike the ambiguity in AWS Public Blockchain Data's asymmetric caching story (`parquet-csv-data-sources.md` #9). GBIF fails even though a cache attempt succeeded, so whatever's wrong is downstream of caching, not caused by its absence.
- **Not explained by dropping the narrow-filter discipline.** Every failing query here already filters by `countrycode` and `class` before anything else, exactly as `08_gbif_create.sql`'s own header comment and this package's general scale guidance recommend. A full, unfiltered `SELECT *` across 1.6B+ rows was never attempted — the failure shows up on the narrowly-scoped query first, the one case that should be cheapest.
- **Not the same failure shape as Foursquare or Overture.** Foursquare fails every query including the plain bounded `SELECT` (`ISSUE-04-foursquare.md`) but was never confirmed to cache either way. Overture's plain bounded `SELECT` *succeeds* and only real aggregation/explode/struct-predicate queries fail (`ISSUE-05-overture.md`). GBIF is a third pattern: caching works, `DESCRIBE` works, but every `SELECT` — even one with a `WHERE` filter and a `LIMIT`, no aggregation at all — fails.

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

- Scripts: [`08_gbif_create.sql`](08_gbif_create.sql), [`08_gbif_select.sql`](08_gbif_select.sql)
- [`ISSUE-03-pudl.md`](ISSUE-03-pudl.md) — fails at `CREATE` time (dotted bucket name), a different failure shape
- [`ISSUE-04-foursquare.md`](ISSUE-04-foursquare.md) — fails at every query including the plain verification SELECT, same symptom as GBIF, but caching was never confirmed either way there
- [`ISSUE-05-overture.md`](ISSUE-05-overture.md) — plain bounded SELECT succeeds, only real queries fail; the opposite split from GBIF, where even the plain filtered SELECT fails
- `../../parquet-csv-data-sources.md` — source catalog entry updated to reflect this status
