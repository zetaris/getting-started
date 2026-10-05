# A query-to-chart example

**Current prerequisite warning:** PUDL registration is now [known to fail](../../open_data/parquet_csv/sql/known_to_fail/ISSUE-03-pudl.md). The earlier successful run is retained as historical evidence and has not been reconciled with the current failure. Do not use this example as default onboarding; first obtain a working registration verified on your target instance.


Use this after [the first-dataset guide](../../docs/guides/first-dataset.md) returns real rows. It uses the existing query helper, then renders its saved JSON as a local HTML chart. No new runtime dependencies or hosting account are required.

The chart counts **reference codes by fuel unit**. It does not measure generation or consumption. The SQL and renderer were checked locally; this example still needs acceptance against a real response from your deployment.

## 1. Configure and verify HTTP access

Follow [scripts/HOWTO.md](../../scripts/HOWTO.md), using your actual UI origin, numeric organization ID, and participant account. Choose Deno or Python; you do not need both.

Python users install the existing helper requirements with `python3 -m pip install -r scripts/requirements.txt`. The standalone renderer uses Python's standard library only.

## 2. Make a team query copy

Run from the repository root:

```sh
mkdir -p tmp/pudl-chart
cp examples/pudl-chart/query.sql tmp/pudl-chart/query.sql
```

Edit **the copied file** and replace `TEAM_07_PUDL` with the assigned database you actually verified. This is one complete statement. Do not submit a CREATE file containing several commands.

## 3. Execute and save the real response

Using Deno:

```sh
./scripts/query_zetaris.ts --file tmp/pudl-chart/query.sql > tmp/pudl-chart/result.json
```

Or using Python:

```sh
python3 scripts/query_zetaris.py --file tmp/pudl-chart/query.sql > tmp/pudl-chart/result.json
```

Require exit code 0 and inspect the JSON before rendering. If the query fails, resolve the error; a file created by shell redirection is not proof of success. `tmp/` is gitignored. The helpers default to a 1000-row return limit; verify the response is complete for your chosen aggregate rather than assuming the limit cannot truncate it.

## 4. Render locally

```sh
python3 examples/pudl-chart/render.py --input tmp/pudl-chart/result.json --output tmp/pudl-chart/chart.html
```

Open `tmp/pudl-chart/chart.html` in a browser. It is a static file; no server is needed. Credentials remain in the existing helper's local environment and are not included in the chart. Inspect real output before sharing it.

The renderer accepts a response object with a nonempty `data` array, either:

- Object rows with `fuel_units` and `code_count` keys, case-insensitive.
- Array rows with corresponding `headers`, where each header is a column-name string or an object containing `name`.

Counts must be nonnegative integers or integer strings. Fuel units may be strings or null. Other response formats fail visibly rather than being guessed. If your deployment uses another format, provide a redacted response to the maintainer before changing the adapter.

## Extend it

Change the question, then update the query, field validation, labels, and explanation together. Keep the row grain explicit. This example is a local result artifact, not an authenticated multi-user web app. A deployed app requires its own approved server-side access and user authentication design.

Include the actual SQL, source release, run date, and output in the [demo template](../../docs/guides/demo-template.md). Synthetic input can exercise the renderer but must not be presented as a live result.
