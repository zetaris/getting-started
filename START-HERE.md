# Start here

Get Zetaris running, try a small dataset, then choose what you want to build. This repo has the SQL recipes and guides you'll need.

## 1. Check your prerequisites

| What you need | What to do |
|---|---|
| Zetaris access | Use the instance we've given you. If you're installing locally, start at [Zetaris Cloud](https://www.zetaris.com/cloud) and follow the [installation guide](docs/install/updated_zetaris_installation_guide.md). |
| Login details | Get the website URL, your account, and permission to run queries and create objects. |
| Team names | On the shared instance, use your assigned team names and only change objects your team owns. |
| Source access | Zetaris must be able to reach the data source. Being able to reach it from your laptop isn't enough. |

Missing access? Ask the organisers.

### Use an existing instance

1. Sign in with your account.
2. Open the SQL Editor.
3. Run `SELECT 7 AS seven;`. You should get one row with `7`.

If it fails, check [troubleshooting](docs/guides/troubleshooting.md).

### Install locally

Open [Zetaris Cloud](https://www.zetaris.com/cloud), choose **Start Free**, and register or sign in. Follow the [installation guide](docs/install/updated_zetaris_installation_guide.md#download-and-licensing) to download the bundle and set it up with Docker Compose.

The guide also has an AWS option. The local install has a [recorded test](docs/install/zetaris-installation-test-record.md); the AWS steps haven't been run in that test.

## 2. Run some SQL

Start in the SQL Editor. Run one complete statement at a time and wait for the result.

Want to use an assistant or script? See [connection options](docs/connections/README.md) for Cursor, Codex, Claude Code, JDBC and HTTP setup. Client settings go in `.env.local`; the platform bundle uses its own `.env`.

For a file with several commands, use `run_sql.py`. For recipes with dependencies, use `onboard.py`. Preview the commands with `--dry-run` before running them. See [client scripts](scripts/HOWTO.md).

## 3. Try your first dataset

Follow [your first dataset](docs/guides/first-dataset.md) to query Pikachu's abilities from PokéAPI. Check that you get the expected rows before moving on.

## 4. Choose what to build

You can [analyse data, combine sources, or build an app](docs/guides/project-paths.md). Choose a question that interests you. For more data, see [available recipes](docs/guides/recipe-readiness.md).

## 5. Prepare your demo

Save your SQL and results so someone else can run them. Use the [demo template](docs/guides/demo-template.md), and check submission details with the organisers.

Stuck? See [troubleshooting](docs/guides/troubleshooting.md). Only clean up your own objects. Don't stop or reset the shared instance.
