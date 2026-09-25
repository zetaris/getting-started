# Handoff to Claude Code

> **Archived — superseded.** This was the original one-time Cowork → Claude Code session handoff. Its content is now fully superseded by [`README.md`](../../../README.md) and [`docs/plans/FUTURES.md`](../FUTURES.md), which reflect what was actually built. `quickstart-data-manifest.md` (referenced below) has since been dispersed into `docs/plans/recipes/*.md` and `FUTURES.md`, and is itself archived alongside this doc at [`quickstart-data-manifest.md`](quickstart-data-manifest.md) rather than kept at the repo root. Kept here as a historical record.

This package is the starting content for a public GitHub repo — working name `zetaris-quickstart-data` — that helps people trying out a small Zetaris deployment get real, permissively-licensed data queryable in minutes. It was assembled in Cowork (research, license verification, and drafting); this handoff is for picking the work up in Claude Code to turn it into an actual repo.

## What's in this package

- **`quickstart-data-manifest.md`** — the main source guide: Kafka, logs, JSON/REST APIs, queryable SQL RDBMS, PDFs, and government open-data sections for Singapore, the US (NASA, data.gov), the EU/UK, Canada, Australia, Mexico, and Africa. Fourteen numbered sections; §2 (Parquet) is intentionally a short pointer into the files below rather than duplicating them.
- **`parquet-csv-data-sources.md`** — the Parquet/CSV source catalog: nine data sources, each with license, exact data URL/path, and docs links.
- **`sql/*.sql`** — nine `CREATE LIGHTNING FILESTORE TABLE` scripts, one per Parquet/CSV source, built from the syntax documented at `kbase.zetaris.com` and `data-fabric.readthedocs.io`.
- **`HOWTO.md`** — the Zetaris onboarding walkthrough for those nine scripts: syntax reference, run order, and two open items (see below).

Both markdown files use the same convention throughout: 🟢 open, use it freely · 🟡 open with a condition worth reading · 🔴 not included, with the reason stated. Keep that convention if you add sources later — it's what a reader scans for first.

## The target shape

`quickstart-data-manifest.md` §13 ("Suggested repo layout") has the full directory tree this content is meant to become — one top-level folder per category (`kafka/`, `parquet/`, `logs/`, `json/`, `sql/`, `pdf/`, `singapore/`, `nasa/`, `datagov/`, `eu/`, `uk/`, `canada/`, `australia/`, `mexico/`, `africa/`), each with working code (docker-compose files, connector scripts, DDL) and a short README, plus a top-level `README.md` and `LICENSE-NOTES.md`. The `parquet/` folder in that tree is exactly the contents of this package — drop `parquet-csv-data-sources.md`, `sql/`, and `HOWTO.md` straight in, or keep this package as a sibling top-level folder; either works.

Right now only the Parquet/CSV corner (`sql/*.sql`, tested against documented syntax but not against a live Zetaris instance) has runnable code. Everything else in the manifest is researched and cited but not yet turned into scripts, docker-compose files, or connector code — that's the bulk of the scaffolding work.

## Suggested first steps

1. Scaffold the directory tree from §13 of `quickstart-data-manifest.md`.
2. Move this package's contents into `parquet/` per the note above.
3. Work through the other categories in the manifest, turning each source's "Try it" / "Good for" guidance into an actual runnable artifact (a `docker-compose.yml`, a connector script, a DDL file) — the manifest has enough detail per source (URLs, signup requirements, format) to build directly from.
4. Write the top-level `README.md` (what the repo is, a license table summarizing every source) and `LICENSE-NOTES.md` (the full per-source license list, pulled from both markdown files).

## Things that need a real Zetaris instance to close out

These can't be resolved by reading docs alone — they need an actual `CREATE LIGHTNING FILESTORE TABLE` run against a live Zetaris deployment:

- **Credential-less access to public S3 buckets.** All nine Parquet/CSV sources are public/anonymous buckets, but every documented Zetaris filestore example includes `AWSACCESSKEYID`/`AWSSECRETACCESSKEY` with no documented anonymous option. `HOWTO.md` section 2 lists three things to try (omit the keys, pass empty/`"anonymous"` values, fall back to a real IAM key). Once you know which works, update `HOWTO.md` and all nine `sql/*.sql` headers with the confirmed answer instead of the current placeholder guidance.
- **Whether `PATH` accepts a plain HTTPS URL**, not just `s3a://`/`wasb://`. Matters specifically for `sql/01_nyc_tlc_create.sql`, which currently defaults to the (less reliable) S3 mirror because of this. If HTTPS works, that script can switch to the CloudFront URL as primary.
- Once both are confirmed, re-run all nine scripts end to end and replace the placeholder date/version/release fragments in each `PATH` (called out in every script's header comment) with values confirmed current at the time.

## Conventions to keep

- Every source needs an actual license identified and a URL to it — no adding a dataset on the strength of "it's probably fine" or a platform's own license badge (Kaggle listings specifically need independent verification per `quickstart-data-manifest.md` §8).
- For sources with an ambiguous or unresolved license (NYC TLC, AWS Public Blockchain Data), the pattern is "point at the live source, don't re-host a copy in the repo" — keep that pattern for anything added later with the same kind of ambiguity.
- SQL syntax should trace back to an actual Zetaris doc page (`kbase.zetaris.com` or `data-fabric.readthedocs.io`), not be invented from general SQL conventions — Zetaris's DDL has real quirks (e.g., `s3Endpoint` + `useS3PathStyleAccess` for non-AWS S3-compatible endpoints) that don't match generic Spark/Hive syntax.
- `quickstart-data-manifest.md` §14 ("Known limitations and things worth double-checking") has a running list of smaller unconfirmed details across every category — worth a skim before treating any one source as fully settled.
