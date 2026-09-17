# Plan: Zetaris hobby-edition installation & configuration guide

**Status:** 📋 Planned — shape of the distribution(s) not yet known; this is a scaffold to fill in as that becomes clear
**Target output:** a real, user-facing guide (working name: `docs/install/zetaris-hobby-edition.md` or a top-level `INSTALL.md` — decide once the content exists) covering two install paths.

## Why this exists

Every recipe plan in `docs/plans/recipes/` assumes a running Zetaris instance to verify against. Nothing in the handoff package covers how to actually get one running — this guide closes that gap. It's the prerequisite for finishing the Parquet/CSV recipe's two open items, and for every recipe after it.

## The two install paths

Zetaris publishes different editions; a "hobby edition" or small-footprint distribution shape isn't confirmed yet. What's known:

1. **AWS free-tier mini install** — small enough to fit inside AWS's free-tier allowances and a ~$200 promotional-credit budget, run within a defined time window before the credits expire.
2. **Local install via `docker compose`** — runs entirely on a developer's own machine, no cloud account needed.

Both need to be documented since different readers will want different paths (a laptop-only evaluator vs. someone comfortable spinning up a small cloud footprint).

## Work items

### Discovery (do this first — nothing else here can be written accurately without it)

- [ ] Identify what Zetaris actually ships as an installable hobby/mini edition — a Docker image, a Helm chart, a downloadable installer, something else — and where it's published
- [ ] Confirm minimum resource requirements (CPU/RAM/disk) for a workable instance, and check those against both target environments (AWS free-tier instance sizes, a typical developer laptop)
- [ ] Confirm licensing/signup requirements for the hobby edition itself (separate from the data-source licenses tracked elsewhere in this repo)
- [ ] Identify the actual AWS services involved in the free-tier path (EC2 instance type, storage, networking) and estimate whether a realistic quickstart session fits inside the ~$200/free-tier budget with margin

### AWS free-tier mini install

- [ ] Write the account/prerequisite setup section (AWS account, free-tier eligibility, credit application if applicable)
- [ ] Write the provisioning steps (instance type, AMI or install method, security group / networking basics)
- [ ] Write the Zetaris install/config steps on top of the provisioned instance
- [ ] Document a teardown step (so a reader doesn't leave billable resources running after the quickstart)
- [ ] Note estimated cost/time budget explicitly, so readers can judge fit against their own free-tier/credit window

### Local docker-compose install

- [ ] Write the prerequisite section (Docker/Docker Compose version, host resource requirements)
- [ ] Write (or obtain, if Zetaris publishes one) a `docker-compose.yml` that brings up a working instance
- [ ] Write first-login / initial configuration steps
- [ ] Document how to point this local instance at the Parquet/CSV and REST recipes for verification

### Shared

- [ ] A short "which path should I use" decision note at the top of the guide (local for iterating quickly and free; AWS free-tier for testing something closer to a real deployment, or when local resources are insufficient)
- [ ] Cross-link from this guide into `docs/plans/recipes/00-parquet-csv.md` (the first consumer) and from the top-level `README.md`

## Open questions

- Whether a single "hobby edition" artifact exists yet, or whether this guide is actually documenting a config profile on top of Zetaris's standard distribution — resolve during discovery before writing the install steps
- Whether AWS free-tier compute (t2/t3.micro-class) is sufficient to run Zetaris at all, or whether "free tier" here really means "covered by the ~$200 credit at a paid instance size" — changes the guide's cost-estimate section significantly
