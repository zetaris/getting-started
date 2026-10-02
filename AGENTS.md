# Agent instructions

This repo is a set of tested onboarding material for Zetaris: install guide, `open_data/` source packages (`*_create.sql` / `*_select.sql` pairs), helper scripts in `scripts/`, and SQL references in `docs/guides/`. You are acting as a data engineer against a Zetaris instance.

## Connect first

The user's first prompt names a protocol (JDBC or REST) and a goal. Which instance you talk to is set in `.env.local` (`ZETARIS_REST_URL`, `ZETARIS_JDBC_URL` and the rest; local is the default), not in the prompt. Before running anything else, read the connection guide for your harness in `docs/connections/` (`claude-code-connection.md`, `codex-connection.md`, `cursor-connection.md`) for the settings table and troubleshooting, run the preflight below, and confirm the connection with `SELECT 1` and `SHOW LIGHTNING DATABASES`. Over REST, also call `GET /datasource/datasources`. Then work on the user's goal.

- **JDBC:** use `ZETARIS_JDBC_JAR` if set; otherwise ask the user for the full path to the driver JAR. Do not assume or search for it.
- **REST:** the key is `ZETARIS_API_KEY` in `.env.local`, created by the user in the Zetaris GUI. Never create, request, print, log or put it in a URL.
- **OpenAPI spec:** fetch it fresh from `/redoc/docs.yaml` using Basic auth (`ZETARIS_USERNAME` and `ZETARIS_PASSWORD` from `.env.local`), not the bearer key. See section 6.4 of the connection guide.
- **Finding `.env.local`:** it is the only env file; do not use `.env`. It is gitignored, so a git worktree has none. Every script in `scripts/` (Python and Deno) already looks in the repo root and then the top-level checkout. For your own shell commands, use the snippet in the preflight section.

## Preflight check

Run this before any Zetaris work in a new session, and report what is missing. Do not install anything, create credentials, or start work until the user has seen the result. Ask before installing.

Run `python3 scripts/preflight.py` (add `--jdbc --jar <path>` for JDBC). It is read-only and covers the checklist below; the list is what it checks and why. Run SQL files with `python3 scripts/run_sql.py FILE` (`--dry-run` first, `--skip-exists` to re-run, `--channel jdbc` for JDBC); see `scripts/HOWTO.md`.

1. **Credentials.** Find `.env.local` (see "Connect first"). Check that these names are set, without printing values: `ZETARIS_API_KEY` for REST, and `ZETARIS_USERNAME` / `ZETARIS_PASSWORD` for the OpenAPI spec and for JDBC. Also note `ZETARIS_JDBC_JAR` (driver path, JDBC only) and `ZETARIS_USER_AGENT` (needed by any create script containing the `YOUR_APP_NAME YOUR_CONTACT_EMAIL` placeholder).
   ```bash
   ENV="$(dirname "$(cd "$(git rev-parse --git-common-dir)" && pwd)")/.env.local"
   set -a; . "$ENV"; set +a
   for v in ZETARIS_API_KEY ZETARIS_USERNAME ZETARIS_PASSWORD; do [ -n "$(printenv "$v")" ] && echo "$v set" || echo "$v MISSING"; done
   ```
2. **REST.** `GET /datasource/datasources` returns 200, and `SELECT 1` through `/sql-editor/sqls/run` returns `1`. A 401 means a bad key; a 400 means a bad `X-Org-ID` or a non-UUID `X-Request-ID`.
3. **JDBC** (only if the user wants JDBC):
   - **Endpoint:** `nc -z localhost 10000` succeeds.
   - **Java:** JDK 11 or later. On macOS `java` can be a stub that reports "Unable to locate a Java Runtime" even when a Homebrew JDK exists. Check `/usr/libexec/java_home`, then `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`, and export `JAVA_HOME`. If none exists, offer `brew install openjdk@17`. The `temurin` cask needs `sudo`, which the agent cannot enter.
   - **Python:** a venv (`.venv` is gitignored) with `jaydebeapi` importable.
   - **Driver JAR:** ask the user for the full path and confirm the file exists. Never assume a location.
   - **Query:** connect with `jdbc:zetaris:lightning@localhost:10000` and class `com.zetaris.lightning.jdbc.LightningDriver`, then run `SELECT 1`.
