# Recipe: Queryable SQL RDBMS

**Status:** 📋 Planned
**Priority:** 2
**Manifest reference:** `quickstart-data-manifest.md` §5
**Target location:** `sql/`

## Sources

- 🟢 **Self-hosted PostgreSQL via Docker** (start here) — official `postgres` image, PostgreSQL License, auto-loads sample data via `/docker-entrypoint-initdb.d/` on first boot.
- **Chinook** (MIT) — digital-media-store schema, DDL for 6 engines (SQLite/MySQL/PostgreSQL/SQL Server/Oracle/DB2) — most portable.
- **Pagila** (PostgreSQL License) — DVD-rental schema, join-heavy query demos.
- **AdventureWorks** (MIT) — SQL Server `.bak`, Microsoft's flagship OLTP/DW sample.
- 🟢 **Neon** (Postgres, serverless, permanent free tier, no card) and **Aiven for MySQL** (same no-card model) — hosted "query it remotely" targets.
- 🟡 **MongoDB Atlas M0** — free shared cluster; card requirement at signup unconfirmed (§14 open item). Skip Mongo's own bundled sample datasets (unclear license) — load Open Food Facts or a converted Chinook instead if a Mongo demo is wanted.
- 🔴 Not included: "IBM Telco Customer Churn" — no confirmed license anywhere in its provenance chain. If a churn-shaped demo is wanted later, generate synthetic data instead (faker/numpy script, same columns, fabricated IDs).

## Goal

Give Zetaris's `CREATE DATASOURCE` (JDBC) path a working reference, self-hosted-first, covering both a portable schema (Chinook) and a join-heavy one (Pagila), plus one hosted target so the "point Zetaris at a real remote database over the network" path is exercised too.

## Work items

- [ ] `postgres_docker/` — `docker-compose.yml` that starts Postgres, waits for health, loads Chinook + Pagila DDL/data on first boot
- [ ] `chinook/` — PostgreSQL-flavor DDL + data load script (starter DDL excerpt already in the manifest §5)
- [ ] `pagila/` — DDL + data load script
- [ ] `adventureworks/` — note as SQL Server-specific (`.bak` restore), lower priority than the Postgres-native pair
- [ ] `hosted/` — Neon setup walkthrough (Chinook/Pagila load), Aiven MySQL walkthrough (Chinook MySQL DDL), Atlas M0 walkthrough flagged with the unconfirmed card-requirement caveat
- [ ] Confirm `CREATE DATASOURCE` JDBC syntax against Zetaris docs (`kbase.zetaris.com/knowledge/connection-to-sql-server` and the Lightning SQL Manual's "Registering Logical Datasources" example) and verify against a live instance

## Open questions / dependencies

- MongoDB Atlas M0 credit-card requirement — confirm at signup before writing that walkthrough as "no card needed"
- Decide whether AdventureWorks is worth the SQL Server-specific setup cost relative to Chinook/Pagila, or gets deprioritized/dropped
