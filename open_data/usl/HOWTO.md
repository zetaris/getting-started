# HOWTO: onboard these USL models into Zetaris

On the shared event instance, use your assigned namespace and model names consistently. Send one complete command at a time and keep each USL compile payload intact. The separate [EDGAR/PUDL/NOAA walkthrough](../../docs/guides/create-edgar-pudl-noaa-usl.md) depends on PUDL, which is currently known to fail.

These scripts rebuild data products already available through REST/SchemaStore and compare that path with USL. They are not replacements for the existing products.

**File naming:** each model has a numbered `_create.sql` for namespace, compile, activation, DQ, and optional materialization/teardown, plus a matching `_select.sql` for verification. Run them in that order.

---

## 0. Fast start: `sic_usl` end to end in about 5 minutes

This walkthrough runs the simpler `sic_usl` model from `sql/01_sic_usl_create.sql` and its matching select file.

**Prerequisite:** `open_data/rest_apis/sql/rate_limited/12_company_dns_create.sql` Steps 0-2 (through `CACHE TABLE company_dns.sic_codes_raw;`) must already have been run on this instance — this model activates directly from that raw V3 REST table. That script is rate limited, so run its steps one at a time, with 15 seconds or more before each step that calls the endpoint (see its header).

1. Open the Zetaris **SQL Editor** and create the parent metastore, then the package namespace (the parent is required on a clean instance; without it, the second statement fails with `parent namespace : metastore is not existing`):
   ```sql
   CREATE NAMESPACE IF NOT EXISTS lightning.metastore;
   CREATE NAMESPACE IF NOT EXISTS lightning.metastore.usl_demo;
   ```
2. Compile the table definition. It has no data until activation:
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
3. Activate it against the raw REST table (the same flattening query `sql/12_company_dns_create.sql` uses for its V3 SchemaStore view):
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

`sql/01_sic_usl_select.sql` has seven more queries, a self-consistency check, and DQ inspection. The remaining sections cover prerequisites, both models, and their verification status.

---

## 1. Prerequisites

Both models reuse raw REST tables from the `rest_apis` package. Register them in this order if they are missing:

1. `open_data/rest_apis/sql/rate_limited/12_company_dns_create.sql` — Steps 0-2 only (through `CACHE TABLE company_dns.sic_codes_raw;`); it also creates the V4 tables and views, which these models do not use. This package's `01_sic_usl_create.sql` activates directly from `company_dns.sic_codes_raw`.
2. `open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql` — Step 0 and the seven `CREATE LIGHTNING REST TABLE ..._submissions_raw` statements (the `CREATE SCHEMASTORE VIEW` statements in that script are **not** needed here — this package's `sic_edgar_usl` activates directly from the raw `*_submissions_raw` tables, not from `sql/11`'s own profile views).

USL's `ACTIVATE ... AS SELECT` can flatten and join the same raw sources used by SchemaStore views.

**Instance requirements:** `lightning.metastore` must exist before creating a child namespace. Without it, REST returned `parent namespace : metastore is not existing`. Both create scripts now open with `CREATE NAMESPACE IF NOT EXISTS lightning.metastore;` before `lightning.metastore.usl_demo`, so a clean instance no longer needs a separate init step. Send the multi-table `sic_edgar_usl` compile as one statement; semicolon-splitting clients break it. JDBC, REST, or the Unified Semantic Layer → New USL screen can send it intact.

## 2. Models in this package

See [`usl-sources.md`](usl-sources.md) for the catalog and verification status:

| Script | USL | What it exercises |
|---|---|---|
| [`sql/01_sic_usl_create.sql`](sql/01_sic_usl_create.sql) / [`_select.sql`](sql/01_sic_usl_select.sql) | `sic_usl`, one `sic_code` table | Baseline compile, activate, DQ, and deferred materialization; reuses the REST table's flattening query. Its self-consistency check is a plain query. |
| [`sql/02_sic_edgar_usl_create.sql`](sql/02_sic_edgar_usl_create.sql) / [`_select.sql`](sql/02_sic_edgar_usl_select.sql) | `sic_edgar_usl`, `company` and `sic_code` with an FK | Adds a DQ-generating foreign key and activates a union across seven raw REST tables. Its description check is a plain query. |

**What was verified.** Both scripts were run unchanged, exactly as they are in this repo, on an instance built from `open_data/rest_apis/sql/rate_limited/12_company_dns_create.sql` (V3 and V4 tables and all four views present), and their `_select.sql` queries were run against the resulting USLs. They activate from the V3 raw table (`company_dns.sic_codes_raw`, which that script keeps under the same name) and do not read the V4 views, so nothing here has been verified about a USL over V4 data or over a schemastore view; whether `ACTIVATE USL TABLE` can read a schemastore view remains untested.

Run them in that order — `sic_usl` is the lower-risk smoke test for the USL lifecycle itself; `sic_edgar_usl` adds relationships on top of a lifecycle already confirmed working.

## 3. The question `sic_edgar_usl` exists to answer

Query 8 in `open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_select.sql` checks description agreement:

```sql
SELECT entity_name, sic_code, sic_description_edgar, sic_description_reference
FROM edgar.all_companies_profile_table
WHERE sic_description_edgar <> sic_description_reference;
```

The FK-generated DQ rule checks that each SIC code exists; it does not compare descriptions. Two attempts to register description equality as `REGISTER DQ` failed, so the model checks it with a plain join. That join drops IBM and returns five wording differences; the FK rule flags IBM as missing from the SIC reference. The checks catch different issues. See the [SQL companion](../../docs/guides/zetaris-lightning-sql-companion.md#86-register-dq-confirmed-limitations-live-tested), [`usl-sources.md`](usl-sources.md), and archived build plan section 4, step V6.

## 4. Known open items in this package

See the [SQL companion's open USL items](../../docs/guides/zetaris-lightning-sql-companion.md#85-known-open-items-in-this-repos-usl-package-specifically), including untested cross-USL foreign keys, the SQL materialization gap for `Valid Records Only`, and the `cik` format sidestep. `REGISTER DQ` limits are in [section 8.6](../../docs/guides/zetaris-lightning-sql-companion.md#86-register-dq-confirmed-limitations-live-tested).

## 5. Teardown

Both scripts include commented `REMOVE USL` and `DROP NAMESPACE ... CASCADE` teardown statements from the USL User Guide. The package's archived build plan still lists live teardown confirmation as open (step V10).

## 6. Everything else

For the REST/SchemaStore/VDM versions, see the linked scripts and [`edgar-sic-enrichment-plan.md`](../../docs/plans/archive/edgar-sic-enrichment-plan.md). General USL guidance is in [SQL companion section 8](../../docs/guides/zetaris-lightning-sql-companion.md#8-the-unified-semantic-layer-usl-a-scriptable-alternativesuccessor-to-vdm). Verification history is in the [archived build plan](../../docs/plans/archive/usl-build-plan.md).
