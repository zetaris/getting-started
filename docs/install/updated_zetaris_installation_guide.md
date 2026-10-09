# Zetaris installation and configuration guide

**Date:** 24 September 2026  
**Tested:** the local installation, first login, both data recipes and the lifecycle commands have been tested on a fresh install. The AWS path's sizing and cost estimates were checked, but its steps have not been run on AWS. See the [test record](zetaris-installation-test-record.md).  
**Distribution:** Zetaris platform Docker Compose bundle, with driver/API images in the 2.4.3.1 series. This guide covers local installation and installation on an AWS virtual machine.

By the end of this guide, you should be able to sign in to Zetaris, execute a SQL query, and begin the Parquet/CSV and REST data recipes.

## 1. Choose an installation path

| Path | Choose it when | Resources and cost |
| --- | --- | --- |
| **Local Docker Compose** | You want to evaluate Zetaris or work through recipes on your own machine | Allocate 8 GB RAM and 4 CPUs to Docker, with at least 15 GB free disk space. No cloud infrastructure bill. |
| **Docker Compose on AWS** | Your laptop lacks resources, or you need a remotely hosted development environment | An `m7i-flex.large` (2 vCPUs, 8 GiB RAM) with a 40 GiB disk in Sydney (`ap-southeast-2`), about $1.04 for an eight-hour session, paid from AWS Free plan credits. |

Both paths use the same bundle. Choose local installation when your machine meets the requirements below; choose AWS when you need a remote development machine.

**Which AWS free tier fits:** this bundle's preflight check requires at least 6 GB of memory available to Docker and recommends 8 GB. AWS accounts created on or after 15 July 2025 have a Free plan whose eligible instance types include `m7i-flex.large` (8 GiB), which meets that requirement. Accounts created before that date have the older free tier, which only covers 1 GiB `t2.micro`/`t3.micro` instances; those accounts need a paid instance such as `t3.xlarge`. [AWS free-tier instance types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html)

## 2. Obtain the distribution and access

### What is being installed

Zetaris is distributed as a Docker Compose bundle. It contains the platform configuration, initialisation scripts and references to images in `zetarishackathon.azurecr.io`. Use the supplied `docker-compose.yml`; there is no need to build images or construct a new Compose file.

| Component | Purpose |
| --- | --- |
| `postgres` | Metadata and audit databases, plus bundled sample data |
| `init` | Initialises shared volumes and encryption keys; exits successfully when finished |
| `driver` | Zetaris query engine |
| `api` | Application API |
| `ui` | Browser interface |
| `bootstrap` | Creates the initial organisation, administrator and configured sample data; exits when finished |
| `ai-datasteward` | AI data service; included in this Compose configuration |

### Download and licensing

You need the platform archive, its matching `.env`, registry credentials and a Zetaris licence or evaluation entitlement covering your installation.

