# Connect Cursor to Zetaris

First confirm the [connection prerequisites](README.md). This repo supplies the prompt and a small [recipe command reference](lightning-recipe-reference.md); it does not supply the driver, instance, or account.

Obtain the matching Zetaris JDBC driver and actual JDBC endpoint from the instance administrator, or the separate distribution used by the [installation guide](../install/updated_zetaris_installation_guide.md). Confirm a Java runtime and a JDBC client are available in the environment where Cursor executes commands. If either is absent, report the missing prerequisite before installing or substituting anything.

The local distribution documented in the Codex guide uses `com.zetaris.lightning.jdbc.LightningDriver` and `jdbc:zetaris:lightning@localhost:10000`. These are local examples. `localhost` means the machine executing the client; it does not identify a shared remote instance.

Supply credentials through your local execution environment. Keep them out of prompts saved in the repo, SQL files, and reports. Attach the actual driver and these repository docs using Cursor's file context, then use this prompt after replacing non-secret placeholders:

```text
Connect to the Zetaris instance using the actual driver at {{ABSOLUTE_DRIVER_PATH}}
and the endpoint {{JDBC_URL}}. Use the credentials already configured in the
local environment. If they are unavailable, ask me to configure them locally;
do not guess credentials or print them.

Use the driver class required by this matching distribution. For the local
distribution described by this repo, it is
com.zetaris.lightning.jdbc.LightningDriver.

Read docs/connections/lightning-recipe-reference.md and
START-HERE.md from this repository. Use Zetaris Lightning SQL directly through
JDBC. Do not create a SparkSession or substitute a Hive/Spark JDBC driver.

Check connection by running SELECT 1; and require a result row containing 1.
Stop if the driver, runtime, endpoint, credentials, or permissions are missing.
A connection check does not verify an external dataset.

Before creating objects, obtain my assigned team prefix and confirm the allowed
objects. Inspect matching existing objects and reuse them only if their
source/definition matches. Do not delete or alter another team's objects.
Execute one complete command per JDBC call and wait for each result before
issuing a dependent command. Keep each COMPILE USL ... DDL payload intact.
```

After connection succeeds, follow [your first dataset](../guides/first-dataset.md). Advanced USL work also needs the relevant model guide and version-compatible platform reference; the starter command reference is not a complete USL manual.
