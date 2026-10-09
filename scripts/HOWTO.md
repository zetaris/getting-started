# Repository scripts

Helpers for talking to Zetaris and PostgreSQL directly from the command line, plus two standalone data-fetching scripts for the Parquet/CSV package. The Zetaris/PostgreSQL helpers are available in both Deno/TypeScript and Python — both versions load `.env.local`, preserve values already exported in the shell, use the same environment variables, and provide the same checks and query behavior. Run every command below from the repository root.

## Configure access

Copy the settings you need from [`../.env.example`](../.env.example) into `.env.local` in the repository root. `.env.local` is the only env file the scripts read, and it is gitignored — do not commit it. If you have an older client `.env`, migrate its settings into `.env.local` without replacing an existing file. The platform bundle’s `.env` is separate. If `.env.local` already exists, add the settings without replacing its other values.

**Git worktrees.** A gitignored file is not copied into a worktree, so you do not need a copy there: every script (Python and Deno) looks for `.env.local` in the repository root first and then in the top-level checkout the worktree belongs to. Variables already exported in your shell win over the file.

For the Zetaris scripts:

```dotenv
ZETARIS_BASE_URL=http://localhost:3000
ZETARIS_ORG_ID=123
ZETARIS_API_KEY=
ZETARIS_USERNAME=
ZETARIS_PASSWORD=
ZETARIS_QUERY_LIMIT=1000
ZETARIS_ENGINE_ID=
```

Replace `123` with your numeric organization ID. Set either `ZETARIS_API_KEY` or both username and password. When a token is set, the scripts use it directly. Otherwise, they log in with `POST /api/auth/login` and use the returned access token.

`ZETARIS_BASE_URL` is the web UI origin. The default `http://localhost:3000` is for the local setup. The scripts use the UI's `/api/proxy/...` routes, so a raw Zetaris API address such as port 8888 is not a drop-in replacement.

For the PostgreSQL connection check:

```dotenv
PGHOST=
PGPORT=5432
PGDATABASE=
PGUSER=
PGPASSWORD=
PGSSLMODE=disable
```

Set `PGHOST` to your server IP or hostname, then fill in the rest. Quote passwords containing spaces or `#`. Set `PGSSLMODE=verify-full` if your server uses TLS with a trusted certificate matching the host; the default, `disable`, is for servers without TLS. Exported environment variables take precedence over `.env.local` values.

## Find your organization ID

Use the numeric organization ID associated with your participant account. Do not infer it from the organization name or use the example number above.

If you are already signed in and the UI can make a successful data request, you can also open your browser's developer tools, use the Network panel, and inspect that request's headers. If it includes `X-Org-ID`, copy only that numeric value into your local `.env.local`. Do not copy or share Authorization/Cookie headers, tokens, or the full request. A request for a different organization is not a valid value for your account.

The repo does not document a guaranteed UI screen for this ID. If the header is absent or access is not confirmed, use the SQL Editor until you have a verified ID. Do not guess an API endpoint to obtain it. Only HTTP helpers require this field; you can use the SQL Editor while this is unresolved.

## Verify SQL execution

After configuration, run one of:

```sh
./scripts/query_zetaris.ts "SELECT 1"
python3 scripts/query_zetaris.py "SELECT 1"
```

Use your installed runtime. Python users first install `scripts/requirements.txt` as described in README. Require a result row containing `1`. The database-list check below verifies authenticated metadata access only. Next, follow [your first dataset](../docs/guides/first-dataset.md) to verify external rows.

## How a request works

Each script loads `.env.local` (repository root, or the top-level checkout from a worktree). The shared helper (`zetaris_api.ts` or `zetaris_api.py`) checks the base URL and numeric organization ID, then gets an access token. It uses `ZETARIS_API_KEY` when set; otherwise it sends the username and password to the UI login route with a fresh `X-Request-ID`. Authenticated proxy requests include the bearer token, `X-Org-ID`, and another fresh `X-Request-ID`. Requests time out after 30 seconds. Both language versions enforce the same validation and timeouts.

## Check readiness and run SQL scripts (REST or JDBC)

`preflight.py` and `run_sql.py` use the documented REST API (`ZETARIS_REST_URL`, default `http://localhost:8888/api/v1.0`) or JDBC, not the UI proxy used by the scripts below. They read `.env.local` the same way. Standard library only; JDBC also needs a JDK and `jaydebeapi` (`python3 -m venv .venv && .venv/bin/pip install -r scripts/requirements.txt`). They hop into `.venv` automatically for JDBC.

```sh
python3 scripts/preflight.py            # env, REST, instance state
python3 scripts/preflight.py --jdbc --jar /path/to/driver.jar
python3 scripts/run_sql.py --dry-run open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql
python3 scripts/run_sql.py open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql
python3 scripts/run_sql.py --channel jdbc -e "SELECT 1"
```

