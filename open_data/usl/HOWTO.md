# HOWTO: onboard these USL models into Zetaris

On the shared event instance, use assigned team namespaces/model names and replace every dependent reference consistently. Execute one complete command at a time; keep each USL compile payload intact. For the separate historical [EDGAR/PUDL/NOAA walkthrough](../../docs/guides/create-edgar-pudl-noaa-usl.md), note that its PUDL prerequisite is currently known to fail and must be resolved before execution.

The general walkthrough for this package's `sql/` scripts — read this once before running any of them. Each model here rebuilds a data product already built elsewhere in this repo (currently, `open_data/rest_apis/`'s REST+SchemaStore+VDM version of the EDGAR+SIC data product) using the Unified Semantic Layer instead, as a contrast, not a replacement — so the two approaches can be run side by side and compared.

**File naming:** each model is split into two files sharing a prefix: `NN_<name>_create.sql` (namespace, `COMPILE USL`, `ACTIVATE`, `RUN DQ`, and a commented-out `MATERIALIZE`/teardown) and `NN_<name>_select.sql` (verification and contrast queries). Run the create script first, then verify with its matching select script.

---

## 0. Fast start: `sic_usl` end to end in about 5 minutes

The fastest way to see this package's whole pattern — namespace, design, compile, activate, verify — on a real, live source, before reading anything else. This uses `sic_usl` (`sql/01_sic_usl_create.sql` / `_select.sql`), the simpler of the two models.

**Prerequisite:** `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql` Steps 0-1 (through `CACHE TABLE company_dns.sic_codes_raw;`) must already have been run on this instance — this model activates directly from that raw REST table.

1. Open the Zetaris **SQL Editor** and create the namespace:
   ```sql
   CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo;
   ```
