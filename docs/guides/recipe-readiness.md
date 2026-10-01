# Recipe readiness

Use the [small starter](first-dataset.md) first. This index distinguishes recorded evidence from a freshly verified instance. A script's existence, a licensing color, or a successful CREATE does not prove its current data path works.

## Recommended starting subset

| Source | Run first | Recorded evidence | Leave for later |
|---|---|---|---|
| PokéAPI REST | Database/container, Pikachu raw table and abilities view, then its verification | [Installation test record](../install/zetaris-installation-test-record.md), 24 September 2026 | Types, stats, Charizard, and union views |

Use assigned team names on the shared event instance. Source availability still needs checking from the Zetaris server during your run.

## Active source catalogs

- [REST catalog](../../open_data/rest_apis/rest-api-sources.md) is the per-source readiness record: 11 pairs, with nine marked Verified, NASA DONKI Unverified, and Singapore PM2.5 Known to fail. “Verified” describes a recorded run, not a guarantee on your instance. Dates and caveats, where recorded, are in the script headers and source notes; a missing date must not be invented.
- [Parquet/CSV catalog](../../open_data/parquet_csv/parquet-csv-data-sources.md) lists seven current pairs. It explicitly states that license colors do not indicate runtime verification. Only NOAA and AWS Public Blockchain are active file pairs; five pairs are under `known_to_fail`, including PUDL. The earlier PUDL success and current registration failure are unresolved; follow the current catalog rather than treating the old run as current readiness.
- [USL package](../../open_data/usl/HOWTO.md) records verified SIC and SIC/EDGAR lifecycle steps, an observed FK DQ failure, and still-open comparison/materialization questions; consult the current model catalog. The [EDGAR/PUDL/NOAA guide](create-edgar-pudl-noaa-usl.md) records its own joined-result evidence and separate DQ limitation.

Do not run the entire catalog as onboarding. Select one source, inspect its prerequisites, rate limits, schema, data volume, attribution notes, and statement dependencies, then verify the actual subset you created.

## Excluded from the default journey

| Material | Why it is excluded |
|---|---|
| PUDL, Foursquare, Overture, Ookla, and GBIF file recipes | Current known-to-fail registrations or queries; see the per-source issue records |
| Singapore PM2.5 | Known-to-fail source; retained as a documented issue, not a starter fallback |
| NASA DONKI | Unverified shape/connector behavior |
| Local Singapore housing and Open Food Facts bulk fetchers | They download files but have no SQL onboarding pair. The file must be placed on storage reachable by Zetaris; bulk delimiter support also needs confirmation. |
| Large optional tables, whole-dataset counts, and broad scans | Opt in after inspecting size and query scope; not needed to verify the starter |
| Kafka | Deferred pending ingestion confirmation |
| SQL RDBMS recipes, logs, PDFs, and other planned categories | Not shipped as ready onboarding paths |

The [roadmap](../plans/FUTURES.md) is for future work. It is not a menu of capabilities already available to participants.

## When a source fails

Use [troubleshooting](troubleshooting.md). If the minimal PokéAPI path fails, stop and resolve source connectivity/configuration or select a different verified REST source with its prerequisites understood. Do not hide a failure by substituting synthetic rows. PUDL is not a fallback.
