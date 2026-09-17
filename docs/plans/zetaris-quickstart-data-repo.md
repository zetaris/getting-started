# Plan: Build out `zetaris-quickstart-data` — overview

Source: `handoff.md` (Cowork handoff), `quickstart-data-manifest.md` (main source guide, 14 sections), `open_data/parquet_csv/` (the one category with runnable code so far). These currently exist as untracked files in the main checkout (`/Users/mihay42/dev/getting-started`), not yet in this branch/worktree — see Phase 0.

This is the top-level plan. The category-by-category rollout lives in **[FUTURES.md](FUTURES.md)** (the roadmap index) and its per-category files in **`recipes/`** — don't duplicate that detail here; this file covers the parts that aren't a single category (baseline, top-level docs, the install guide, and sequencing).

## Context

This repo is meant to become a public quickstart (`zetaris-quickstart-data`) that gets people real, permissively-licensed data queryable in a small Zetaris deployment quickly. Cowork produced the research/manifest and one fully-scripted category (Parquet/CSV, 9 sources). Everything else in the manifest is researched and cited but has no runnable artifacts yet.

**Current direction (revised from the original all-at-once scaffold):** don't build out the full §13 directory tree up front. Build one category at a time, starting with Parquet/CSV, and don't touch a category — especially Kafka — until we're confident it'll actually work against a real Zetaris instance. See FUTURES.md for why this order and why Kafka specifically waits.

Note on current layout: the handoff suggested a `parquet/` folder; the package was instead placed at `open_data/parquet_csv/`. Kept as-is rather than renamed — the manifest's §13 tree is a suggestion, not a requirement, and renaming now just to match a document has no functional benefit. Each recipe's `Target location` records where it actually lands; the tree grows folder-by-folder as recipes ship rather than being scaffolded wholesale in advance.

## Phase 0 — Baseline

- [ ] Commit `handoff.md`, `quickstart-data-manifest.md`, and `open_data/parquet_csv/**` (currently untracked in the main checkout) to this branch as the starting baseline
- [ ] Review the `.gitignore` diff currently pending in the main checkout before committing — confirm it's intentional

## Phase 1 — Zetaris installation & configuration guide

Deferred from "build the repo tree" status to its own prerequisite: every recipe needs a running Zetaris instance to verify against, and the shape of a hobby/mini edition isn't known yet. Full detail in **[zetaris-installation-guide.md](zetaris-installation-guide.md)** — covers both a candidate AWS free-tier mini install (fits inside free-tier limits + ~$200 promotional credit, time-boxed) and a local `docker compose` install. This needs to reach at least a working local install before the Parquet/CSV recipe's live-verification work items can close.

## Phase 2 — Category rollout

Tracked entirely in **[FUTURES.md](FUTURES.md)**. Summary of current priority order: Parquet/CSV (active) → JSON/REST APIs → SQL RDBMS → Logs → NASA → Singapore → data.gov → EU → UK → Canada/Australia/Mexico/Africa → PDFs → Kafka (deferred, blocked on verification per its recipe). Each category is its own file under `recipes/` with its own checklist — check progress there, update status in both places together.

## Phase 3 — Top-level docs

- [ ] Update top-level `README.md`: what the repo is, current implemented status (not the full target vision — see the "what's implemented vs. planned" distinction below), pointer to the install guide, pointer to FUTURES.md
- [ ] Write `LICENSE-NOTES.md`: full per-source license list, built up incrementally as each recipe ships rather than all at once (start with the 9 Parquet/CSV sources, add a section per recipe as it lands)
- [ ] Carry forward the 🟢/🟡/🔴 convention (open / open-with-condition / not-included-with-reason) into every new README and into `LICENSE-NOTES.md`

`README.md` should be kept honest about status: only claim a category is "implemented" once its recipe's live-Zetaris verification has actually passed, not once code exists but is unverified. Update it alongside each recipe's status change rather than in one big pass at the end.

## Conventions to enforce throughout

- Every source needs an identified license + URL — no "probably fine" or platform-badge-only justification (Kaggle entries need independent verification per manifest §8)
- Ambiguous-license sources (NYC TLC, AWS Public Blockchain Data): point at the live source, don't re-host a copy
- SQL syntax must trace to an actual Zetaris doc page (`kbase.zetaris.com` or `data-fabric.readthedocs.io`), not generic Spark/Hive conventions
- Skim manifest §14 ("Known limitations") before treating any source as fully settled — most of those items are already called out in the relevant recipe's "Open questions" section

## Suggested execution order

1. Phase 0 (baseline) — quick, unblocks everything else
2. Phase 1 (install guide) at least far enough to get a local docker-compose Zetaris instance running — unblocks the Parquet/CSV recipe's two open items
3. Finish the Parquet/CSV recipe (FUTURES.md priority 0) against that instance
4. Work down the FUTURES.md priority list one recipe at a time, updating status as each closes
5. Phase 3 (top-level README/LICENSE-NOTES) incrementally alongside recipe work, not saved for the end
6. Kafka (FUTURES.md priority 11) only after its verification gate is explicitly resolved
