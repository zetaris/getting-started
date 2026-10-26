# Troubleshooting

Find your error below. For SQL limitations, see the [SQL companion](zetaris-lightning-sql-companion.md).

## What went wrong?

| Problem | What to try |
|---|---|
| Missing URL, account or driver | For a local install, use the [Run locally page](https://cloud.enterprise.zetaris.com/dashboard/download). For an existing instance, use the supplied connection details. SQL Editor needs no JDBC; see [connection options](../connections/README.md). |
| AWS account stays **Unverified** or says **Zetaris can't access the IAM role for this AWS account** | Follow [AWS account remains Unverified](#aws-account-remains-unverified), including the recommended email/password signup route if you used Google signup. |
| Local install won't start | Run `preflight.sh` from the platform bundle and follow the [install guide](../install/updated_zetaris_installation_guide.md). Check registry access, memory, disk and configuration. |
| Driver OOM, growing memory while caching JSON, or `Cannot call methods on a stopped SparkContext` | Follow [Driver memory and wide JSON](driver-memory-wide-json.md) for recovery, bounded caching, Parquet storage and driver settings. |
| Login fails or HTTP 401 | Check the URL and credentials. Changing the platform's `.env` after setup does not reset an account. |
| REST preflight says `Operation not permitted` for localhost | The command environment may have blocked local network access before Zetaris returned an HTTP response. In Codex, retry the read-only command with the requested network or elevated execution permission if offered. Do not change the API URL or key based on this error. If permission is unavailable, run the command in a terminal that can reach the instance. |
| Permission error or HTTP 403 | Check your organisation, team names and account permissions. Use your own account. Creating, updating and deleting normally needs an administrator or a delegated Write role: see [Permissions](permissions.md). |
| Missing or invalid org ID | Follow [HTTP setup](../../scripts/HOWTO.md#find-your-organization-id) and use your numeric ID. SQL Editor does not need this setting. |
| HTTP 404 or an HTML response | Use the UI URL that supports the helper's proxy routes. The raw API port does not. |
| JDBC won't connect | Check the driver JAR, class, Java and endpoint. On a remote agent, `localhost` is that machine. |
| Object already exists | Check its owner and definition. Reuse a match; otherwise choose a different project name. |
| Table created but no rows returned | Check the source path, response, schema and Zetaris access. Start with a small `SELECT`. |
| HTTP 429 | Wait as the source instructs. For `company_dns`, first check you sent a User-Agent of the form `app_name user@domain.tld`: without it the limit is very strict. Cache the raw table, wait 60 seconds and retry that one statement; without an identifying User-Agent also space endpoint calls by at least 15 seconds. Avoid retry loops; one statement can trigger several requests. |
| HTTP 502 | Check the source error and retry once if appropriate. `company_dns` has moved hosts and no longer uses the removed warm-up helper. On rate-limited sources, wait before another attempt. Report repeated failures. |
| PUDL registration fails | PUDL has a [known issue](../../open_data/parquet_csv/sql/known_to_fail/ISSUE-03-pudl.md). Use the PokéAPI starter. |
| A downloaded file won't query | Put it in storage Zetaris can reach. A file on your laptop may be out of reach. |
| Uploaded PDF shows bytes or only part of its text | Follow [Upload a PDF and read its text](upload-pdf.md) for File Store registration, `preview_len` and `pdfToText(bincontent)`. |
| Chart won't read the result | Check the query response shape and look for an error before comparing it with the example. |

## AWS account remains Unverified

At **Verify AWS Account → Step 4 of 4**, you may see:

> Zetaris can't access the IAM role for this AWS account.

1. **Check how you created the AWS account.** For a new setup, use [AWS Sign up (advanced)](https://signin.aws.amazon.com/signup?request_type=register), which asks for a **Root user email address**, and complete email/password signup. This is the recommended workaround if you used the new Google signup flow and cannot finish the Zetaris integration. Then repeat [Zetaris Quickstart](../install/managed-aws-cluster-guide.md#1-add-and-verify-your-aws-account) in that account. If you already have resources you need, keep them and contact support before starting over.
2. **Check the stack.** In CloudFormation, confirm the intended AWS account and region, and wait for the Quickstart stack to reach `CREATE_COMPLETE`.
3. **Check the role details.** The IAM Role ARN and External ID in Zetaris must belong to the same current Quickstart setup. Do not reuse values from another account or an older setup. If the stack or role's trust policy changed, review it against the supplied Quickstart configuration; keep its External ID condition.
4. Return to Zetaris and select **Verify again**. If it still fails, share the error and CloudFormation status with support.

This message can also mean the role is missing or its trust policy does not allow access; it does not prove Google signup caused the failure. See [AWS's IAM role troubleshooting](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_roles.html).

## Reruns and object names

Use consistent object names on your own local or AWS instance. Check existing objects before reusing a name.

1. Replace all database, container, namespace, model and reference names consistently.
2. Check existing objects before creating them. See the [recipe reference](../connections/lightning-recipe-reference.md).
3. Reuse existing sources only when their definitions match your recipe.
4. Run one complete statement at a time. If one fails, fix it and continue; earlier statements may have created objects.
5. Cache, change or remove only objects you own and are allowed to change.

`run_sql.py --skip-exists` skips duplicate errors. It does not check that an existing object matches your recipe. `CREATE SCHEMASTORE CONTAINER` has no `IF NOT EXISTS`; check before creating another container. See the [SQL companion](zetaris-lightning-sql-companion.md#5-operational-limitations-confirmed-live-not-documentation-guesses) for the tested cleanup scope.

## Cleanup

Remove only objects you own and have permission to remove. For your local install, follow the installation guide's shutdown steps. For AWS, follow the [managed cluster teardown steps](../install/managed-aws-cluster-guide.md).

On 12 October 2026, Zetaris 2.4.3.1 let `DROP LIGHTNING DATABASE TABLE` remove `reason` (public S3 filestore) and `ability` (PokéAPI REST); `DROP LIGHTNING DATABASE` then removed their test database. This covers only these fixtures. The check deleted an empty SchemaStore container through the documented API after `viewCount=0`; no SQL container-drop form was tested. Use Data Explorer's **File Source & API** panel for other registrations. See the [SQL companion](zetaris-lightning-sql-companion.md) for full scope.

Only drop a namespace if you may remove everything it contains.

## Record the error

Report the tool, failed step, time, error and last step that worked. State whether login, SQL and source queries worked. Remove passwords, tokens, Authorization headers and unrelated customer data.
