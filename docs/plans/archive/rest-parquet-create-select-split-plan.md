# Plan: Split CREATE setup from verification/example SELECT queries (REST + Parquet packages)

> **Archived — done.** This split was executed (commit `4b25da1`, "Split REST/Parquet SQL scripts into CREATE and SELECT files", merged via PR #10). Every `open_data/rest_apis/sql/*` and `open_data/parquet_csv/sql/*` file now ships as a `*_create.sql`/`*_select.sql` pair. Kept here as a historical record of the target structure and rationale.

**Status:** ✅ Done — executed in `4b25da1` (PR #10).
**Depends on:** `open_data/rest_apis/sql/*.sql`, `open_data/rest_apis/failure_cases/singapore_pm25/04_singapore_pm25.sql`, `open_data/parquet_csv/sql/*.sql`, and every doc that cites them (§5).
**Out of scope:** `open_data/usl/sql/*.sql` — a different DDL family (`CREATE NAMESPACE`/`CREATE TABLE` against the Iceberg-backed metastore, per `docs/guides/zetaris-sql-companion.md` §7-8) with its own CREATE/INSERT/SELECT shape. Noted as possible future follow-up in §6.

---

## 1. Problem statement

Every script in `open_data/rest_apis/sql/` and `open_data/parquet_csv/sql/` is a single linear file that interleaves four different kinds of statements:

1. **Setup DDL** — `CREATE LIGHTNING DATABASE`, `CREATE SCHEMASTORE CONTAINER`, `CREATE LIGHTNING REST TABLE` / `CREATE LIGHTNING FILESTORE TABLE`, `CREATE SCHEMASTORE VIEW`, and (one source) `CACHE TABLE`.
2. **Verification `SELECT`s** — the `-- Verify:` block right after each object is created: a row-count or spot-check confirming the object exists and looks right.
3. **Example/downstream `SELECT`s** — analytical, illustrative queries further down the file, present in most `rest_apis` scripts (`sql/05`–`sql/11`) but largely absent from `parquet_csv` scripts.
4. **Teardown DDL** — commented-out `DROP VIEW` statements at the bottom.

A developer who just wants to stand up a source has to scroll past analytical example queries to find the DDL; a developer who wants example queries has to re-read all the setup caveats first. That mixing is the usability problem this plan addresses, per the user's ask to separate "CREATE functions" from "verification SELECT functions."

## 2. Target file structure

For each script currently at `sql/NN_<name>.sql`, split into two files sharing the numeric prefix:

- **`sql/NN_<name>_create.sql`** — every `CREATE` / `CACHE TABLE` / `UNCACHE TABLE` / `DROP` statement: the logical database, the schemastore container, the REST/filestore table(s), the schemastore view(s), and the existing commented-out `TEARDOWN` block. Keeps the full header comment block (source/license/format/docs/caveats) as-is, since nearly every caveat concerns the DDL. Ends with a one-line pointer: `-- Next: verify with sql/NN_<name>_select.sql`.
- **`sql/NN_<name>_select.sql`** — every `SELECT` statement, in two clearly headed sections:
  - `-- === Verification ===` — the row-count/spot-check queries that confirm the create script worked (today's `-- Verify:` blocks, including any `curl`/`jq` cross-check commands given alongside them as comments).
  - `-- === Example queries ===` — the downstream/analytical queries, only present where they exist today (`rest_apis/sql/05`–`11`).
  Starts with a one-line pointer back: `-- Assumes sql/NN_<name>_create.sql has already been run.`

**Why two files, not three:** the ask is CREATE vs. SELECT. A strict three-way split (`_create` / `_verify` / `_queries`) would leave most `parquet_csv` scripts with a one-line `_verify.sql` and an empty `_queries.sql` — file proliferation without a usability gain there. Labelled sections inside one `_select.sql` keep the split meaningful for the `rest_apis` scripts that actually have both kinds of `SELECT`, without junk files elsewhere.

**Open question to confirm with the user before execution:** the above (2 files, labelled sections) vs. a strict 3-file split despite the near-empty files it creates in `parquet_csv`. This plan recommends the 2-file approach.

## 3. Structural nuances to account for per-file (not uniform 1:1 create→verify)

- **`rest_apis/sql/01` and `sql/11`** (EDGAR, 7 companies each) don't have one inline `-- Verify:` per company. Verification today is a *templated* diagnostic ("run this per company, swapping the CIK/table name") plus one literal `curl`-based verification block near the bottom, plus an optional cross-company `UNION ALL` view gated on "verify every individual view first." The `_select.sql` for these two needs to carry: the templated diagnostic, the literal verification block, and the downstream-note callouts — none of these map to a single object the way `sql/02`'s per-Pokémon `-- Verify:` blocks do.
- **The optional cross-company `UNION ALL` view** in `sql/01`/`sql/11` is itself a `CREATE SCHEMASTORE VIEW`, so it belongs in `_create.sql` by type — but its own comment says not to run it until the individual views have been verified via `_select.sql`. This is a real create-depends-on-verify ordering wrinkle; resolve it by keeping the comment/gate as-is in `_create.sql` rather than trying to encode run-order across files.
- **`rest_apis/sql/08`** (StatCan) registers 5 dated raw REST tables (one per day) before a single unioning view — the CREATE section is one-to-many, not one-to-one with `parquet_csv`'s simpler pattern; inventory this explicitly so the split doesn't accidentally drop one of the five.
- **`rest_apis/sql/10`** is the one script using `CACHE TABLE` as a documented workaround for re-fetch-per-query behavior. `CACHE TABLE`/`UNCACHE TABLE` are lifecycle statements on the raw table, not verification — keep them in `_create.sql`, immediately after the table they cache, and keep `HOWTO.md`'s troubleshooting note about caching intact (§5).
- **`parquet_csv/sql/01`** has a `-- ! Forbidden` Option A (dead S3 mirror, kept for reference) with its own `-- Verify:` and a fully commented-out Option B (with its own commented-out `CREATE`s, no verify). Both options' `CREATE`s go in `_create.sql`; only Option A has a `SELECT` to move to `_select.sql`.
- **Teardown blocks** are `CREATE`'s inverse (`DROP VIEW`), so they stay in `_create.sql` as already-commented-out blocks — no change to that convention, just carried over.

## 4. Full inventory

### 4.1 `open_data/rest_apis/sql/` (10 files) + 1 excluded failure case

| File | Has example-query section beyond verify? | Notable structure |
|---|---|---|
| `01_edgar_company_facts.sql` | No (verify only) | 7 per-company CREATE pairs; templated diagnostic + curl verify; optional gated cross-company view |
| `02_pokeapi.sql` | No | 2 pokémon, clean per-object `-- Verify:` blocks; one cross-pokémon union view |
| `03_open_food_facts_live.sql` | No | 4 products, clean per-object `-- Verify:` blocks |
| `05_nasa_neows.sql` | Yes | Clean verify block, then a full example-query section |
| `06_nasa_donki.sql` | Yes | Same shape as `05` |
| `07_eurostat.sql` | Yes | Verify block, then JSON-stat decode examples |
| `08_statcan_wds.sql` | Yes | 5 dated raw tables → 1 union view; verify block; then examples incl. window-function rewrites |
| `09_abs_data_api.sql` | Yes | Verify block, then SDMX examples |
| `10_company_dns_sic.sql` | Yes | Includes `CACHE TABLE`; verify block with expected-count comment; then examples |
| `11_edgar_company_profiles.sql` | Yes | Same per-company shape as `01`, plus a worked example section |
| `failure_cases/singapore_pm25/04_singapore_pm25.sql` | Yes | Excluded from the main sequence, but same interleaved shape — split for consistency (§4.3) |

### 4.2 `open_data/parquet_csv/sql/` (9 files)

All follow the same simple shape: one or two `CREATE LIGHTNING DATABASE` + `CREATE LIGHTNING FILESTORE TABLE` statements, each immediately followed by a one-line `-- Verify: SELECT * FROM ... LIMIT 10;`. No example-query sections anywhere in this package. `01_nyc_tlc.sql` is the one exception with the dead-Option-A / commented-Option-B structure noted in §3.

### 4.3 The failure-case file

`failure_cases/singapore_pm25/04_singapore_pm25.sql` keeps its original `04` prefix (the number it held before being excluded from the main `rest_apis/sql/` sequence) — split it the same way for package-wide consistency: `04_singapore_pm25_create.sql` / `04_singapore_pm25_select.sql`, staying inside `failure_cases/singapore_pm25/`. `ISSUE.md` in the same directory references this script directly (§5) and must be updated in the same change.

## 5. Documentation cross-references that must be updated

A repo-wide search for `sql/0[1-9]` currently matches these 12 files. None of them can be updated by a blind filename find/replace — each needs a judgment call on whether the reference is (a) "run this script" (→ point at `_create.sql` then `_select.sql`), (b) "verify against this script's output" (→ point at `_select.sql`), or (c) a citation of a specific fact/caveat that lives in the header comments (→ point at `_create.sql`, and recheck any line-number citation, see below):

- `open_data/rest_apis/HOWTO.md` — the syntax skeleton (§1), "Running the scripts" walkthrough and order table (§4), "Verifying data" (§5), and scattered footnotes throughout §8's troubleshooting entries.
- `open_data/rest_apis/rest-api-sources.md` — per-source catalog entries likely link to `sql/NN_name.sql`.
- `open_data/rest_apis/failure_cases/singapore_pm25/ISSUE.md` — references its own script by name.
- `open_data/parquet_csv/HOWTO.md` — same idea, simpler (no example-query section to account for).
- `open_data/parquet_csv/parquet-csv-data-sources.md` — per-source catalog entries.
- `open_data/usl/HOWTO.md` — cites the REST scripts it builds on top of.
- `docs/plans/edgar-sic-enrichment-plan.md` — cites `sql/01` and `sql/11` repeatedly, **including line-number citations** (`sql/01, line 32-40` / `lines 32-40`, appearing at least twice) that will point at the wrong statement once the file is split and re-numbered. These must be recomputed against the new `_create.sql`, not just renamed.
- `docs/plans/REST-API-HANDOFF.md`
- `docs/plans/archive/00-parquet-csv.md`
- `docs/plans/archive/01-rest-json-apis.md`
- `docs/plans/usl-simple-advanced-build-plan.md`
- `docs/guides/zetaris-sql-companion.md`
- `handoff.md`

**The line-number-citation risk is the largest correctness risk in this change** — a filename-only find/replace will leave stale line numbers that silently point at the wrong statement (or past end-of-file) in the new, shorter `_create.sql`. Every citation of the form "`sql/NN`, line(s) X-Y" found anywhere in the repo must be re-derived against the split files, not mechanically renamed.

## 6. Execution steps (for when this plan is later carried out — not run now)

1. Confirm the 2-file-vs-3-file naming decision (§2) with the user.
2. For each source, mechanically partition its statements per §2-§3 into `_create.sql` / `_select.sql`, preserving all header/caveat comments in `_create.sql` and adding the one-line cross-reference header to each new file.
3. Replace each original combined file with its two split files (`git rm` the original, `git add` the pair) — don't leave the old combined file alongside the split ones; that would just recreate the mixing problem one level up.
4. Grep the full repo for every remaining reference to an old `sql/NN_<name>.sql` filename (§5) and update each to the correct new file(s) for its context.
5. Re-derive every line-number citation found against an old file and point it at the correct line in the correct new file.
6. Update both `HOWTO.md` files' "Running the scripts"/walkthrough sections, order tables, and "Verifying data" sections to describe a run-`_create.sql`-then-run-`_select.sql` sequence per source.
7. Sanity check per split pair: concatenating `_create.sql` + `_select.sql` (in that order) reproduces the exact statement set of the original file — nothing dropped, nothing duplicated — and any cross-statement ordering caveat (e.g. `sql/10`'s "cache the raw table right after creating it, before querying") still reads correctly with verification now living in a separate file.
8. Final review pass over the full diff, including every touched doc file, before considering the change complete.

**Suggested order of work:** `parquet_csv` first — 9 simple, low-risk files with no example-query sections — to prove out the two-file pattern and the doc-update workflow cheaply, then `rest_apis` (11 files including the failure case), which carries the larger doc cross-reference blast radius and the line-number-citation risk from §5.

## 7. Explicitly out of scope for this pass

- `open_data/usl/sql/*.sql` — different DDL family (metastore `CREATE NAMESPACE`/`CREATE TABLE`), not a Lightning REST/filestore source; would need its own analysis of what "verification" even means there (its `SELECT`s are INSERT-shaped population queries, not read-only spot-checks) before a parallel split makes sense.
- Any change to the actual DDL/SQL logic, caveats, or example-query content — this is a pure file-organization change plus the doc updates it forces; no query behavior changes.