- **`preflight.py`** is read-only and exits 1 if anything fails. It checks credentials are set (never printing them), REST (`GET /datasource/datasources` and `SELECT 1`), optionally JDBC (port, JDK, `jaydebeapi`, driver JAR), and lists what is on the instance, including Lightning databases and USL namespaces that `SHOW DATASOURCES` omits. It installs nothing.
- **`run_sql.py`** splits a script into statements (quote- and comment-aware), sends them one at a time, and stops at the first error. A multi-table `COMPILE USL` is kept whole. It replaces the `YOUR_APP_NAME YOUR_CONTACT_EMAIL` placeholder with `ZETARIS_USER_AGENT` and refuses to send the placeholder. `--skip-exists` skips "already exists" errors; inspect ownership and matching definitions first, especially on a shared instance. `--dry-run` prints the statements without connecting. The create scripts change the instance, so dry-run first if unsure.
- **JDBC driver JAR:** pass `--jar` or set `ZETARIS_JDBC_JAR`. The scripts never guess a location. JDBC reuses `ZETARIS_USERNAME` and `ZETARIS_PASSWORD`. On macOS the `java` on `PATH` can be a stub, so they look for a Homebrew JDK (for example `brew install openjdk@17`, which needs no `sudo`).

### Onboard sources with their dependencies

`onboard.py` reads `open_data/manifest.json`, where each source and USL model declares the sources it `requires`, and runs create scripts in dependency order. The same mechanism covers any source or USL model; add a new one to the manifest and it works the same way.

```sh
python3 scripts/onboard.py --list                          # every source, status, dependencies
python3 scripts/onboard.py --check                         # validate the manifest against the repo
python3 scripts/onboard.py plan sic_edgar_usl              # the resolved order, dependencies first
python3 scripts/onboard.py run sic_edgar_usl --dry-run     # plan plus statement counts, nothing sent
python3 scripts/onboard.py run company_dns pokeapi         # run several; shared dependencies run once
```

Dependencies that already exist are satisfied: a duplicate "already exists" error on a dependency is skipped. The sources you name only skip duplicates with `--skip-exists`. It stops at the first real error and says which source and statement. A source marked `known_to_fail` needs `--allow-known-to-fail`. `--channel jdbc` and `--jar` work as in `run_sql.py`. USL models re-run less predictably than REST sources (re-running `ACTIVATE USL TABLE` is not verified), so run a USL model once and use `REMOVE USL` first if you need to rebuild it.

### Tear down and start over

`teardown` reverses an onboarding. It derives the drops from each create script, so there is nothing extra to maintain in the manifest: `DROP VIEW` for each schemastore view, `UNCACHE TABLE` for each cache, and `REMOVE USL` for each USL. It also tears down every source that `requires` the ones you name, dependents first, because dropping `company_dns` would otherwise leave a USL pointing at nothing.

```sh
python3 scripts/onboard.py teardown sic_edgar_usl                 # plan only, nothing sent
python3 scripts/onboard.py teardown sic_edgar_usl --verbose       # plan plus every statement
python3 scripts/onboard.py teardown sic_edgar_usl --yes --channel jdbc --jar <jar>
python3 scripts/onboard.py teardown company_dns --no-dependents   # only the named source
python3 scripts/onboard.py teardown sic_edgar_usl --drop-namespace --yes   # also DROP NAMESPACE ... CASCADE
```

- Nothing is sent without `--yes`. Show the plan to the user and wait for a go-ahead first.
- Drops are idempotent: an object that is already gone is reported as `absent`, not as a failure.
- The USL namespace (`lightning.metastore.usl_demo`) is left alone unless you pass `--drop-namespace`, which removes every USL inside it.
- SQL cannot remove REST and file tables, Lightning databases or schemastore containers. The command lists them at the end; remove them in the Zetaris Data Explorer, then re-onboard with `run <id>... --skip-exists`. If you leave them in place, `--skip-exists` is what lets a re-run proceed.
- Statements are derived from the create script's statement shapes. If you add a new statement type to a create script, check the `teardown <id> --verbose` plan still covers it.

## Check the Zetaris connection

```sh
./scripts/check_zetaris.ts
python3 scripts/check_zetaris.py
```

This calls the Lightning database list endpoint and reports how many databases are visible to your account. It does not submit SQL.

## Run a Zetaris query

Pass SQL in quotes:

```sh
./scripts/query_zetaris.ts "SELECT 1"
python3 scripts/query_zetaris.py "SELECT 1"
```

Or pass a SQL file:

```sh
./scripts/query_zetaris.ts --file path/to/query.sql
python3 scripts/query_zetaris.py --file path/to/query.sql
```

The script accepts SQL text as one quoted argument or reads the entire file after `--file`. It sends that text in one request to Zetaris and prints the JSON response (`headers`, `data`, `total`, `timeUsed`). It does not split a file into separate statements and does not manage transaction rollback. Use one complete command per file/request with this helper. For multi-command files, use the separate `run_sql.py` runner described above; it keeps USL compile payloads intact. Resume partial setup only after inspecting existing objects. `ZETARIS_QUERY_LIMIT` caps returned rows at 1000 by default. Set `ZETARIS_ENGINE_ID` when you want to choose a compute engine. SQL runs with your Zetaris account's permissions, so review a file before passing it to the command.

