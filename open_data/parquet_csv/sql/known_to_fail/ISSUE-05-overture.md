# Failure case: Overture Maps Places theme — table creates and plain SELECT works, but `CACHE TABLE` and every real query fail with a 500 error

**Status:** Known to fail — kept out of `sql/`'s main sequence. Not required for this package's goals (the other sources already cover the Parquet/CSV onboarding pattern needed); kept here as a flagged item for engineering to debug rather than dropped silently.

**Source script:** [`05_overture_maps_create.sql`](05_overture_maps_create.sql) / [`05_overture_maps_select.sql`](05_overture_maps_select.sql) (unchanged from their last working state, moved here as-is)

**Reported by:** Michael Hay

---

## Summary

Like Foursquare (`ISSUE-04-foursquare.md`), `CREATE LIGHTNING FILESTORE TABLE` **succeeds** for this source. Unlike Foursquare, a plain unaggregated `SELECT * ... LIMIT` also succeeds — the failure shows up specifically once a query does real work (aggregation, `explode`, a `CASE` expression, or a `WHERE` predicate on a struct field), or once `CACHE TABLE` is attempted. Full per-step results from a live run:

| Step | Result |
|---|---|
| `CREATE LIGHTNING DATABASE OVERTURE_S3 ...` | Succeeded |
| `CREATE LIGHTNING FILESTORE TABLE overture_places ...` | Succeeded |
| `CACHE TABLE OVERTURE_S3.overture_places;` | **Failed — 500 error** |
| Verification: `SELECT * FROM OVERTURE_S3.overture_places LIMIT 10;` | Succeeded |
| Verification: same query with `LIMIT 1000` | Succeeded |
| Query 1: `DESCRIBE OVERTURE_S3.overture_places;` | Succeeded |
| Query 2: overview (`COUNT(*)`, `COUNT(DISTINCT categories.primary)`) | **Failed — 500 error** |
| Query 3: top categories (`GROUP BY categories.primary`) | **Failed — 500 error** |
| Query 4: top countries (`LATERAL VIEW explode(addresses)` + `GROUP BY`) | **Failed — 500 error** |
| Query 5: confidence distribution (`CASE` + `GROUP BY`) | **Did not complete** — stopped after 2m40s with no result; assumed to also fail with a 500 error if left to run further, consistent with queries 2-4 and 8 |
| Query 6: website completeness (`size(websites)`) | Skipped — not run, given queries 2-5's results |
| Query 7: top brands (`WHERE brand IS NOT NULL` + `GROUP BY brand.names.primary`) | Skipped — not run, given queries 2-5's results |
| Query 8: named lookup (`WHERE names.primary = '...'`) | **Failed — 500 error** |

**Exact Zetaris error text is not yet captured in this writeup** — if you hit this again, paste the literal error message/body here so engineering has it verbatim, not just the pass/fail summary above.

## What this is NOT

- **Not a table-registration problem.** `CREATE LIGHTNING FILESTORE TABLE` succeeds, same as Foursquare and unlike PUDL (which fails at `CREATE` time — `ISSUE-03-pudl.md`).
- **Not a blanket "every query fails" problem, unlike Foursquare.** Foursquare's plain `SELECT * ... LIMIT 10` also fails (`ISSUE-04-foursquare.md`); Overture's does not, at either `LIMIT 10` or `LIMIT 1000`. Whatever's wrong here is specific to queries that do more than a bounded row scan.
- **Not (as far as tested) a `LIMIT`-size problem.** The verification query succeeded identically at `LIMIT 10` and `LIMIT 1000`, so this isn't simply "large result sets fail" — the failing queries (2-5, 8) are all either aggregations, an `explode`, or a predicate on a struct field, not larger unfiltered scans.
- **Not confirmed to be the struct/array nesting specifically.** Query 8's `WHERE names.primary = '...'` touches a single struct field with no aggregation at all, and it still failed — so this isn't only a `GROUP BY`/aggregation problem either. Nested-column access (`categories.primary`, `names.primary`, `addresses[].country`, `brand.names.primary`) is common to every failing query except possibly the never-run ones, which is suggestive but not proven given query 2 also aggregates plain non-nested data (`COUNT(*)`).

## Root-cause hypothesis

Unconfirmed, and less narrowed than PUDL's or Foursquare's. Candidates, in rough order of how well they fit the evidence:

