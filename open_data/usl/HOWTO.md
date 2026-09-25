# HOWTO: the USL rebuild of the EDGAR+SIC data product

**This package is a contrast, not a replacement.** `open_data/rest_apis/sql/10_company_dns_sic_create.sql` and `sql/11_edgar_company_profiles_create.sql` already build this same "EDGAR company profile enriched with a SIC hierarchy" data product using `CREATE LIGHTNING REST TABLE` + `CREATE SCHEMASTORE VIEW` + a manually-built Virtual Data Mart, and both are live-tested and confirmed working (see `docs/plans/edgar-sic-enrichment-plan.md`). This package rebuilds the same data product using the Unified Semantic Layer (USL) instead, so the two approaches can be run side by side and their behavior compared — per explicit request, neither this package nor `docs/plans/edgar-sic-enrichment-plan.md`'s original scripts should be deleted or treated as superseded by the other.

**Status: live-tested, fixes applied, believed passing — pending final confirmation.** Both scripts in this package's `sql/` directory have been run against a live Zetaris instance; a null-handling bug found during that run was fixed in a follow-up commit (`8f18f4f`, "Fix SQL queries in USL scripts to handle null values and document errors"). The person who ran the tests has not yet given final sign-off that both scripts pass end to end post-fix, so treat this as believed-working rather than closed out. See [`docs/plans/usl-simple-advanced-build-plan.md`](../../docs/plans/usl-simple-advanced-build-plan.md) for the build-and-verify checklist, and [`docs/guides/zetaris-sql-companion.md`](../../docs/guides/zetaris-sql-companion.md) section 8 for the reference material this package is meant to validate. The known open items in section 4 below (cross-USL foreign keys, materialization's SQL surface) are separate, still-open questions, unaffected by the null-handling fix.

---

## 1. Prerequisites

Both scripts here **reuse raw REST tables already registered by the `rest_apis` package** rather than re-registering the same endpoints under USL. Run these first, in this order, if they haven't already been run on the target instance:

1. `open_data/rest_apis/sql/10_company_dns_sic_create.sql` — Steps 0-1 only (through `CACHE TABLE company_dns.sic_codes_raw;`). This package's `01_simple_sic_usl.sql` activates directly from `company_dns.sic_codes_raw`.
2. `open_data/rest_apis/sql/11_edgar_company_profiles_create.sql` — Step 0 and the seven `CREATE LIGHTNING REST TABLE ..._submissions_raw` statements (the `CREATE SCHEMASTORE VIEW` statements in that script are **not** needed here — this package's advanced USL activates directly from the raw `*_submissions_raw` tables, not from `sql/11`'s own profile views).

This is deliberate: the point of the contrast is that USL's `ACTIVATE ... AS SELECT` clause can do the same flattening/joining work a `SCHEMASTORE VIEW` does, landing in a different (constraint-checked, DQ-capable, materializable) destination — not that USL needs a different set of raw sources.

## 2. The two scripts

