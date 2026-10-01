# Known-to-fail sources

Sources that were investigated and scripted for `open_data/parquet_csv/`, but hit a blocking issue that isn't a mistake in the SQL — something in the Zetaris connector, the source's own bucket naming, or the interaction between them. Each source's onboarding script (unchanged from its last working state) sits here alongside an `ISSUE-NN-<name>.md` with the full reproduction steps, evidence, and a root-cause hypothesis for engineering to debug.

These are not part of `sql/`'s main sequence or `HOWTO.md`'s "Running the scripts" order. They're kept here rather than deleted so the investigation isn't lost and engineering has a concrete starting point if the underlying issue is ever fixed.

## Index

| Source | Script | Status | Summary |
|---|---|---|---|
| Catalyst Cooperative PUDL | [`03_pudl_create.sql`](03_pudl_create.sql) | Known to fail | `CREATE LIGHTNING FILESTORE TABLE` against `s3a://pudl.catalyst.coop/...` fails — PUDL's bucket name (`pudl.catalyst.coop`) contains dots, and Zetaris's S3 filestore connector does not accept a dotted bucket name in the `PATH`. The files themselves are downloadable directly from S3 (confirmed via `aws s3 cp`/`curl`) — this is specifically about registering the bucket as a Zetaris `FILESTORE TABLE`, not about the data being unavailable. See [`ISSUE-03-pudl.md`](ISSUE-03-pudl.md). |
| Foursquare Open Source Places | [`04_foursquare_places_create.sql`](04_foursquare_places_create.sql) | Known to fail | `CREATE LIGHTNING FILESTORE TABLE` succeeds against Source Cooperative's S3-compatible endpoint, but `CACHE TABLE` and every query against the resulting table — including a plain `SELECT * ... LIMIT 10` — fail with a 500 error. Unlike PUDL, this fails at query time, not at table-registration time. See [`ISSUE-04-foursquare.md`](ISSUE-04-foursquare.md). |
| Overture Maps Places theme | [`05_overture_maps_create.sql`](05_overture_maps_create.sql) | Known to fail | `CREATE LIGHTNING FILESTORE TABLE` succeeds and a plain `SELECT * ... LIMIT` works (confirmed at both `LIMIT 10` and `LIMIT 1000`), but `CACHE TABLE` and every analytical query (aggregation, `explode`, a struct-field predicate) fail with a 500 error, or in one case run past 2m40s with no result. Unlike Foursquare, the bounded unaggregated SELECT does work here — only queries that do real work fail. See [`ISSUE-05-overture.md`](ISSUE-05-overture.md). |
| GBIF species occurrences | [`08_gbif_create.sql`](08_gbif_create.sql) | Known to fail | `CREATE LIGHTNING FILESTORE TABLE` succeeds and caching via the Data Explorer GUI succeeds, but every `SELECT` against the resulting table fails with a 500 error — including the plain, narrowly-filtered verification query, which is the simplest query in this package's entire SELECT-script pattern. `DESCRIBE` still works. Unlike the other three known-to-fail sources, scale/nesting/bucket-naming don't obviously explain this one. See [`ISSUE-08-gbif.md`](ISSUE-08-gbif.md). |
| Ookla Speedtest Global Performance | [`07_ookla_speedtest_create.sql`](07_ookla_speedtest_create.sql) | Known to fail | Both `CREATE LIGHTNING FILESTORE TABLE` statements (`ookla_speedtest_fixed` and `ookla_speedtest_mobile`) fail with a 500 error — this fails at table-registration time, like PUDL, but Ookla's bucket name has no dots, so PUDL's specific root cause doesn't apply here. See [`ISSUE-07-ookla.md`](ISSUE-07-ookla.md). |

## Adding a new known-to-fail source

1. Move the source's script pair here as-is — don't "fix" it as part of the move, since the point is to preserve the last state that hit the issue.
2. Write a new `ISSUE-NN-<name>.md` (matching the script's own numeric prefix and name) covering: a summary, the environment, what was observed in Zetaris, independent verification against the source directly (ruling out what it *isn't*), a root-cause hypothesis explicitly marked as unconfirmed where it is, suggested engineering debugging steps, and a recommended action (skip, retry later, or workaround).
3. Add a row to the index table above.
4. Update `../../HOWTO.md` and `../../parquet-csv-data-sources.md` to reflect the source's new status and location.
