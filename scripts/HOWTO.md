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

Replace `123` with your actual numeric organization ID. The example number is not a working assignment. Set either `ZETARIS_API_TOKEN` or both username and password. When a token is set, the scripts use it directly. Otherwise, they log in with `POST /api/auth/login` and use the returned access token. Keep credentials in `.env`; do not commit that file.

`ZETARIS_BASE_URL` is the web UI origin. The default `http://localhost:3000` is for the local setup. The scripts use the UI's `/api/proxy/...` routes, so a raw Zetaris API address such as port 8888 is not a drop-in replacement.

## Find your organization ID

Ask the instance administrator for the numeric organization ID associated with your participant account. Do not infer it from the organization name or use the example number above.

If you are already signed in and the UI can make a successful data request, you can also open your browser's developer tools, use the Network panel, and inspect that request's headers. If it includes `X-Org-ID`, copy only that numeric value into your local `.env`. Do not copy or share Authorization/Cookie headers, tokens, or the full request. A request for a different organization is not a valid value for your account.

The repo does not document a guaranteed UI screen for this ID. If the header is absent or access is not confirmed, ask the administrator. Do not guess an API endpoint to obtain it. Only HTTP helpers require this field; you can use the SQL Editor while this is unresolved.

## Verify SQL execution

After configuration, run one of:

```sh
./scripts/query_zetaris.ts "SELECT 1"
python3 scripts/query_zetaris.py "SELECT 1"
```

Use your installed runtime. Python users first install `scripts/requirements.txt` as described in README. Require a result row containing `1`. The database-list check below verifies authenticated metadata access only. Next, follow [your first dataset](../docs/guides/first-dataset.md) to verify external rows.

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

The script accepts SQL text as one quoted argument or reads the entire file after `--file`. It sends that text in one request to Zetaris and prints the JSON response. It does not split a file into separate statements. `ZETARIS_QUERY_LIMIT` caps returned rows at 1000 by default. Set `ZETARIS_ENGINE_ID` when you want to choose a compute engine. Use a file containing one complete command. Multi-statement recipe files are not a supported automatic onboarding workflow here: execution may be rejected or stop partway through, and there is no helper-managed rollback. Preserve a complete USL compile payload as one command; do not split its internal table definitions.

## What the scripts send

[`check_zetaris.ts`](check_zetaris.ts) calls `/api/proxy/lightning-database/databases`. [`query_zetaris.ts`](query_zetaris.ts) posts the SQL, row limit, and optional engine ID to `/api/proxy/sql-editor/sqls/run-query`. Both use [`zetaris_api.ts`](zetaris_api.ts) for login, request headers, error handling, and the 30-second timeout.

SQL runs with your Zetaris account's permissions. Review the query before running it. If a request returns 404, check that `ZETARIS_BASE_URL` points to the web UI and that it exposes the proxy routes.

## Use a real result in a chart

The [PUDL chart example](../examples/pudl-chart/README.md) runs one aggregate query through these helpers, saves its response locally, and renders an HTML chart without putting credentials in browser code. Use your assigned team database and inspect the response before rendering.

For errors and partial setup, see [troubleshooting](../docs/guides/troubleshooting.md).
