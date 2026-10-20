# Zetaris client setup

Choose JDBC or REST below to see the setup for your connection.

<a id="1-choose-a-protocol"></a>

<!-- protocol: jdbc -->

Use JDBC to run Lightning SQL through the Zetaris Java driver. You need your
Zetaris user ID and password, JDK 11 or later and the matching driver JAR.
For a remote instance, use the JDBC URL supplied to you.

## 2. Set up `.env.local`

Copy the needed settings from [`.env.example`](../../.env.example) into
`.env.local` at the repository root. If the file already exists, add settings
without replacing its other values. Scripts also find the top-level checkout's
`.env.local` when run from a Git worktree.

Keep passwords and API keys in this local, gitignored file. Never put them in
a prompt, source file, command output or URL.

| Variable | Set it to |
|---|---|
| `ZETARIS_JDBC_URL` | `jdbc:zetaris:lightning@localhost:10000` locally, or the supplied JDBC URL |
| `ZETARIS_JDBC_JAR` | Full path to the matching Zetaris driver JAR. If unset, provide the path when asked; scripts do not search for it. |
| `ZETARIS_USERNAME` | Your Zetaris user ID |
| `ZETARIS_PASSWORD` | Your Zetaris password |
| `ZETARIS_USER_AGENT` | Your app name and contact email, only for create scripts that call external APIs. SEC EDGAR requires a real contact. |

## 4. Prepare JDBC

To connect with JDBC, you need Java 11 or later, the Zetaris driver file (a
`.jar` file), and your Zetaris username and password. The driver must match
your Zetaris instance. Get its full file path from whoever supplied the driver;
the setup scripts do not search for it.

On macOS, the `java` command may not find an installed Java runtime. If that
happens, check `/usr/libexec/java_home` or the Homebrew JDK location
`/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`, then set
`JAVA_HOME` to the JDK folder. The preflight finds a Java path but does not
check its version. Confirm it with:

```sh
"$JAVA_HOME/bin/java" -version
```

To check your setup, run this read-only preflight from the repository folder:

```sh
python3 scripts/preflight.py --jdbc --jar "/full/path/to/your/zetaris-driver.jar"
```

Replace the example path with the actual path to your driver file. The
preflight installs nothing and does not change your Zetaris instance. It also
checks REST, so read the JDBC results separately; a REST problem by itself does
not mean JDBC is unavailable.

The repository's Python SQL runner also needs a local Python environment
(`.venv`) and the `jaydebeapi` package. If either is missing, that runner is
not ready. A direct Java JDBC connection does not need these Python components.
Ask before installing missing software or packages.

If a local port check says `Operation not permitted`, Codex may be blocked from
accessing your computer's local network. That result does not show that the
port is closed or that the JDBC URL is wrong. Retry the same read-only check
with network access, or run it in a terminal that can reach Zetaris. For a
remote instance, use its supplied host and port; `localhost` refers to the
machine running the JDBC client.

If Java is missing, ask before installing it. If JDBC is unavailable, use REST
if your account has access.

## 5. JDBC starter prompt

Set the JDBC values in `.env.local`, then submit this as the first instruction.
Replace the goal with your task.

```text
Read AGENTS.md and follow it. Run python3 scripts/preflight.py --jdbc and show
me the result. Report JDBC and REST checks separately. Stop on JDBC failures and report
what is missing. REST failures alone do not block JDBC. If the driver JAR path is not set, ask me
for it. Once readiness checks pass, connect over JDBC to the instance
configured in .env.local and confirm with SELECT 1 and SHOW LIGHTNING DATABASES.

If a local port check returns `Operation not permitted`, retry the same
read-only check with approved network access before reporting the endpoint as
closed. Distinguish missing Python runner dependencies (`.venv` or
`jaydebeapi`) from direct Java JDBC readiness; do not install dependencies
without asking.

Goal: <for example: list NY_TAXI and TPCDS_DB tables, then read 5 rows from
NY_TAXI.taxi_zones; keep it read-only>

Dry-run before creating anything and wait for my go-ahead.
```

## 7. Verify access

Run the JDBC preflight shown above and read its JDBC result separately from
its REST result. The script also runs REST checks, but a missing REST key or
unreachable REST service alone does not block a JDBC connection.

`SELECT 1` should return `1`. `SHOW LIGHTNING DATABASES` shows the instance's
Lightning databases; an empty list is normal on a clean instance.

`SHOW DATASOURCES` lists sources registered with `CREATE DATASOURCE`. Use
`SHOW LIGHTNING DATABASES` for REST and file sources.

## 8. Safety and permissions