For the TypeScript versions: each script's first line supplies the Deno flags, including network and read permission (the scripts load `.env.local` themselves through `load_env.ts`), and uses `--no-config` to avoid loading the separate PostgreSQL driver. If direct execution is unavailable, run `deno run --no-config --allow-net --allow-env='ZETARIS*' --allow-read scripts/check_zetaris.ts` instead.

## What the Zetaris scripts send

`check_zetaris.*` calls `/api/proxy/lightning-database/databases`. `query_zetaris.*` posts the SQL, row limit, and optional engine ID to `/api/proxy/sql-editor/sqls/run-query`. Both use the shared `zetaris_api.*` helper for login, request headers, error handling, and the 30-second timeout.

If a request returns 404, check that `ZETARIS_BASE_URL` points to the web UI and that it exposes the proxy routes.

API contract: [Zetaris API reference](http://localhost:8888/redoc/index.html#tag/SQL-Editor). The UI on port 3000 proxies the documented `/api/v1.0/...` endpoints under `/api/proxy/...`.

## Check a PostgreSQL connection

```sh
deno task ping:postgres
python3 scripts/ping_postgres.py
```

The script authenticates and runs `SELECT 1`, reports elapsed time, then closes the connection. It exits with code 1 on failure. Connection and server-side query timeouts are 10 seconds. This checks database access, not ICMP ping. It uses the [Postgres.js driver](https://github.com/porsager/postgres) (TypeScript) or Psycopg (Python).

## Running the Deno/TypeScript scripts

Use [Deno](https://deno.com/agents.md) 2.9 or later. Check your installation with `deno --version`. Deno downloads script dependencies on first use; `deno.lock` pins their versions.

```sh
deno task check
deno task lint
deno task ping:postgres
deno task warmup:company-dns
```

Or invoke a script directly, as shown in the sections above — each one's shebang line carries its own permission flags.

## Running the Python scripts

Python 3.9 or later is required. Install the environment-file loader and the Psycopg PostgreSQL driver with:

```sh
python3 -m pip install -r scripts/requirements.txt
```

Then run any of `check_zetaris.py`, `query_zetaris.py`, or `ping_postgres.py` as shown above.

## Warm up company_dns

[`warmup_company_dns.ts`](warmup_company_dns.ts) is unrelated to the Zetaris API scripts above — it talks to `company_dns` directly, not to Zetaris, and has no Python equivalent. Its hosted instance (`https://company-dns.mediumroast.io`) can return an empty response or an HTTP 502 on the first request after a period of no traffic; this script polls its `/health` endpoint until the service is warm, then pre-hits the SIC bulk endpoint so Zetaris's own `CREATE LIGHTNING REST TABLE` request lands on an already-warm backend. Run it before `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql` — see that file's own header and `open_data/rest_apis/HOWTO.md`'s Fast Start.

```sh
deno run --allow-net --allow-env scripts/warmup_company_dns.ts
```

For a self-hosted instance, set the URL and grant access to its host explicitly:

```sh
COMPANY_DNS_BASE_URL=http://localhost:8000 deno run --allow-net --allow-env=COMPANY_DNS_BASE_URL scripts/warmup_company_dns.ts
```

Or use the pinned-permission Deno task instead of raw flags:

```sh
deno task warmup:company-dns
```

## Fetch local data files for the Parquet/CSV package

[`fetch_datagovsg.py`](fetch_datagovsg.py) and [`fetch_openfoodfacts.py`](fetch_openfoodfacts.py) are also unrelated to the Zetaris API scripts above — they're plain stdlib-only Python downloaders for two `open_data/parquet_csv/` candidate sources that don't have a Zetaris SQL registration yet (see that package's [HOWTO.md section 3](../open_data/parquet_csv/HOWTO.md#3-sources-that-need-a-local-fetch-step-first)), and have no TypeScript equivalent. Both save into `tmp/cache/<source>/` at the repo root — gitignored, never commit what lands there. Run them from the repository root with any Python 3.8+:

```sh
python3 scripts/fetch_datagovsg.py
python3 scripts/fetch_openfoodfacts.py --sample-rows 5000
```

Each script prints the attribution line its source's license requires (SODL for data.gov.sg, ODbL for Open Food Facts) on completion — copy it into whatever you publish. See each script's own module docstring and the Parquet/CSV HOWTO for full usage, caveats, and current limitations (neither source has a Zetaris table registration yet).

## Render a saved result

The [PUDL chart example](../examples/pudl-chart/README.md) is retained as a conditional example for an already verified PUDL table. PUDL registration is currently known to fail; do not use it as the default starter. See [troubleshooting](../docs/guides/troubleshooting.md) for connection and partial-setup recovery.
