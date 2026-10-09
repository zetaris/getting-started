# Start here

Get Zetaris running, try a small dataset, then choose what you want to build. This repo has the SQL recipes and guides you'll need.

Taking part in the [Open Agent Hackathon 2026](https://hackathon.genai.works/event/open-agent-hackathon-2026)? It runs online on 22-27 October, with teams of 1-5 builders. Use the event page for registration, tracks, rules and submission deadlines.

## 1. Check your prerequisites

| What you need | What to do |
|---|---|
| Zetaris access | Use the instance we've given you. If you're installing locally, sign in to [Zetaris Cloud's Run locally page](https://cloud.enterprise.zetaris.com/dashboard/download). |
| Login details | Get the website URL, your account, and permission to run queries and create objects. |
| Team names | On the shared instance, use your assigned team names and only change objects your team owns. |
| Source access | Zetaris must be able to reach the data source. Being able to reach it from your laptop isn't enough. |

### Use an existing instance

1. Sign in with your account.
2. Open the SQL Editor.
3. Run `SELECT 1 AS one;`. You should get one row with `1`.

If it fails, check [troubleshooting](docs/guides/troubleshooting.md).

### Install locally

Sign in to the [Run locally page](https://cloud.enterprise.zetaris.com/dashboard/download) and follow its steps. It provides the download, your registry sign-in command and the local sign-in details.

1. Install and open Docker Desktop. Give Docker 8 GB of memory and 4 CPUs, and leave 15 GB of disk space free. On Apple Silicon, enable **Use Rosetta** as directed by the portal. On Windows, use WSL for the shell commands.
2. Run the registry sign-in command shown in the portal, then download `zetaris-platform.zip`. Move the zip out of Downloads before unpacking it.
3. Unpack it, enter the `zetaris-platform` folder and run `./preflight.sh`. Resolve any failed checks before continuing.
4. Run `docker compose pull`, then `docker compose up -d`. Initial setup continues after the start command returns.
5. Run `./verify.sh`. If checks fail while setup is still running, wait a minute and try again.
6. Open [http://localhost:3000](http://localhost:3000) and sign in with the details shown in the portal. Change the initial password from the user menu.

Keep the registry and account credentials private. For configuration details and troubleshooting, use the [installation guide](docs/install/updated_zetaris_installation_guide.md). The local install also has a [recorded test](docs/install/zetaris-installation-test-record.md).

## 2. Run some SQL

Start in the SQL Editor. Run one complete statement at a time and wait for the result.

Want to use an assistant or script? See [connection options](docs/connections/README.md) for Cursor, Codex, Claude Code, JDBC and HTTP setup. Client settings go in `.env.local`; the platform bundle uses its own `.env`.

For a file with several commands, use `run_sql.py`. For recipes with dependencies, use `onboard.py`. Preview the commands with `--dry-run` before running them. See [client scripts](scripts/HOWTO.md).

## 3. Try your first dataset

Follow [your first dataset](docs/guides/first-dataset.md) to query Pikachu's abilities from PokéAPI. Check that you get the expected rows before moving on.

## 4. Choose what to build

You can [analyse data, combine sources, or build an app](docs/guides/project-paths.md). Choose a question that interests you. For more data, see [available recipes](docs/guides/recipe-readiness.md).

## 5. Prepare your demo

Save your SQL and results so someone else can run them. Use the [demo template](docs/guides/demo-template.md), and check the [event page](https://hackathon.genai.works/event/open-agent-hackathon-2026) for current submission requirements.

Stuck? See [troubleshooting](docs/guides/troubleshooting.md). Only clean up your own objects. Don't stop or reset the shared instance.
