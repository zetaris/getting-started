# Choose an install: your computer or an AWS cluster

You can run Zetaris on your own computer or as a cluster in your AWS account. Both give you the same platform. Use this page to pick one, then follow the matching guide.

The Zetaris developer/free edition is scoped to the size available on each platform, local or AWS, and nothing more. Zetaris does not charge for storage. Support comes from the [getting-started repository](https://github.com/zetaris/getting-started), the [Zetaris Knowledge base](https://kbase.zetaris.com/knowledge/sql-guide) and the Zetaris Discord.

## The rule

**If your computer meets the requirements below, you can start local. Otherwise, install Zetaris on AWS.**

| Requirement | What the local install needs |
|---|---|
| Docker | Docker Engine 25 or later recommended, with the daemon running. On macOS and Windows use Docker Desktop; on Windows run the commands from WSL2. |
| Memory | 8 GB available **to Docker** recommended. The install's own preflight check fails below 6 GB. |
| CPU | 4 CPUs available to Docker recommended. |
| Disk | At least 15 GB free, plus room for datasets and logs. |
| Architecture | The Zetaris images are amd64. Apple Silicon runs them through emulation, which needs extra startup time. |
| Network | Outbound access to the image registry and the data sources you will query. |

The memory that counts is the amount you allocate to Docker, not the total in your computer. If you cannot give Docker that much, or Docker is not allowed on your computer, use AWS.

You can also do both. A local install and an AWS cluster do not conflict, and at this size the Zetaris software is free in either place.

## Compare the two

Use this when your computer meets the requirements and you are weighing the two.

| | Local install | AWS cluster |
|---|---|---|
| **Where it runs** | Docker on your computer | A Zetaris compute cluster in your AWS account |
| **What you need** | The requirements above | An AWS account. A new account can use AWS's free credits; an existing account is billed normally. See below. |
| **Time to a first query** | About 20 to 30 minutes to pull the images and start the containers. This depends on your network connection. | About 30 minutes to provision a cluster, then you sign in to its Gateway and query. |
| **Cost** | Nothing beyond your computer. | AWS's charges for the resources, which a Free Tier account pays from credits. |
| **Your assistant or client connects to** | `localhost`, with the JDBC endpoint on port `10000`. | Your cluster's own hostname and JDBC endpoint, shown on the cluster's overview page. |
| **Availability** | While the computer is awake and Docker is running. | Set by the cluster's schedule; suspend or delete it when you do not need it. |
| **Clean up** | `docker compose down`, or `down -v` to discard everything. | Delete the cluster (about 15 minutes), then the CloudFormation stack. Retained storage can remain until you delete it. |
| **Permissions** | Docker on your computer. | An AWS identity that can create and delete the setup stack and its resources. |

## Using AWS

- **New AWS account.** Follow the [AWS Free Tier checklist](aws-free-tier-checklist.md) to collect up to $200 in credits, then create the cluster. In Zetaris testing a Mini cluster running non-stop for about a week used roughly $80 of them, so a five-day event fits within the credits.
- **Existing AWS account.** You can install a small Zetaris cluster in it, but the free credits do not apply, so AWS bills that account for the resources. Open a new account if you want the credits.

## Next

- **In your browser (Experimental):** Follow the [GitHub Codespaces guide](github-codespaces-guide.md) to run Zetaris on a 4-core machine.
- **Local:** [Install locally](updated_zetaris_installation_guide.md).
- **AWS:** [AWS Free Tier checklist](aws-free-tier-checklist.md) for a new account, then [Managed AWS cluster](managed-aws-cluster-guide.md).
- When Zetaris is running either way, continue to your first SQL from [Start here](../../START-HERE.md).
