# Zetaris installation guide: test record

This file records the tests run against the [installation and configuration guide](updated_zetaris_installation_guide.md). It lists what was run, what the results were, and what has not been tested yet.

## Summary

| Guide section | Result | Date |
| --- | --- | --- |
| §3 Path A: local Docker Compose, fresh install on empty volumes | ✅ Passed | 24 Sep 2026 |
| §5 First login and `SELECT 7 AS seven` | ✅ Passed | 24 Sep 2026 |
| §6 Parquet/CSV recipe (PUDL energy sources) | ⚠️ Passed at the time, no AWS credentials needed — contradicted by a later failure writeup, then passed again in a 2026-10-31 re-test on self-hosted 2.4.3.1; the difference is not reconciled (see §6) | 24 Sep 2026 |
| §6 REST recipe (PokéAPI Pikachu abilities) | ✅ Passed | 24 Sep 2026 |
| §7 Stop, start, down and up, with data retained | ✅ Passed | 24 Sep 2026 |

## Test environment

| Item | Value |
| --- | --- |
| Host | macOS on Apple Silicon (arm64), amd64 images run under emulation |
| Docker | Engine 29.8.0, Compose plugin 5.5.1 |
| Resources given to Docker | 7.7 GiB memory, 8 CPUs, 29 GB free disk |
| Images | driver `zetaris-ndp-driver:main-2.4.3.1-92eca65…`, API `zetaris-ndp-api:main-2.4.3.1-36a2ea1…`, UI `zetaris-new-ui:main-fb1fc51…`, AI `lightning-ai-datasteward:main-0.1.0-d9201cc…`, `postgres:16-alpine` |
| Bundle | The supplied `zetaris-platform` bundle, zipped and then unzipped into an empty directory |

## Method

- **Empty volumes.** `docker-compose.yml` sets the project name `zetaris`, so a second copy on the same host would reuse an existing install's volumes. The test copy was run with `COMPOSE_PROJECT_NAME=zfresh`, which takes precedence over the file's `name:`. That gave it its own empty `zfresh_*` volumes. Every command from the guide was otherwise run as written.
- **Existing install.** The host already had a working `zetaris` install. Docker lacked the memory to run both, so that install was stopped with `docker compose stop` during the test. Afterwards it was restarted with `docker compose start`, and `./verify.sh` passed all 9 checks on it.
- **§3.3 configuration.** A new administrator email, organisation (`quickstart`) and password were set. The password followed the guide's policy, using `@` and no `$`. `UI_PORT` was set to `127.0.0.1:3000`, and the remaining supplied values were kept (`2g` / `2` / `local[2]` / `1g`, `ZETARIS_SEED_TPCH=true`, `COMPOSE_PROFILES` unset). The file was then locked down with `chmod 600 .env`.
- **SQL.** The §5 and §6 statements were sent to the platform's SQL Editor endpoint (`POST /api/proxy/sql-editor/sqls/run-query`), signed in as the new administrator. This is the same call the browser's SQL Editor makes. The statements were not typed into a browser window.
- **Clean-up.** The test project was removed with `docker compose down -v`, scoped to `zfresh`. The existing `zetaris_*` volumes were not touched.

## Results

### §3 Local installation

| Step | Result |
| --- | --- |
| `unzip`, `cd`, `docker compose version` | Passed |
| `./preflight.sh` | Passed, with 3 expected warnings: arm64 emulation, memory 7 GB (8 GB recommended), and the other install's `zetaris_pgdata` volume |
| `docker compose config --quiet` | Passed; no configuration printed |
| `docker compose pull` | Passed. The registry login gave access to all 5 images, which were already cached |
| `docker compose up -d` | Passed. It returned once `api` was healthy, and `ui` was published on `127.0.0.1:3000` |
| Pull start to `bootstrap` `Exited (0)` | **201 s** with cached images. A first install also has to download about 4 GB |
| `docker compose ps --all` | `postgres`, `driver`, `api`, `ui` and `ai-datasteward` were healthy. `init` and `bootstrap` showed `Exited (0)` |
| `./verify.sh` | **9 of 9 passed**, including login and `select 7` through ui → api → driver |
| Loopback binding | `http://localhost:3000` responded (HTTP 307 to sign-in). The host's LAN address on port 3000 did not respond |

### §5 First login and query

