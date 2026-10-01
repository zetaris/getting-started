# USL Models for Zetaris Quick-Starts

A catalog of Unified Semantic Layer (USL) models built in this package — each one a `CREATE NAMESPACE` + `COMPILE USL` + `ACTIVATE USL TABLE` + `RUN DQ` lifecycle over data already onboarded elsewhere in this repo. For the SQL syntax pattern, the lifecycle walkthrough, and the specific question this package exists to answer, see `HOWTO.md` — it isn't repeated here.

**Script location:** each model's script pair lives directly in `sql/` as `NN_<name>_create.sql` / `NN_<name>_select.sql` — no rate-limit or source-type grouping applies here, since every model reuses raw tables already registered by `open_data/rest_apis/`.

---

## Quick-reference table

| # | Model | Tables | What it tests | Verification | Script |
|---|---|---|---|---|---|
| 1 | `sic_usl` | One: `sic_code` | Baseline USL lifecycle — namespace, compile, activate, a self-consistency check, deferred materialization | Lifecycle verified; self-consistency check confirmed not expressible as `REGISTER DQ`, runs as a plain query instead | `sql/01_sic_usl_create.sql` |
| 2 | `sic_edgar_usl` | Two, FK-related: `company`, `sic_code` | FK relationships, an FK-generated DQ rule, a description-agreement check, deferred `Valid Records Only` materialization | Lifecycle verified; FK rule verified (found 1 real invalid record, 6/7); description-agreement check runs as a plain query instead of `REGISTER DQ`; FK-vs-check comparison not yet run | `sql/02_sic_edgar_usl_create.sql` |

"Verified" means the statement in question has been run successfully against a live Zetaris instance. "Not yet run" means written against the documented grammar but not yet tried live at all. See [`docs/guides/zetaris-sql-companion.md` section 8.6](../../docs/guides/zetaris-sql-companion.md#86-register-dq-confirmed-limitations-live-tested) for what's confirmed about `REGISTER DQ`'s limitations generally, rather than repeating it per model here.

---

## 1. `sic_usl` — single-table USL

- **What it is:** a USL rebuild of `company_dns`'s SIC hierarchy reference data (already onboarded via REST in `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql`) — the lowest-risk USL smoke test, confirming the basic lifecycle works before attempting a two-table, FK-related model.
- **Source data:** reuses `company_dns.sic_codes_raw` directly — no new REST registration.
- **Status detail:** the lifecycle through `ACTIVATE` (namespace, compile, activate, 1,005 rows) is confirmed working. The custom `major_group_desc_consistent` self-consistency check is confirmed not expressible as a `REGISTER DQ` rule on this table and runs instead as a plain aggregate query in `sql/01_sic_usl_select.sql` — see `docs/guides/zetaris-sql-companion.md` section 8.6 for why. The PK constraint's auto-generated `RUN DQ` rule has not yet been confirmed to pass. Materialization is deferred (no cloud storage target configured on any instance this repo has touched).

## 2. `sic_edgar_usl` — two-table, FK-related USL

- **What it is:** a USL rebuild of the EDGAR+SIC "company profile" data product (already built via REST+SchemaStore+manual-VDM in `open_data/rest_apis/sql/rate_limited/11_edgar_company_profiles_create.sql`) — the actual contrast artifact, using a `FOREIGN KEY` relationship and its auto-generated DQ rule instead of a hand-written self-consistency query.
- **Source data:** reuses `company_dns.sic_codes_raw` and the seven `*_submissions_raw` REST tables from `sql/11` directly — no new REST registration.
- **Status detail:** the lifecycle through both `ACTIVATE` statements is confirmed working (a null-handling bug found on the first live run was fixed in commit `8f18f4f`). The description-agreement check is not registered as a `REGISTER DQ` rule — see `docs/guides/zetaris-sql-companion.md` section 8.6 — and runs instead as a plain join query in `sql/02_sic_edgar_usl_select.sql`. `RUN DQ` has run: the auto-generated PK rule (`cik`) reports 7 total, 7 valid, 0 invalid; the auto-generated FK rule (`sic`) reports 7 total, **6 valid, 1 invalid**. `SHOW DQ ALL INVALID` identified the invalid record: IBM (`cik` `0000051143`, `sic` `3570`, `sic_description_edgar` "Computer & office Equipment") — a real 4-digit code, not a null/empty-string artifact of the activation query's `COALESCE`, so the leading explanation is that `company_dns`'s 1,005-row SIC reference list doesn't include code `3570` at all. Not yet confirmed directly (`SELECT * FROM sic_code WHERE sic_code = '3570'` would settle it). This is very likely the same root cause behind a previously-unresolved discrepancy on the REST side — `sql/11`'s `all_companies_profile_table` also showed IBM missing (6 rows instead of 7) via the identical `INNER JOIN ... ON s.sic = r.sic_code`; see `docs/plans/archive/edgar-sic-enrichment-plan.md` section 8.8. Whether the FK rule alone would have been sufficient (the question this model exists to answer) is not yet confirmed — compare the FK rule's result against the plain query's once the latter has run; the plain query is an `INNER JOIN`, so it will silently exclude IBM rather than surfacing it, same blind spot as `sql/11`'s own version. Materialization is deferred, same as `sic_usl`.

---

**See also:** `HOWTO.md` for the Zetaris USL onboarding walkthrough and the lifecycle this package exercises, `docs/guides/zetaris-sql-companion.md` section 8 for the general USL reference material, and `docs/plans/archive/usl-build-plan.md` for the live-verification checklist this catalog's status detail is drawn from.