2. Design and compile the table (DDL only — no data yet, the card renders grey until step 3's activation):
   ```sql
   COMPILE USL IF NOT EXISTS sic_usl DEPLOY NAMESPACE lightning.metastore.usl_demo DDL
   CREATE TABLE sic_code (
       sic_code varchar(4) NOT NULL PRIMARY KEY,
       description varchar(200),
       division varchar(1),
       division_desc varchar(200),
       major_group varchar(2),
       major_group_desc varchar(200),
       industry_group varchar(3),
       industry_group_desc varchar(200)
   );
   ```
3. Activate it against the raw REST table (the same flattening query `sql/10_company_dns_sic_create.sql` uses for its SchemaStore view):
   ```sql
   ACTIVATE USL TABLE lightning.metastore.usl_demo.sic_usl.sic_code AS
   SELECT
       sic_code,
       sic_val.description AS description,
       sic_val.division AS division,
       sic_val.division_desc AS division_desc,
       sic_val.major_group AS major_group,
       sic_val.major_group_desc AS major_group_desc,
       sic_val.industry_group AS industry_group,
       sic_val.industry_group_desc AS industry_group_desc
   FROM company_dns.sic_codes_raw
   LATERAL VIEW explode(
       from_json(to_json(data.sics), 'map<string, struct<description:string, division:string, division_desc:string, major_group:string, major_group_desc:string, industry_group:string, industry_group_desc:string>>')
   ) AS sic_code, sic_val;
   ```
4. Verify it worked:
   ```sql
   SELECT COUNT(*) FROM lightning.metastore.usl_demo.sic_usl.sic_code;   -- expect 1005
   ```
5. Try a real query — every SIC code in the "Manufacturing" division, for example:
   ```sql
   SELECT sic_code, description, major_group_desc
   FROM lightning.metastore.usl_demo.sic_usl.sic_code
   WHERE division_desc LIKE '%Manufacturing%'
   ORDER BY sic_code;
   ```

That's the lifecycle through activation. `sql/01_sic_usl_select.sql` has 7 more example queries, a self-consistency check, and DQ inspection queries if you want to keep exploring this table. Everything below covers both models in more depth, the FK/DQ contrast `sic_edgar_usl` adds, and what's confirmed vs. not yet run live.

---

## 1. Prerequisites

Both scripts here **reuse raw REST tables already registered by the `rest_apis` package** rather than re-registering the same endpoints under USL. Run these first, in this order, if they haven't already been run on the target instance:

1. `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql` — Steps 0-1 only (through `CACHE TABLE company_dns.sic_codes_raw;`). This package's `01_sic_usl_create.sql` activates directly from `company_dns.sic_codes_raw`.
2. `open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql` — Step 0 and the seven `CREATE LIGHTNING REST TABLE ..._submissions_raw` statements (the `CREATE SCHEMASTORE VIEW` statements in that script are **not** needed here — this package's `sic_edgar_usl` activates directly from the raw `*_submissions_raw` tables, not from `sql/11`'s own profile views).

This is deliberate: the point of the contrast is that USL's `ACTIVATE ... AS SELECT` clause can do the same flattening/joining work a `SCHEMASTORE VIEW` does, landing in a different (constraint-checked, DQ-capable, materializable) destination — not that USL needs a different set of raw sources.

**Instance requirements.** `lightning.metastore` must exist before `CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo` can succeed; on an instance where it did not, the statement failed with "parent namespace : metastore is not existing" over REST. After a clean instance reset it worked over both JDBC and REST. A `COMPILE USL` with more than one table (`sic_edgar_usl`) must be sent as one statement: the SQL Workspace editor and any runner that splits on `;` will break it apart, so send it whole over JDBC or REST, or use the GUI's Unified Semantic Layer → New USL screen.

## 2. Models in this package

See [`usl-sources.md`](usl-sources.md) for the full catalog (tables, what each tests, current verification status). In short:

| Script | USL | What it exercises |
|---|---|---|
| [`sql/01_sic_usl_create.sql`](sql/01_sic_usl_create.sql) / [`_select.sql`](sql/01_sic_usl_select.sql) | `sic_usl`, one table (`sic_code`) | Baseline lifecycle: `CREATE NAMESPACE` → `CREATE TABLE` → `COMPILE USL` → `ACTIVATE USL TABLE` (reusing `sql/10_company_dns_sic_create.sql`'s exact `LATERAL VIEW explode()` + `from_json`/`to_json` coercion query) → `RUN DQ` → `MATERIALIZE USL TABLE`. Its self-consistency check runs as a plain query (see section 3). |
| [`sql/02_sic_edgar_usl_create.sql`](sql/02_sic_edgar_usl_create.sql) / [`_select.sql`](sql/02_sic_edgar_usl_select.sql) | `sic_edgar_usl`, two tables (`company`, `sic_code`) related by `FOREIGN KEY` | Everything `sic_usl` does, plus: an explicit FK relationship (auto-generating its own DQ rule) and a UNION-shaped activation query across 7 raw REST tables in one `ACTIVATE` (replacing `sql/11_edgar_company_profiles_create.sql`'s two-layer per-company-view + `UNION ALL`-view pattern with a single activation). Its description-agreement check also runs as a plain query (see section 3). |

Run them in that order — `sic_usl` is the lower-risk smoke test for the USL lifecycle itself; `sic_edgar_usl` adds relationships on top of a lifecycle already confirmed working.

## 3. The question `sic_edgar_usl` exists to answer

`open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_select.sql` query 8 is a hand-written data-quality check:

```sql
SELECT entity_name, sic_code, sic_description_edgar, sic_description_reference
FROM edgar.all_companies_profile_table
WHERE sic_description_edgar <> sic_description_reference;
```

USL's `FOREIGN KEY` constraint auto-generates a DQ rule — but a foreign key only proves **referential existence** (a `sic` code named by a company actually exists in `sic_code`), not **value equality between two independently-sourced description columns**. `sic_edgar_usl`'s equivalent check (`open_data/usl/sql/02_sic_edgar_usl_select.sql`) tests this directly, as a plain join rather than a `REGISTER DQ` rule — two attempts to register it as a `REGISTER DQ` rule failed live (see [`docs/guides/zetaris-lightning-sql-companion.md` section 8.6](../../docs/guides/zetaris-lightning-sql-companion.md#86-register-dq-confirmed-limitations-live-tested)). The FK rule's own `RUN DQ` result is confirmed (see [`usl-sources.md`](usl-sources.md)), and the comparison has been run: the plain `INNER JOIN` query drops IBM and returns 5 wording-only description differences, while the FK rule flags IBM. They are complementary. See `docs/plans/archive/usl-build-plan.md` section 4, step V6.

## 4. Known open items in this package

Moved to [`docs/guides/zetaris-lightning-sql-companion.md` section 8.5](../../docs/guides/zetaris-lightning-sql-companion.md#85-known-open-items-in-this-repos-usl-package-specifically), alongside the rest of the general and USL-specific platform-limitation reference — cross-USL foreign keys (untested), `MATERIALIZE USL TABLE`'s SQL-form gap around `Valid Records Only`, and the `cik` format sidestep. `REGISTER DQ`'s own confirmed limitations are in section 8.6. Read both before treating either script's output as fully settled.

## 5. Teardown

Both scripts include a commented-out `TEARDOWN` block using `REMOVE USL` and `DROP NAMESPACE ... CASCADE` (per the USL User Guide section 12/Appendix B) — unlike the `rest_apis`/`parquet_csv` packages, USL claims a real SQL teardown path with no GUI-only step. This is itself one of the things `docs/plans/archive/usl-build-plan.md` step V10 needs to confirm live before it's treated as settled.

## 6. Everything else

For the REST/SchemaStore/VDM version of this same data product, see `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql`, `open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql`, and `docs/plans/archive/edgar-sic-enrichment-plan.md`. For the general USL reference material this package is built against, see `docs/guides/zetaris-lightning-sql-companion.md` section 8. For the build-and-verify tracking, see `docs/plans/archive/usl-build-plan.md`.
