# Systems

Where Zetaris is run on, or against, a specific class of system, with the
documents, scripts and tests for it. Each system has its own folder. Nothing here
names a vendor: store and partner names are supplied when a package is built.

| Folder | What it covers |
|---|---|
| [`object_stores/`](object_stores/README.md) | Materializing a USL to an S3-compatible object store, and proving the result from the source API to the Parquet file. Includes a step-by-step test, the scripts, and a packager for handing the test to a partner. |

Shared helpers stay where they are: `scripts/` (SQL runner, onboarding, preflight)
and `open_data/` (the sources and the USL the tests use).