- Start with read-only commands such as `SHOW`, `DESCRIBE`, and `SELECT`.
- Use your own local or AWS Zetaris instance. Check that an existing object
  matches the recipe definition before reusing it.
- Creating, dropping, granting, or writing changes the instance. Preview
  create scripts with `--dry-run` and wait for the user's clear go-ahead before
  running them.
- Send one Lightning SQL statement per call. Keep a multi-table `COMPILE USL`
  together as one statement; do not split it at semicolons.
- Keep credentials out of prompts, logs, source files, and commits.

## 10. Troubleshooting

| Symptom | Check |
|---|---|
| `Unable to locate a Java Runtime` | Find a JDK and set `JAVA_HOME`. Ask before installing one. |
| Driver JAR missing or `ClassNotFoundException` | Set the full path to the matching driver JAR. Do not guess a path. |
| `externally-managed-environment` from `pip` | Use the repository's `.venv`; do not install packages into system Python. |
| REST checks fail during JDBC preflight | Read the JDBC result separately. A REST failure alone does not mean JDBC is unavailable. |
| A source is missing from `SHOW DATASOURCES` | Check `SHOW LIGHTNING DATABASES`; REST and file registrations appear there. |
| `Table not found` | Use the qualified name `<source>.<table>`. |
| JDBC `mismatched input ... expecting` | Send one statement per call. The `run_sql.py` runner splits scripts and keeps `COMPILE USL` intact. |

For JDBC script options, see [`scripts/HOWTO.md`](../../scripts/HOWTO.md).

<!-- protocol: rest -->

Use REST to run SQL or call platform endpoints over HTTP. No Java runtime or
JDBC driver is needed. Choose the route used by your client:

| Route | Endpoint | Authentication |
|---|---|---|
| Direct REST API | API base at `/api/v1.0` | User-created API key, organisation ID and request ID |
| UI proxy | Web UI origin, calls to `/api/proxy/...` | API key, or UI login with user ID and password |

For Zetaris Cloud or another remote instance, use the URLs supplied to you.
The routes use separate addresses: put the API base in `ZETARIS_REST_URL` and
the web UI origin in `ZETARIS_BASE_URL`.

