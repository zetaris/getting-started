# Start here

Query the supplied samples, connect your own data, then build your hackathon project. Use the [event page](https://hackathon.genai.works/event/open-agent-hackathon-2026) for registration, rules and submission details.

## 1. Check your prerequisites

Set up your own Zetaris instance using one of the routes below. Then sign in with your account.

| Access route | Start here |
|---|---|
| Your computer | Download from [Zetaris Cloud's Run locally page](https://cloud.enterprise.zetaris.com/dashboard/download), then follow [Install locally](docs/install/updated_zetaris_installation_guide.md). |
| Managed AWS cluster | Use [Managed AWS cluster](docs/install/managed-aws-cluster-guide.md) to connect your AWS account and create a Zetaris compute cluster from Zetaris Cloud. |

## 2. Run some SQL

Open the SQL Editor. Use [connection choices](docs/connections/README.md) if you prefer an assistant or script.

Follow [your first SQL commands](docs/connections/lightning-recipe-reference.md). Check execution, inspect tables and read the supplied NY Taxi and TPCDS samples. This step only needs query permission and creates nothing.

## 3. Try your first dataset

Optionally follow [your first dataset](docs/guides/first-dataset.md) to connect PokéAPI and query Pikachu's abilities. This step needs creation permission on your instance. Zetaris must be able to reach the API.

Check the expected rows if you use this recipe. You can also build a project using only the supplied samples.

## 4. Choose what to build

[Analyse data, combine sources, or build an app](docs/guides/project-paths.md). Find additional sources in [Cookbooks](docs/guides/recipe-readiness.md).

## 5. Prepare your demo

Use the [demo template](docs/guides/demo-template.md) to save your SQL, results and steps someone else can reproduce. Check the event page for submission requirements.

Stuck? See [troubleshooting](docs/guides/troubleshooting.md). Follow the cleanup steps for your local installation or AWS cluster when you finish.