| Script | USL | What it exercises |
|---|---|---|
| [`sql/01_simple_sic_usl.sql`](sql/01_simple_sic_usl.sql) | `sic_usl`, one table (`sic_code`) | Baseline lifecycle: `CREATE NAMESPACE` → `CREATE TABLE` → `COMPILE USL` → `ACTIVATE USL TABLE` (reusing `sql/10_company_dns_sic_create.sql`'s exact `LATERAL VIEW explode()` + `from_json`/`to_json` coercion query) → a custom `REGISTER DQ` rule → `RUN DQ` → `MATERIALIZE USL TABLE`. |
| [`sql/02_advanced_company_profile_usl.sql`](sql/02_advanced_company_profile_usl.sql) | `company_profile_usl`, two tables (`company`, `sic_code`) related by `FOREIGN KEY` | Everything the simple USL does, plus: an explicit FK relationship (auto-generating its own DQ rule), a UNION-shaped activation query across 7 raw REST tables in one `ACTIVATE` (replacing `sql/11_edgar_company_profiles_create.sql`'s two-layer per-company-view + `UNION ALL`-view pattern with a single activation), and a custom DQ rule that a bare FK can't express (see section 3). |

Run them in that order — the simple USL is the lower-risk smoke test for the USL lifecycle itself; the advanced one adds relationships and a cross-table DQ rule on top of a lifecycle already confirmed working.

## 3. The specific question this package exists to answer

`open_data/rest_apis/sql/11_edgar_company_profiles_select.sql` query 8 is a hand-written data-quality check:

```sql
SELECT entity_name, sic_code, sic_description_edgar, sic_description_reference
FROM edgar.all_companies_profile_table
WHERE sic_description_edgar <> sic_description_reference;
```

USL's `FOREIGN KEY` constraint auto-generates a DQ rule — but a foreign key only proves **referential existence** (a `sic` code named by a company actually exists in `sic_code`), not **value equality between two independently-sourced description columns**. `sql/02_advanced_company_profile_usl.sql` registers a second, custom DQ rule (`sic_description_agrees`, a correlated-subquery boolean expression) specifically to test whether that hypothesis holds live, or whether the FK rule turns out to cover more than expected. See `docs/plans/usl-simple-advanced-build-plan.md` section 4, step V6 for how this gets recorded once run.

## 4. Known open items in this package (unconfirmed, flagged rather than guessed past)

- **Cross-USL foreign keys are untested.** Both scripts define their own copy of the `sic_code` table rather than having `company_profile_usl.company` reference `sic_usl.sic_code` across USL boundaries — the USL User Guide's own `FOREIGN KEY ... REFERENCES` example only shows a same-DDL-block reference (`department(id)` within the same `CREATE TABLE` batch), and neither the guide nor the Kbase confirms whether a FK can target a table in a *different* USL. Duplicating `sic_code` avoids relying on an unconfirmed capability; if cross-USL FKs turn out to work, this duplication can be removed later.
- **`MATERIALIZE USL TABLE`'s SQL form doesn't document a `Records: Valid Records Only` equivalent.** The USL User Guide's UI section describes that option explicitly, but its own SQL command reference (Appendix B) shows only `format`/`path` options. `sql/02`'s materialization step is written both ways (a SQL-only attempt and a fallback note pointing at the GUI's Configure Materialization dialog) — this needs a live run to know which one actually works, and if only the GUI path works, that's a second VDM-shaped gap in USL's own SQL surface worth documenting in `docs/guides/zetaris-sql-companion.md` section 8.4.
- **The `cik` format mismatch from `sql/11_edgar_company_profiles_create.sql` is sidestepped, not fixed, the same way that script itself sidestepped it.** `company.cik` here is declared to match the zero-padded string shape from the `submissions` endpoint (the only shape used in this package) — this package never joins against `sql/01_edgar_company_facts_create.sql`'s revenue tables, where `cik` is a bare integer, so the mismatch noted in `sql/11_edgar_company_profiles_create.sql` caveat 1 doesn't come up here. A future extension joining USL's `company` table to revenue data would need to resolve that format difference first.

## 5. Teardown

Both scripts include a commented-out `TEARDOWN` block using `REMOVE USL` and `DROP NAMESPACE ... CASCADE` (per the USL User Guide section 12/Appendix B) — unlike the `rest_apis`/`parquet_csv` packages, USL claims a real SQL teardown path with no GUI-only step. This is itself one of the things `docs/plans/usl-simple-advanced-build-plan.md` step V10 needs to confirm live before it's treated as settled.

## 6. Everything else

For the REST/SchemaStore/VDM version of this same data product, see `open_data/rest_apis/sql/10_company_dns_sic_create.sql`, `sql/11_edgar_company_profiles_create.sql`, and `docs/plans/edgar-sic-enrichment-plan.md`. For the general USL reference material this package is built against, see `docs/guides/zetaris-sql-companion.md` section 8. For the build-and-verify tracking, see `docs/plans/usl-simple-advanced-build-plan.md`.
