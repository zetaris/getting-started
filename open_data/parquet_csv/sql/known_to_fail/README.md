# Known-to-fail sources

Sources that were investigated and scripted for `open_data/parquet_csv/`, but hit a blocking issue that isn't a mistake in the SQL — something in the Zetaris connector, the source's own bucket naming, or the interaction between them. Each source's onboarding script (unchanged from its last working state) sits here alongside an `ISSUE-NN-<name>.md` with the full reproduction steps, evidence, and a root-cause hypothesis for engineering to debug.

These are not part of `sql/`'s main sequence or `HOWTO.md`'s "Running the scripts" order. They're kept here rather than deleted so the investigation isn't lost and engineering has a concrete starting point if the underlying issue is ever fixed.

## Index

PUDL, Foursquare, Overture Maps, GBIF, and Ookla used to be listed here. A later live run (2026-10-31) passed, so their scripts moved to [`../03_pudl_create.sql`](../03_pudl_create.sql), [`../04_foursquare_places_create.sql`](../04_foursquare_places_create.sql), [`../05_overture_maps_create.sql`](../05_overture_maps_create.sql), [`../07_ookla_speedtest_create.sql`](../07_ookla_speedtest_create.sql), and [`../08_gbif_create.sql`](../08_gbif_create.sql). [`ISSUE-03-pudl.md`](ISSUE-03-pudl.md), [`ISSUE-04-foursquare.md`](ISSUE-04-foursquare.md), [`ISSUE-05-overture.md`](ISSUE-05-overture.md), [`ISSUE-07-ookla.md`](ISSUE-07-ookla.md), and [`ISSUE-08-gbif.md`](ISSUE-08-gbif.md) stay here as the records of the earlier failures, superseded by that re-test. GBIF's verified script registers one snapshot file rather than the 282 GiB directory. Ookla's verified script stays on the 2026 quarter=2 files that were listed and queried that day.

No source in this package is currently known to fail. The index below is empty until the next one is.

| Source | Script | Status | Summary |
|---|---|---|---|
| — | — | — | No current known-to-fail source. Earlier records are the ISSUE files linked above. |

## Adding a new known-to-fail source

1. Move the source's script pair here as-is — don't "fix" it as part of the move, since the point is to preserve the last state that hit the issue.
2. Write a new `ISSUE-NN-<name>.md` (matching the script's own numeric prefix and name) covering: a summary, the environment, what was observed in Zetaris, independent verification against the source directly (ruling out what it *isn't*), a root-cause hypothesis explicitly marked as unconfirmed where it is, suggested engineering debugging steps, and a recommended action (skip, retry later, or workaround).
3. Add a row to the index table above.
4. Update `../../HOWTO.md` and `../../parquet-csv-data-sources.md` to reflect the source's new status and location.
