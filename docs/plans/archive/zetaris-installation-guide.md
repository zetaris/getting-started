# Plan: Zetaris hobby-edition installation & configuration guide

> **Archived — superseded.** The real, user-facing guide this plan was scaffolding now exists at [`docs/install/updated_zetaris_installation_guide.md`](../../install/updated_zetaris_installation_guide.md), with its test results in [`docs/install/zetaris-installation-test-record.md`](../../install/zetaris-installation-test-record.md). Kept here only as a historical record of the original planning.

**Status:** ✅ Superseded — shape of the distribution(s) not yet known; this is a scaffold to fill in as that becomes clear
**Target output:** a real, user-facing guide (working name: `docs/install/zetaris-hobby-edition.md` or a top-level `INSTALL.md` — decide once the content exists) covering local installation.

## Why this exists

Every recipe plan in `docs/plans/recipes/` assumes a running Zetaris instance to verify against. Nothing in the handoff package covers how to actually get one running — this guide closes that gap. It's the prerequisite for finishing the Parquet/CSV recipe's two open items, and for every recipe after it.

## Local installation

Install via `docker compose` on a developer's own machine. No cloud account is needed.

## Work items

### Discovery (do this first — nothing else here can be written accurately without it)

- [ ] Identify what Zetaris actually ships as an installable hobby/mini edition — a Docker image, a Helm chart, a downloadable installer, something else — and where it's published
- [ ] Confirm minimum resource requirements (CPU/RAM/disk) for a workable instance, for a typical developer laptop
- [ ] Confirm licensing/signup requirements for the hobby edition itself (separate from the data-source licenses tracked elsewhere in this repo)

### Local docker-compose install

- [ ] Write the prerequisite section (Docker/Docker Compose version, host resource requirements)
- [ ] Write (or obtain, if Zetaris publishes one) a `docker-compose.yml` that brings up a working instance
- [ ] Write first-login / initial configuration steps
- [ ] Document how to point this local instance at the Parquet/CSV and REST recipes for verification

### Shared

- [ ] Cross-link from this guide into `docs/plans/archive/00-parquet-csv.md` (the first consumer) and from the top-level `README.md`

## Open questions

- Whether a single "hobby edition" artifact exists yet, or whether this guide is actually documenting a config profile on top of Zetaris's standard distribution — resolve during discovery before writing the install steps