1. Start at [Zetaris Cloud](https://www.zetaris.com/cloud) for a local installation. Choose **Start Free** to open the account portal, then register or sign in with your existing account. You can also use the [registration page](https://cloud.enterprise.zetaris.com/register) directly. Your Zetaris Cloud credentials are separate from the administrator account you will create inside your installation.
2. Review the [Terms and Conditions](https://cloud.enterprise.zetaris.com/terms) and [Privacy Policy](https://cloud.enterprise.zetaris.com/privacy) before completing registration. Your use of the platform is governed by your Order with Zetaris. Without one, the agreement allows internal evaluation for up to 30 days; it does not grant an ongoing licence.
3. Open the [Run locally page](https://cloud.enterprise.zetaris.com/dashboard/download), download `zetaris-platform.zip` and use the registry sign-in command supplied there. That page also has the current local startup steps and sign-in details. Move the zip out of Downloads before unpacking it. If the download is not available for your account, contact [Zetaris Support](https://www.zetaris.com/support) to have it enabled.

If your organisation has already arranged access, use the supplied archive and registry credentials. The Apache licence in the `getting-started` repository covers the data recipes only, not the platform images.

After extraction, keep these files together:

```text
zetaris-platform/
  .env
  .env.server.example
  docker-compose.yml
  preflight.sh
  verify.sh
  conf/
  init/
  initdb/
  sample-data/
  caddy/
```

The `getting-started` repository contains the data recipes and this guide; it does not replace the platform bundle. You can keep it inside `zetaris-platform` or anywhere else convenient.

Some older bundle comments refer to `.env.example` or `env/make-env.sh`. Those files are absent from this distribution. Use its supplied `.env`; obtain a matching copy from the distributor if it is missing. Preserve the supplied image references as a compatible set.

## 3. Path A — local Docker Compose

### 3.1 Prepare the machine

Install [Docker Desktop](https://docs.docker.com/desktop/) on macOS/Windows, or [Docker Engine with the Compose plugin](https://docs.docker.com/engine/install/) on Linux. On Windows, run the shell commands from WSL2 with Docker Desktop integration enabled.

| Requirement | Guidance for this bundle |
| --- | --- |
| Docker | Docker Engine 25 or later is recommended by the preflight script; daemon must be running |
| Compose | Use the `docker compose` plugin; this guide was tested with Compose 5.5.1 |
| Memory | 8 GB available to Docker recommended; preflight fails below 6 GB |
| CPU | 4 CPUs available to Docker recommended |
| Disk | At least 15 GB free for the installation; allow additional space for datasets and logs |
| Architecture | The supplied Zetaris images are amd64; Apple Silicon requires emulation |
| Network | Outbound access to the image registry and the data sources you will query |

On Docker Desktop, the memory allocation to Docker matters, not just the laptop's installed RAM. Leave headroom for the operating system and other applications. On Apple Silicon, enable supported amd64 acceleration where available and allow extra startup time.

### 3.2 Extract the bundle and authenticate

From the directory containing the downloaded archive:

```bash
unzip zetaris-platform.zip
cd zetaris-platform
docker version
docker compose version
docker login zetarishackathon.azurecr.io
./preflight.sh
```

Enter the registry credentials issued by Zetaris at the prompts. Run subsequent platform commands from this directory, which contains `docker-compose.yml`.

Resolve every preflight failure before proceeding. The registry check detects a stored login configuration; `docker compose pull` is the definitive check that the credentials can access the required images. Check free space in Docker Desktop's disk image as well as on the host.

### 3.3 Configure before first startup

Edit the supplied `.env` in an editor. Keep the issued image settings and other supplied values. Set or confirm:

| Variable | Local value or action |
| --- | --- |
| `ZETARIS_ADMIN_EMAIL` | Initial administrator email |
| `ZETARIS_ADMIN_PASSWORD` | Your own strong password, following the policy below |
| `ZETARIS_ADMIN_ORG` | Initial organisation name; choose before the first startup |
| `ZSPARK_DRIVER_MEM` | `2g` |
| `ZSPARK_DRIVER_CORES` | `2` |
| `ZSPARK_MASTER_URL` | `local[2]` |
| `ZETARIS_API_MAX_HEAP` | `1g` |
| `UI_PORT` | `3000` |
| `ALLOWED_ORIGINS` | `http://localhost:3000` |
| `GUI_URL` | `http://localhost:3000` |
| `COMPOSE_PROFILES` | Empty/unset for this local path |
| `ZETARIS_SEED_TPCH` | `true` to retain the supplied sample-data setup |

The administrator password must be at least eight characters and contain lowercase, uppercase, a digit and one of `$ @ ! % * ? &`. Other punctuation is rejected.

Keep `.env` private and out of version control:

```bash
chmod 600 .env
docker compose config --quiet
```

`--quiet` validates the configuration without printing resolved secrets.

### 3.4 Pull and start

```bash
docker compose pull
docker compose up -d
docker compose ps --all
```

The bundle README estimates roughly 4 GB of image downloads, taking 5–15 minutes, followed by 5–10 minutes for first startup. In testing on an Apple Silicon laptop with the images already downloaded, the first startup finished in under four minutes. Allow about 30–45 minutes for a first installation, longer on a slow network or an emulated host. Use service readiness rather than elapsed time to decide whether startup is complete.

```bash
docker compose logs --tail=80 driver api bootstrap
./verify.sh
```

Expected results:

- `postgres`, `driver`, `api`, `ui` and `ai-datasteward` are running; check their health in `docker compose ps --all`.
- `init` and `bootstrap` show `Exited (0)`. They are successful one-time setup jobs.
- `verify.sh` passes all nine checks, including login and a query through the UI, API and query engine.

If bootstrap is still running, wait for it to finish and rerun the verifier. If `ui` checks fail immediately after bootstrap finishes, the UI may still be starting: wait a minute and run `./verify.sh` again before troubleshooting. Continue with section 5.

## 4. Path B — small AWS installation

### 4.1 Set up the AWS account and session budget

1. Use your organisation's AWS account, or create an account from [AWS signup](https://aws.amazon.com/resources/create-account/). Complete the displayed email, contact, payment and identity verification steps, and select Basic Support for this quickstart. Obtain console access with permission to manage EC2, EBS, security groups and this session's billing information.
2. Choose the plan. A new account can stay on the **Free plan** and use `m7i-flex.large`, paid from its credits. The Free plan lasts six months or until the credits are used up, whichever comes first. Choose the **Paid plan** instead if your account was created before 15 July 2025, or if you want the larger `t3.xlarge`. To upgrade a Free-plan account, use **Upgrade Plan** in the console's Billing console; upgrading keeps any remaining credits until they expire.
3. Open **Billing and Cost Management → Credits**. Record the balance, expiry and applicable services. Redeem a separately issued promotional code there if applicable. New-customer credits start at $100, with up to $100 more earned through qualifying activities; a $200 balance is not automatic. [AWS plan and credit rules](https://aws.amazon.com/free/free-tier-faqs/)
4. In **Billing → Budgets**, create a $10 monthly cost budget with an email notification at $5 of actual cost. Include usage before credits when configuring the cost calculation so the alert remains useful during a credited session. This is a notification, not an automatic shutdown.
5. Schedule an **eight-hour session**, with the first hour reserved for provisioning, downloads, startup and verification. Set a reminder to terminate the demo before the eight hours end and before the Free plan or credits expire.

The following estimate uses AWS's On-Demand Linux rates for Asia Pacific (Sydney), `ap-southeast-2`, from the AWS price list published on 21 September 2026. AWS bills in US dollars.

| Item | Rate | Eight-hour session |
| --- | --- | --- |
| One `m7i-flex.large` (Free-plan eligible) | $0.1197/hour | $0.9576 |
| One public IPv4 address | $0.005/hour | $0.0400 |
| 40 GB gp3 at baseline performance | $0.096/GB-month | About $0.042 if deleted after eight hours, using a 730-hour month |
| **Estimated total** | | **About $1.04** |

If you keep the disk for a full month after that eight-hour session, the estimate becomes **$4.84**. Leaving the complete environment running for 730 hours is approximately **$94.87**.

With a `t3.xlarge` ($0.2112/hour) instead, the session costs about **$1.77**, keeping the disk for a month about **$5.57**, and running for 730 hours about **$161.67**.

Sources: [EC2 On-Demand pricing](https://aws.amazon.com/ec2/pricing/on-demand/), [EBS pricing](https://aws.amazon.com/ebs/pricing/), [IPv4 pricing](https://aws.amazon.com/vpc/pricing/). These estimates exclude data transfer, taxes, snapshots, extra storage and any platform licence charge. Reserve **$10 of eligible credits** for this short session and check the price the console displays before launch. Use the [AWS Pricing Calculator](https://calculator.aws/) if changing the region or configuration.

### 4.2 Provision the VM

Use these instance settings. With the local sizing profile, the Zetaris containers used about 1.9 GiB of memory at idle and about 2.3 GiB after running the section 6 recipes, on a machine giving Docker 7.7 GiB. An 8 GiB `m7i-flex.large` gives the same memory; its 2 vCPUs match the local profile's two cores, so expect slower queries than on a larger machine. Choose `t3.xlarge` (4 vCPUs, 16 GiB) for heavier work or on a Paid-plan account.

| Setting | Value |
| --- | --- |
| Region | Asia Pacific (Sydney), `ap-southeast-2` |
| AMI | Canonical Ubuntu Server 24.04 LTS, **x86_64** |
| Instance | `m7i-flex.large` (2 vCPUs, 8 GiB RAM), or `t3.xlarge` (4 vCPUs, 16 GiB RAM) |
| Disk | 40 GiB encrypted gp3 root volume; review delete-on-termination |
| Network | VPC subnet with internet access and a public IPv4 address for the SSH path below |
| Access | SSH key pair; inbound TCP 22 restricted to your public IP |
| Metadata | Require IMDSv2 |
| CPU credits | `t3.xlarge` only: Standard, with Unlimited disabled |

`t3.xlarge` is burstable: in Standard mode, sustained CPU use is limited to the credits it earns, which avoids surplus CPU-credit charges but can throttle long queries. [AWS CPU-credit configuration](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-how-to.html)

This installation uses EC2, EBS, VPC networking and a security group. It does not require RDS, Kubernetes, a load balancer or a NAT gateway. S3 is optional for recipes that use your own stored files. Allow outbound access for package installation, image pulls and source queries. Keep application ports closed to inbound internet access for the SSH-tunnel setup.

In the EC2 console:

1. Select **Asia Pacific (Sydney)** and choose **Launch instance**. Name it `zetaris-quickstart`.
2. Select Ubuntu 24.04 LTS from Canonical and **64-bit (x86)**, then select `m7i-flex.large` (marked **Free tier eligible**) or `t3.xlarge`.
3. Create/download a `.pem` key pair, or select a key whose private file you already hold.
4. Under **Network settings**, select the default VPC and a subnet, enable a public IP, and create a security group allowing SSH only from **My IP**. Leave HTTP/HTTPS closed for the tunnel path.
5. Set the root disk to 40 GiB gp3 with encryption, baseline IOPS/throughput and delete-on-termination enabled. Under **Advanced details**, require IMDSv2; for `t3.xlarge`, also disable Unlimited CPU credits.
6. Review one instance and its costs, then launch. Wait for **Running** and successful instance status checks. Record its instance ID, public IPv4 and root-volume ID for access and teardown.

If the account has no default VPC, use an approved public subnet. To build an isolated one, create a VPC and subnet with non-overlapping private CIDRs, attach an internet gateway, and associate the subnet with a route table containing `0.0.0.0/0` to that gateway. Enable VPC DNS resolution and assign a public IP at launch. Record these additional resources for teardown. [EC2 launch procedure](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-instance-wizard.html)

### 4.3 Install the bundle on the VM

Transfer the supplied archive, substituting your key path and instance address:

```bash
chmod 600 /path/to/key.pem
scp -i /path/to/key.pem zetaris-platform.zip ubuntu@YOUR_PUBLIC_IP:~/
ssh -i /path/to/key.pem ubuntu@YOUR_PUBLIC_IP
```

On the VM, install Docker Engine and the Compose plugin using [Docker's Ubuntu installation instructions](https://docs.docker.com/engine/install/ubuntu/). Install `unzip` if absent. Confirm your chosen account can run `docker version` and `docker compose version`; if group membership was changed, reconnect first. Use the same account for registry login and Compose operations.

```bash
unzip zetaris-platform.zip
cd zetaris-platform
docker login zetarishackathon.azurecr.io
./preflight.sh
```

On `m7i-flex.large`, preflight passes with warnings that memory is below the recommended 8 GB and that there are fewer than 4 CPUs. Both are expected.

For an individual developer, use the supplied local `.env` and apply section 3.3, including a unique administrator password and `UI_PORT=127.0.0.1:3000`. The small local heap settings are a starting point even on the larger VM; increase them only when needed.

```bash
chmod 600 .env
docker compose config --quiet
docker compose pull
docker compose up -d
docker compose ps --all
./verify.sh
```

From another terminal on your laptop, establish the tunnel and leave it running:

```bash
ssh -i /path/to/key.pem -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:3000:127.0.0.1:3000 ubuntu@YOUR_PUBLIC_IP
```

Open <http://localhost:3000> on your laptop. The traffic travels over SSH, and the browser treats it as localhost.

## 5. First login and initial verification

1. Open <http://localhost:3000>, locally or through the SSH tunnel.
2. Sign in with the administrator email and password configured before bootstrap.
3. Open the SQL Editor and run:

```sql
SELECT 1 AS one;
```

Expect one row with value `1`. This confirms that an authenticated query reaches the engine without depending on an external dataset.

If you retained the shipped default login, the bundle README lists `admin@zetaris.com` / `Zetaris1@`; change that password immediately.

Changing `ZETARIS_ADMIN_PASSWORD` or the organisation in `.env` after bootstrap does not recreate or reset existing accounts. After a UI password change, the verifier needs a matching credential value in `.env`; otherwise its login check can fail even though the services are healthy.

## 6. Verify the data recipes

The recipe SQL runs **inside Zetaris's SQL Editor**. Open the files from the `getting-started` repository and execute the relevant statements against the instance you just installed. A file downloaded onto your laptop is not automatically visible to the query engine, particularly on AWS.

### Parquet/CSV

Read the current [Parquet/CSV HOWTO](../../open_data/parquet_csv/HOWTO.md) and [recipe plan](../plans/archive/00-parquet-csv.md). Start with [the NOAA GHCN-Daily CREATE script](../../open_data/parquet_csv/sql/02_noaa_ghcn_create.sql) — live-tested and confirmed working (PUDL, this walkthrough's earlier example, is now known to fail; see the HOWTO's "Source folders" section):

1. Review its header and verify that the source path (the current year's file) is still available.
2. Run the `CREATE LIGHTNING DATABASE NOAA_GHCN_S3` prerequisite once.
3. Run the `CREATE LIGHTNING FILESTORE TABLE` statement, then its `CACHE TABLE` statement — confirmed required for workable query times against this table, not just a nice-to-have.
4. Run:

```sql
SELECT * FROM NOAA_GHCN_S3.noaa_ghcn_daily_2025 LIMIT 10;
```

Expect 10 rows of raw station observations (station ID, date, element code, value, and flag columns — no header row, so Zetaris names them `_c0`..`_c7`). The script reads a public bucket (`isS3BucketPublic "true"`), so you do not need AWS credentials. `sql/02_noaa_ghcn_select.sql` has further analytical example queries, also confirmed working, if you want to explore further.

### REST

Follow the [REST HOWTO](../../open_data/rest_apis/HOWTO.md) and [PokéAPI script](../../open_data/rest_apis/sql/non_rate_limited/02_pokeapi_create.sql). It needs no API key.

Run its database/container prerequisites and the Pikachu REST table and view statements, then query:

```sql
SELECT * FROM pokeapi.pikachu_abilities_table LIMIT 10;
```

Expect two rows for Pikachu's abilities: `static` and the hidden ability `lightning-rod`. Run creation statements only for objects that do not already exist; the recipe is not an idempotent migration script. Outbound access to the source must work from the Zetaris server, not just the browser machine.

## 7. Stop and tear down

Run from the platform directory:

```bash
docker compose stop          # stop containers, retaining data
docker compose start         # resume stopped containers
docker compose down          # remove containers/network, retain named volumes
docker compose up -d         # recreate containers using retained data
```

`docker compose down -v` also deletes the named volumes, including the metastore and encryption keys. Use it only when discarding the installation.

### AWS teardown

Stopping containers does not stop EC2 billing. For a temporary break, stop the instance in AWS; storage and retained public addresses can still incur charges. A non-reserved public IP can change at the next start, affecting SSH and DNS.

At the end of the quickstart:

1. Back up anything you need to retain.
2. Terminate the demo instance when its data can be discarded.
3. Inspect and remove unneeded retained EBS volumes, snapshots and Elastic IPs.
4. Remove this demo's unused security group and any optional recipe storage you created.
5. Check Billing for remaining resources and charges before the credit window ends.

## 8. Completion checklist

For the environment, results and memory measurements behind this guide, see the [test record](zetaris-installation-test-record.md).

- [ ] Bundle, matching configuration and registry access obtained.
- [ ] Hardware/resource checks passed.
- [ ] Services running; setup jobs exited successfully.
- [ ] Administrator login and `SELECT 1 AS one` succeed.
- [ ] Intended Parquet/CSV and REST recipes return data.
- [ ] For AWS, the cost estimate, credit expiry and teardown time are recorded.

Related documents: [test record](zetaris-installation-test-record.md), [getting-started README](../../README.md), [original installation plan](../plans/archive/zetaris-installation-guide.md) (archived — superseded by this guide), [Parquet/CSV plan](../plans/archive/00-parquet-csv.md).
