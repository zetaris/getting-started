# Zetaris API scripts

These scripts connect to Zetaris through the local web UI's API proxy. The connection check confirms that your account can list its visible Lightning databases, and the query script runs SQL as your Zetaris account. Use Deno 2.9 or later and run the commands below from the repository root.

## Configure access

Add these settings from [`../.env.example`](../.env.example) to the repository's `.env` file. If `.env` already exists, add the settings without replacing its other values.

```dotenv
ZETARIS_BASE_URL=http://localhost:3000
ZETARIS_ORG_ID=123
ZETARIS_API_TOKEN=
ZETARIS_USERNAME=
ZETARIS_PASSWORD=
ZETARIS_QUERY_LIMIT=1000
ZETARIS_ENGINE_ID=
```

Replace `123` with your numeric organization ID. Set either `ZETARIS_API_TOKEN` or both username and password. When a token is set, the scripts use it directly. Otherwise, they log in with `POST /api/auth/login` and use the returned access token. Keep credentials in `.env`; do not commit that file.

`ZETARIS_BASE_URL` is the web UI origin. The default `http://localhost:3000` is for the local setup. The scripts use the UI's `/api/proxy/...` routes, so a raw Zetaris API address such as port 8888 is not a drop-in replacement.

## How a request works

Each script loads `.env` from the repository root. The shared [`zetaris_api.ts`](zetaris_api.ts) helper checks the base URL and numeric organization ID, then gets an access token. It uses `ZETARIS_API_TOKEN` when set; otherwise it sends the username and password to the UI login route with a fresh `X-Request-ID`. Authenticated proxy requests include the bearer token, `X-Org-ID`, and another fresh `X-Request-ID`. Requests time out after 30 seconds.

## Check the connection

```sh
./scripts/check_zetaris.ts
```

This calls the Lightning database list endpoint and reports how many databases are visible to your account. It does not submit SQL.

## Run a query

Pass SQL in quotes:

```sh
./scripts/query_zetaris.ts "SELECT 1"
```

Or pass a SQL file:

```sh
./scripts/query_zetaris.ts --file path/to/query.sql
```

The script accepts SQL text as one quoted argument or reads the entire file after `--file`. It sends that text in one request to Zetaris and prints the JSON response. It does not split a file into separate statements. `ZETARIS_QUERY_LIMIT` caps returned rows at 1000 by default. Set `ZETARIS_ENGINE_ID` when you want to choose a compute engine. If the API rejects a file with multiple statements, pass one statement at a time.

## What the scripts send

[`check_zetaris.ts`](check_zetaris.ts) calls `/api/proxy/lightning-database/databases`. [`query_zetaris.ts`](query_zetaris.ts) posts the SQL, row limit, and optional engine ID to `/api/proxy/sql-editor/sqls/run-query`. Both use [`zetaris_api.ts`](zetaris_api.ts) for login, request headers, error handling, and the 30-second timeout.

SQL runs with your Zetaris account's permissions. Review the query before running it. If a request returns 404, check that `ZETARIS_BASE_URL` points to the web UI and that it exposes the proxy routes.

## Warm up company_dns

[`warmup_company_dns.ts`](warmup_company_dns.ts) is unrelated to the Zetaris API scripts above — it talks to `company_dns` directly, not to Zetaris. Its hosted instance (`https://company-dns.mediumroast.io`) can return an empty response or an HTTP 502 on the first request after a period of no traffic; this script polls its `/health` endpoint until the service is warm, then pre-hits the SIC bulk endpoint so Zetaris's own `CREATE LIGHTNING REST TABLE` request lands on an already-warm backend. Run it before `open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql` — see that file's own header and `open_data/rest_apis/HOWTO.md`'s Fast Start.

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