Signing in with the email and password set in `.env` returned a session token. `SELECT 7 AS seven` returned one row with the value `7`.

### §6 Parquet/CSV: PUDL

**Update — passed again 2026-10-31, difference not reconciled.** A later writeup had marked `03_pudl_create.sql` known to fail because the bucket name `pudl.catalyst.coop` contains dots. A re-test that day registered a new filestore table on `s3a://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` with `useS3PathStyleAccess "true"` (1.6 s) and read it on a self-hosted Zetaris 2.4.3.1 instance (hackathon Docker images). Why the earlier writeup failed is not established; it may have been a different environment. `SELECT * ... LIMIT 10` returned 10 rows, starting `AB`, `ANT`, `BFG`. `COUNT(*)` matched the Parquet footers: 42 rows in the energy-source file (12,326 bytes, last modified 2026-10-14) and 666,788 rows in `out_eia__yearly_generators.parquet`. The script is [`sql/03_pudl_create.sql`](../../open_data/parquet_csv/sql/03_pudl_create.sql). The table below is this record's original 2026-09-24 run. The `stable` object has since been replaced (it was 12,863 bytes on 12 Sep 2026). The [installation guide](updated_zetaris_installation_guide.md)'s Parquet/CSV walkthrough uses NOAA GHCN-Daily.

| Step | Result |
| --- | --- |
| Source check: `aws s3 ls --no-sign-request s3://pudl.catalyst.coop/stable/core_eia__codes_energy_sources.parquet` | The file exists (12,863 bytes, dated 12 Sep 2026) |
| `CREATE LIGHTNING DATABASE PUDL_S3 …` | Succeeded |
| `CREATE LIGHTNING FILESTORE TABLE pudl_eia_energy_sources …` with the options from `03_pudl_create.sql` | Succeeded (7.6 s) |
| `SELECT * FROM PUDL_S3.pudl_eia_energy_sources LIMIT 10` | Returned **10 rows** with columns `code`, `label`, `fuel_units`, …, `description`. The first rows were `AB` agricultural by-products, `ANT` anthracite coal, `BFG` blast furnace gas, `BIT` bituminous coal |

The test used `isS3BucketPublic "true"` with no AWS credentials configured on the host or in Zetaris, and the query returned 10 rows.

### §6 REST: PokéAPI

| Step | Result |
| --- | --- |
| `CREATE LIGHTNING DATABASE POKEAPI_REST …` | Succeeded |
| `CREATE SCHEMASTORE CONTAINER pokeapi` | Succeeded |
| `CREATE LIGHTNING REST TABLE pikachu_facts …` | Succeeded |
| `CREATE SCHEMASTORE VIEW pikachu_abilities_table …` | Succeeded |
| `SELECT * FROM pokeapi.pikachu_abilities_table LIMIT 10` | Returned **2 rows**: `static` (not hidden, slot 1) and `lightning-rod` (hidden, slot 3), with id 25, base experience 112, height 4, weight 60 |
| Running `CREATE SCHEMASTORE CONTAINER pokeapi` again | Failed with `A container named "pokeapi" already exists.` This matches the guide's warning that the recipe can't be re-run from the top |

### §7 Stop and tear down

| Step | Result |
| --- | --- |
| `docker compose stop`, then `start` | Passed |
| `docker compose down` | Containers were removed. All 4 named volumes were kept |
| `docker compose up -d` after `down` | Returned in 106 s. `bootstrap` skipped the existing accounts and TPC-H datasource, then exited 0 |
| Data after `down` / `up` | The PUDL and PokéAPI queries returned the same rows, and the administrator login still worked |
| `docker compose down -v` | Removed all 4 named volumes for the project |

### Memory used

Memory use by the Zetaris containers, from `docker stats`, with the local sizing profile:

| State | driver | api | ui | postgres | ai-datasteward | Total |
| --- | --- | --- | --- | --- | --- | --- |
| Idle after first start | 1.03 GiB | 0.50 GiB | 0.13 GiB | 0.10 GiB | 0.13 GiB | **≈ 1.9 GiB** |
| After the §5–§6 queries | 1.30 GiB | 0.63 GiB | 0.15 GiB | 0.11 GiB | 0.13 GiB | **≈ 2.3 GiB** |

These figures fit the preflight check's assumptions (6 GB minimum, 8 GB recommended). The test ran with 7.7 GiB given to Docker.
