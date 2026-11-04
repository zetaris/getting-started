# Demo Bank

A synthetic retail bank for trying Zetaris federation and the Unified Semantic
Layer on a local Docker install, with no cloud accounts. All names, emails and
phone numbers are generated; there is no real customer data.

| Database | Stands in for | Tables (rows) |
|---|---|---|
| `SF_BANK` | Core banking warehouse (Snowflake) | branches (10), products (6), customers (500), accounts (800), transactions (20,025) |
| `DBX_RISK` | Risk lakehouse (Databricks) | merchants (25), cards (650), loans (250), card_transactions (15,025), fraud_alerts (688), credit_scores (3,000) |

Parquet, one file per table (`sf_bank/<table>.parquet`, `dbx_risk/<table>.parquet`), about 1 MB,
snapshot generated 2026-10-28. License: Apache License 2.0.

## Scripts

| Script | What it does |
|---|---|
| [`../../sql/10_demo_bank_create.sql`](../../sql/10_demo_bank_create.sql) | Creates `SF_BANK`, `DBX_RISK` and the 11 Parquet tables |
| [`../../sql/10_demo_bank_select.sql`](../../sql/10_demo_bank_select.sql) | Row-count verification, then 20 single-source and 10 federated example queries |
| [`../../../usl/sql/03_demo_bank_usl_create.sql`](../../../usl/sql/03_demo_bank_usl_create.sql) | USL `lightning.metastore.bank_demo.demo_bank_usl`: 11 tables, 14 relationships |
| [`../../../usl/sql/03_demo_bank_usl_select.sql`](../../../usl/sql/03_demo_bank_usl_select.sql) | `RUN DQ` on the FK rules, then queries over the USL |

## Quick start (local Docker)

1. Start Zetaris: `docker compose up -d` in your platform folder.
2. Copy the files into the containers, from the repo root:

       python3 scripts/copy_local_data.py --platform-dir <zetaris-platform-folder>

3. Run `10_demo_bank_create.sql`, then `03_demo_bank_usl_create.sql`, in the SQL
   Editor (or `python3 scripts/onboard.py`). Send the `COMPILE USL` block as one statement.
4. Uncomment and run the queries in the two `_select.sql` files one at a time.

A `docker cp` lasts for the life of the container; run step 2 again after
`docker compose down`.

## Things to know

- The "live" queries (Q10, Q20, F10) and 30-day windows use `current_date()`,
  so they return fewer rows as the snapshot ages.
- File sources show under `SHOW LIGHTNING DATABASES`, not `SHOW DATASOURCES`.