For a local install, browse the available endpoints in the
[REST API docs](http://localhost:8888/redoc/index.html). Scripts use the
separate API base `http://localhost:8888/api/v1.0`; the docs page is not the
API base.

## 2. Set up `.env.local`

Copy the needed settings from [`.env.example`](../../.env.example) into
`.env.local` at the repository root. If the file already exists, add settings
without replacing its other values. Scripts also find the top-level checkout's
`.env.local` when run from a Git worktree.

Keep passwords and API keys in this local, gitignored file. Never put them in
a prompt, source file, command output or URL.

| Variable | Used by | Set it to |
|---|---|---|
| `ZETARIS_REST_URL` | Direct REST | API base ending in `/api/v1.0`; local default is `http://localhost:8888/api/v1.0` |
| `ZETARIS_ORG_ID` | Both routes | Numeric **ID** under **Management → Organisation**. See [Find your organisation ID](#3-find-your-organisation-id). |
| `ZETARIS_API_KEY` | Both routes | API key you create in the Zetaris GUI |
| `ZETARIS_BASE_URL` | UI-proxy helpers | Web UI origin, such as `http://localhost:3000`; no path after the origin |
| `ZETARIS_USERNAME` | OpenAPI spec, optional UI-proxy login | Your Zetaris user ID |
| `ZETARIS_PASSWORD` | OpenAPI spec, optional UI-proxy login | Your Zetaris password |
| `ZETARIS_QUERY_LIMIT` | UI-proxy query helper | Positive row limit; defaults to `1000` |
| `ZETARIS_ENGINE_ID` | UI-proxy query helper | Optional compute engine ID |
| `ZETARIS_USER_AGENT` | Create scripts that call external APIs | Your app name and contact email. SEC EDGAR requires a real contact. |

### Create an API key

1. Sign in to the Zetaris UI with your account.
2. In the sidebar, open **Management → API Tokens**.
3. Click the **+** button at the top right to create an API key.
4. Copy the key when it is shown and save it as `ZETARIS_API_KEY` in `.env.local`.

Each key is shown in plaintext only once. The key has your account's
permissions. Never ask an agent to create or fetch it, and do not paste it
into a prompt. If REST returns `401`, create a fresh key on this page and
update the local value.

The UI-proxy helpers can use that API key directly. If it is not set, they can
log in with both `ZETARIS_USERNAME` and `ZETARIS_PASSWORD`. Direct REST uses the
bearer key.

## 3. Find your organisation ID

1. Sign in to the Zetaris UI.
2. In the sidebar, open **Management → Organisation**.
3. Copy the numeric value in the **ID** field into `ZETARIS_ORG_ID` in `.env.local`.

Use the **ID**, not the organisation name or login URL slug. For example, if
the ID field shows `1`, set `ZETARIS_ORG_ID=1`. Use the value shown for your
organisation.

If you cannot access this page, ask your organiser or administrator for the
numeric organisation ID. Direct REST and the UI-proxy helpers require this
setting.

## 6. REST starter prompt

Create your API key and set the REST values in `.env.local` first. Then submit
this as the first instruction.

```text
Read AGENTS.md and follow it. Run python3 scripts/preflight.py and show me the
result. Then connect over REST to the instance configured in .env.local and
confirm with SELECT 1 and SHOW LIGHTNING DATABASES.

Goal: <for example: list NY_TAXI and TPCDS_DB tables, then read 5 rows from
NY_TAXI.taxi_zones; keep it read-only>

Dry-run before creating anything and wait for my go-ahead.
```

## 7. Verify access

For direct REST, run the read-only preflight:

```sh
python3 scripts/preflight.py
```

It checks `GET /datasource/datasources`, `SELECT 1` and the instance's
Lightning databases.

`SELECT 1` should return `1`. `SHOW LIGHTNING DATABASES` shows the instance's
Lightning databases; an empty list is normal on a clean instance.

`SHOW DATASOURCES` lists sources registered with `CREATE DATASOURCE`. Use
`SHOW LIGHTNING DATABASES` for REST and file sources.

REST returns values as strings, and decimals may use exponent format;
convert them before comparing.

### Verify the UI proxy

The small `query_zetaris` and `check_zetaris` helpers use the UI proxy. Choose
Python or Deno; each example runs one query:

```sh
./scripts/query_zetaris.ts "SELECT 1"
python3 scripts/query_zetaris.py "SELECT 1"
```

These use `ZETARIS_BASE_URL`, not the direct REST URL. A successful direct REST
preflight does not verify the UI-proxy route.

## 8. Safety and permissions

- Start with read-only commands such as `SHOW`, `DESCRIBE`, and `SELECT`.
- Use your own local or AWS Zetaris instance. Check that an existing object
  matches the recipe definition before reusing it.
- Creating, dropping, granting, or writing changes the instance. Preview
  create scripts with `--dry-run` and wait for the user's clear go-ahead before
  running them.
- Send one Lightning SQL statement per call. Keep a multi-table `COMPILE USL`
  together as one statement; do not split it at semicolons.
- Keep credentials out of prompts, logs, source files, and commits.

## 9. Fetch the OpenAPI specification

Fetch a fresh specification when you need a direct REST endpoint. The spec
route uses HTTP Basic authentication with `ZETARIS_USERNAME` and
`ZETARIS_PASSWORD`. It does not accept the bearer API key. Save the spec
outside the repository because it may contain environment-specific details.

```sh
set -a
. ./.env.local
ZETARIS_REST_URL="${ZETARIS_REST_URL:-http://localhost:8888/api/v1.0}"
set +a
curl -sS -u "$ZETARIS_USERNAME:$ZETARIS_PASSWORD" \
  "${ZETARIS_REST_URL%/api/v1.0}/redoc/docs.yaml" \
  -o /tmp/zetaris-docs.yaml
```

For a local instance this fetches `http://localhost:8888/redoc/docs.yaml`.
For a remote instance, `ZETARIS_REST_URL` must point to its `/api/v1.0` API
base. Do not print or echo the credentials.

## 10. Troubleshooting

| Symptom | Check |
|---|---|
| REST `401` | For direct REST, create a new GUI API key and update `ZETARIS_API_KEY`. The spec route needs Basic auth, not the bearer key. |
| REST `400 Not Allowed` | Check that `ZETARIS_ORG_ID` is the numeric ID for your account. |
| REST `400` on a valid request | Check that `X-Request-ID` and `queryId` are UUIDs. |
| REST preflight says `Operation not permitted` for localhost | The command environment may be blocking local network access before an HTTP response. In Codex, retry the read-only command with the requested network or elevated execution permission if offered. Do not change the API path or key based on this error. If permission cannot be granted, run the command in a terminal that can reach the Zetaris instance. |
| UI-proxy helper cannot connect | Set `ZETARIS_BASE_URL` to the web UI origin, not the direct API address. |
| A source is missing from `SHOW DATASOURCES` | Check `SHOW LIGHTNING DATABASES`; REST and file registrations appear there. |
| `Table not found` | Use the qualified name `<source>.<table>`. |

For script-specific setup and the difference between one-request helpers and
multi-statement runners, see [`scripts/HOWTO.md`](../../scripts/HOWTO.md).