1. **Struct/array (nested Parquet) column access under any non-trivial query.** Every failing query (2, 3, 4, 8) touches a struct field (`categories.primary`, `names.primary`) or an array (`addresses`, `websites` in the untested query 6), and `05_overture_maps_create.sql`'s own trailing comment already flagged nested columns as a possible flattening concern before this was tested. Query 2's `COUNT(*)` succeeding or failing alongside `COUNT(DISTINCT categories.primary)` in the same statement isn't separately testable from the result captured here — a narrower repro (plain `COUNT(*)` alone, no nested-field reference) would help confirm or rule this out.
2. **`CACHE TABLE` itself being broken for this table**, independent of the query shape — it failed before any analytical query was attempted, and if the underlying cache operation touches the whole nested schema (unlike a row-bounded `SELECT * ... LIMIT`), that alone could explain every subsequent query failing too, if they're implicitly relying on a cache that never materialized. This doesn't fully explain query 8, though, which doesn't require caching to run as a correctness matter.
3. **Scale.** This bucket's `place` partition is Overture's largest Places type; a bounded `LIMIT` scan avoids scanning the whole dataset, while every failing query (aggregation, explode, or an unindexed struct-field predicate) needs a fuller scan. Query 5's 2m40s hang before presumed failure is the one piece of evidence pointing this direction instead of a pure parsing/schema issue, which would be expected to fail fast rather than hang.

These three are not mutually exclusive — nested-column handling plus full-table scan cost could compound.

## Recommended action for this package

Skip `CACHE TABLE` and analytical queries for this source; the plain, bounded `SELECT * ... LIMIT N` is the only confirmed-working operation. The other sources in this catalog already demonstrate the onboarding pattern this package exists to show, and NOAA is confirmed working end to end. If Overture's dataset is needed for a demo:

- Try a narrower `PATH` (a single partition file instead of the whole `type=place/` prefix) to rule out scale as the dominant factor.
- Try a `SELECT` that references only top-level, non-nested columns (e.g. `id`, `confidence` without the `CASE`) with no `GROUP BY`, to isolate nested-column access from aggregation/scan cost.
- Revisit this source directly if Zetaris engineering narrows which of the hypotheses above is the actual cause.

## Suggested engineering debugging steps

1. **Capture the literal 500 response body** from `CACHE TABLE` and from query 2, the simplest failing query, to get an actual error code or stack trace rather than inferring from pass/fail alone.
2. **Isolate nested-column access from aggregation.** Run `SELECT COUNT(*) FROM OVERTURE_S3.overture_places;` alone (no nested-field reference, no `GROUP BY`) and separately `SELECT categories.primary FROM OVERTURE_S3.overture_places LIMIT 10;` (nested-field reference, no aggregation, bounded) to see which one fails.
3. **Isolate `CACHE TABLE` from everything else.** Confirm whether querying still fails identically without ever attempting `CACHE TABLE` first, to rule out a corrupted or partial cache state as the cause of the later query failures.
4. **Let query 5 run to completion** (no timeout) against a smaller `PATH` (a single file, not the whole prefix) to distinguish "would eventually succeed, just slow" from "would eventually also 500."
5. **Compare against Foursquare's failure** (`ISSUE-04-foursquare.md`) — Foursquare fails even its plain `SELECT * ... LIMIT 10`, Overture does not; both are nested-Parquet, S3-backed sources with directory-prefix `PATH`s. Understanding why Overture's bounded scan succeeds where Foursquare's doesn't would help confirm or rule out "directory-prefix/multi-file PATH" as a shared root cause across both known-to-fail sources.
6. **Surface a clearer error** if the root cause is confirmed — a generic 500 is much harder to diagnose from the user side than a specific message (e.g. "aggregation over nested Parquet columns is unsupported," or a scan-timeout message distinct from a hard failure).

## References

- Scripts: [`05_overture_maps_create.sql`](05_overture_maps_create.sql), [`05_overture_maps_select.sql`](05_overture_maps_select.sql)
- [`ISSUE-03-pudl.md`](ISSUE-03-pudl.md) — fails at `CREATE` time (dotted bucket name), a different failure shape
- [`ISSUE-04-foursquare.md`](ISSUE-04-foursquare.md) — fails at every query including the plain verification SELECT, unlike this source
- `../../parquet-csv-data-sources.md` — source catalog entry updated to reflect this status