4. **Instance state.** `SHOW DATASOURCES` does not list Lightning-registered sources (REST, file). Also run `SHOW LIGHTNING DATABASES`. For USL, run `SHOW NAMESPACES OR TABLES IN lightning.metastore`; an empty result is normal on a clean instance, but a failing `CREATE NAMESPACE` on a missing parent means `lightning.metastore` is not initialised (see the USL note under "Writing SQL").
5. **Report** a short pass/fail list, and stop on any failure.

## Writing SQL

- Zetaris Lightning SQL only. Not Spark SQL or Hive SQL, and never start a local Spark session.
- One statement per call, no trailing semicolon, qualified names (`<source>.<table>`). A `_create.sql` script holds many statements; `scripts/run_sql.py` splits and sends them for you.
- **USL:** `lightning.metastore` must exist before `CREATE NAMESPACE IF NOT EXISTS lightning.metastore.<name>` works; check with `SHOW NAMESPACES OR TABLES IN lightning.metastore` (on an uninitialised instance the statement fails with "parent namespace : metastore is not existing"). A multi-table `COMPILE USL` must be sent as one whole statement, so do not split it on `;`. It works over JDBC and REST that way. Use `SHOW DQ ALL INVALID TABLE <namespace.usl.table>` (the `TABLE` clause is required).
- Read `docs/guides/zetaris-lightning-sql-commands.md` for syntax and `docs/guides/zetaris-lightning-sql-companion.md` for confirmed gotchas and platform limitations before writing new SQL.

## Running scripts

Use `scripts/onboard.py` to onboard sources and USL models with their dependencies, and `scripts/run_sql.py` to run any single `_create.sql` / `_select.sql` file or ad hoc SQL. Do not hand-roll a splitter. See `scripts/HOWTO.md` for options.

- **Dry-run first** (`--dry-run`) and show the user the statement list. Create scripts change the instance, so get a clear go-ahead before running one for real.
- **User-agent.** Never send the `YOUR_APP_NAME YOUR_CONTACT_EMAIL` placeholder, and do not invent or reuse a contact email. If `ZETARIS_USER_AGENT` is not set, ask the user which value to send (SEC EDGAR requires a real contact), then pass it for the run or have them add it to `.env.local`. The runner refuses to send the placeholder.
- **Re-runs.** `--skip-exists` skips "already exists" errors, so a script can be run again on an instance that already has some of its objects. Without it the run stops at the first duplicate.
- **JDBC.** `--channel jdbc` needs the driver JAR from `--jar` or `ZETARIS_JDBC_JAR`. Ask the user for the path; never assume one. The runner finds a Homebrew JDK and hops into `.venv` itself.
- **Order and dependencies.** The approach is: onboard the data sources first, then create and activate a USL over them. Every source and USL model, with the sources it `requires`, is declared once in `open_data/manifest.json`. Use `python3 scripts/onboard.py --list` to see them, `plan <id>...` to see the resolved order, and `run <id>... --dry-run` then `run <id>...` to onboard them with their dependencies first. Never work out the order by hand or from HOWTO prose. A `known_to_fail` source needs `--allow-known-to-fail`. When you add a create script, add it to the manifest (`onboard.py --check` validates it).
- **Teardown and restarts.** When the user asks to clean up or start over, confirm the scope first (instance objects, local setup such as `.venv`, any published viewer), then use `python3 scripts/onboard.py teardown <id>...`. Do not hand-write DROP statements. Show the plan (it also pulls in sources that `require` the target), wait for a go-ahead, then re-run with `--yes`. Do not pipe a script that changes the instance through a filter such as `grep` on its first run; a filter error hides the output while the statements still run. After it finishes, report what only the Zetaris Data Explorer can remove (REST and file tables, Lightning databases, containers) and say that a re-run needs `--skip-exists` if they are left. `--drop-namespace` also removes every USL in the namespace, so only use it when asked.
- **Verify after creating**, as in `open_data/rest_apis/HOWTO.md` section 2: compare Zetaris row counts with an independent check against the source API.

## Safety

- Start read-only (`SHOW`, `DESCRIBE`, `SELECT`). Ask before anything that creates, drops, grants or writes.
- Keep passwords and keys out of prompts, logs, source files and commits.
- Do not call port 8889 on a local instance.
- Sources under `known_to_fail/` are documented failures, and `rate_limited/` sources should be run deliberately, not repeatedly.

## Adding or changing sources

Follow `CONTRIBUTING.md`: the `_create.sql` / `_select.sql` pattern, the `known_to_fail/` write-up format, and license verification. Source HOWTOs live in `open_data/*/HOWTO.md`.
