# Plan: Bring repo docs to a production footing

**Status:** ✅ Executed. README rewritten, `docs/plans/archive/` created with 5 plan docs + root `handoff.md` moved into it (each with a supersession banner), `FUTURES.md` and USL status docs refreshed, and cross-links fixed. Kept here as the record of what changed and why.
**Superseded note (later session):** §2 item 3 and §4's table below decided to keep `quickstart-data-manifest.md` at the repo root. A follow-up review found it duplicated the `docs/plans/recipes/*.md` files in intent, not just content — its content has since been dispersed into `FUTURES.md` and the recipes, and the manifest itself moved to `docs/plans/archive/quickstart-data-manifest.md`. Nothing remains at the repo root except `README.md`, `LICENSE`, and `.env.example`.
**Trigger:** README.md and several `docs/plans/` entries describe an earlier state of the repo. Five things have since landed: the install + test-record guides (`docs/install/`), full REST source testing (including the advanced sources), the CREATE/SELECT SQL split, a built-and-tested USL, and the Zetaris SQL companion guide (`docs/guides/`).

This session synced the worktree to the current `main` (`git merge origin/main --ff-only`, fast-forwarding two merges that weren't in this branch yet: the CREATE/SELECT split and a USL null-handling fix) before auditing, so the findings below reflect the actual committed state, not a stale snapshot.

---

## 1. What I could confirm directly, and what I couldn't

Checked every claim against the committed repo rather than taking the list at face value:

| # | Claimed event | Verified in repo? |
|---|---|---|
| 1 | Install guide + test guide, up to date | ✅ Yes — [`docs/install/updated_zetaris_installation_guide.md`](../install/updated_zetaris_installation_guide.md) and [`docs/install/zetaris-installation-test-record.md`](../install/zetaris-installation-test-record.md), dated 2026-09-24, local path fully tested, AWS path checked on paper only. |
| 2 | All REST sources tested, including advanced ones | ⚠️ **Partially confirmed.** [`open_data/rest_apis/rest-api-sources.md`](../../open_data/rest_apis/rest-api-sources.md)'s own quick-reference table (post-sync) still lists **source 6, NASA DONKI, as "not yet tested"** and **source 3, Open Food Facts, as "partially live-tested"** (queries 1-7 confirmed, query 8 not reached). Source 4 (Singapore PM2.5) is a documented permanent failure case, not a pending test. If 3 and 6 have since been finished, the source docs need updated status lines with dates/results — I don't have those results to write in on your behalf. |
| 3 | SQL split into CREATE and SELECT | ✅ Yes, but only just — this was `4b25da1`/PR #10 on `origin/main`, not yet in this branch until the sync above. Every `open_data/rest_apis/sql/*` and `open_data/parquet_csv/sql/*` file is now a `*_create.sql`/`*_select.sql` pair. There's also a dedicated plan doc for it ([`docs/plans/archive/rest-parquet-create-select-split-plan.md`](archive/rest-parquet-create-select-split-plan.md)) whose header still said "🔲 Not started" even though the work is done — now fixed and archived, see §7. |
| 4 | USLs built, corrected, tested | ⚠️ **Not confirmed in committed docs.** `open_data/usl/HOWTO.md` still says "**Status: not yet live-tested**" and [`docs/plans/usl-simple-advanced-build-plan.md`](usl-simple-advanced-build-plan.md)'s header still says "nothing in this plan has been run against a live Zetaris instance yet." There *is* a recent commit (`8f18f4f`, "Fix SQL queries in USL scripts to handle null values and document errors") suggesting real test runs happened and surfaced bugs — but the status headers were never flipped to reflect it. |
| 5 | Zetaris SQL companion guide in `docs/guides/` | ✅ Yes — [`docs/guides/zetaris-sql-companion.md`](../guides/zetaris-sql-companion.md), cross-linked from the USL and split-plan docs already. |

**Net effect:** the repo is further along than README.md says, but *not quite* as far along as items 2 and 4 in your list — or it is, and the status headers in the source-of-truth docs (`rest-api-sources.md`, `usl/HOWTO.md`) just weren't updated after the last test pass. I'd rather surface that gap now than write a README claiming "fully tested" over docs that say otherwise.

## 2. Open questions — resolved

1. **DONKI and Open Food Facts:** not retested (session-limited). Remain **pending** — `rest-api-sources.md`, `recipes/01-rest-json-apis.md`, and the README will keep their current "not yet tested" / "partially tested" language, not be marked done.
2. **USL:** believed to be working after the `8f18f4f` null-handling fix, but not yet confirmed by the person who ran it. Docs will reflect this honestly as **"fixes applied, result believed passing, pending confirmation from the committer"** — not flipped to a flat "tested and working" until that confirmation lands. The cross-USL foreign-key limitation and the deferred-materialization note in the USL build plan stand as-is; nothing suggests either was resolved.
3. **Root-level `handoff.md` / `quickstart-data-manifest.md`:** confirmed — keep `quickstart-data-manifest.md` at root, move `handoff.md` to `docs/plans/archive/`.

**Net change to §3/§6 below:** the README will present DONKI, Open Food Facts, and USL with accurate, hedged status language (not "done"), and a short TODO note pointing at who/what unblocks each — rather than waiting on a second confirmation round before executing. If the committer later confirms USL or someone retests DONKI/OFF, that's a small follow-up edit to the same status lines, not a re-plan.

## 3. README.md rewrite

Replace the current "being built out one category at a time, nothing implemented" framing with the actual current state:

- **Status section:** installation is documented and tested (local path); REST APIs — table of real per-source status pulled from `rest-api-sources.md`, DONKI and Open Food Facts shown honestly as not-yet/partially tested rather than lumped in as done; Parquet/CSV status; USL section described as built with a recent null-handling fix, believed passing, pending confirmation from the committer (not claimed as a flat "tested"); SQL scripts now ship as CREATE/SELECT pairs — explain the convention once so users know what to expect in `sql/`.
- **"Getting Zetaris running"** section: point straight at `docs/install/updated_zetaris_installation_guide.md`, drop the "not ready yet, check back" language entirely.
- **New "Documentation map" section:** one place linking `docs/install/`, `docs/guides/zetaris-sql-companion.md`, `docs/plans/FUTURES.md`, and each `open_data/*/HOWTO.md` — right now a new reader has to discover these by browsing.
- **Repo layout section:** replace the "intentionally minimal, nothing here yet" note with the real tree (`open_data/{parquet_csv,rest_apis,usl}`, `docs/{install,guides,plans}`).

## 4. Disposition of `docs/plans/`

Plans accumulate status headers that go stale once the work lands. Proposed convention: keep `docs/plans/` for documents that still describe *upcoming or in-progress* work, and add `docs/plans/archive/` for plans whose work is done and are kept only as historical record (per this repo's own convention already stated in `zetaris-sql-companion.md`: "docs/plans/ is for plans to build or improve something," which stops applying once nothing is left to build).

| Doc | Real state | Disposition |
|---|---|---|
| [`zetaris-installation-guide.md`](zetaris-installation-guide.md) | Fully superseded — the real guide is `docs/install/updated_zetaris_installation_guide.md` | Move to `docs/plans/archive/`, add a one-line "superseded by `docs/install/...`" banner at the top |
| [`rest-parquet-create-select-split-plan.md`](rest-parquet-create-select-split-plan.md) | Executed (`4b25da1`), header not updated | Flip header to ✅ Done with the commit ref, move to `docs/plans/archive/` |
| [`REST-API-HANDOFF.md`](REST-API-HANDOFF.md) | Point-in-time session handoff (2026-09-19), now superseded by `rest-api-sources.md`'s live status table | Move to `docs/plans/archive/` as a historical record |
| [`zetaris-quickstart-data-repo.md`](zetaris-quickstart-data-repo.md) | Phase 0 checklist references files as "currently untracked" — long since committed; later phases overtaken by the real install guide and the recipe docs | Move to `docs/plans/archive/`; `FUTURES.md` + `recipes/*` are now the live roadmap, this doc's job is done |
| [`edgar-sic-enrichment-plan.md`](edgar-sic-enrichment-plan.md) | Mostly done (§8), but still the canonical research trail behind source 10 and the USL contrast — actively cross-linked | Keep in `docs/plans/`, tighten the header, no move |
| [`usl-simple-advanced-build-plan.md`](usl-simple-advanced-build-plan.md) | Header contradicts actual test state (§2) | Update status header once §2 is answered; keep in `docs/plans/` while USL's own follow-ups (materialization, cross-USL FKs) remain open |
| [`FUTURES.md`](FUTURES.md) | Roadmap index; status column and the install-guide link are stale | Keep, refresh in place (§5) |
| `recipes/00-parquet-csv.md`, `recipes/01-rest-json-apis.md` | Living checklists, mostly accurate but need the final DONKI/OFF status once confirmed | Keep, update status lines |
| `recipes/02` through `recipes/11` | Still genuinely "planned, not started" | Keep as-is |
| Root `handoff.md` | One-time Cowork→Claude-Code handoff, fully superseded | Move to `docs/plans/archive/` (§2, item 3) |
| Root `quickstart-data-manifest.md` | Still the only detail for ~9 unbuilt categories | Keep at root, no change |

## 5. `FUTURES.md` refresh

- Fix the prerequisite table's link from `zetaris-installation-guide.md` (plan doc, now archived) to `docs/install/updated_zetaris_installation_guide.md` (the real guide), and mark that row ✅ Done instead of 📋 Planned.
- Update the Parquet/CSV and JSON/REST APIs rows' status text to match the corrected `rest-api-sources.md` table from §2/§6.
- Add a short line noting the USL work exists as a third, contrast-only track outside the main priority-ordered list (it already isn't numbered 0-11, so it's easy to lose track of).

## 6. Source-status accuracy pass

- `open_data/rest_apis/rest-api-sources.md` and `docs/plans/recipes/01-rest-json-apis.md`: leave DONKI and Open Food Facts's status lines as-is (still accurate) — no change needed there, just make sure the README doesn't overstate them.
- `open_data/usl/HOWTO.md`'s "Status: not yet live-tested" line and `docs/plans/usl-simple-advanced-build-plan.md`'s header: update to reflect the `8f18f4f` fix and the believed-passing-pending-confirmation state, referencing that commit. Leave the cross-USL FK and deferred-materialization caveats untouched — nothing indicates they've changed.
- Add a one-line follow-up note (in `usl-simple-advanced-build-plan.md`'s header, not a new doc) asking for the committer's confirmation, so it's easy to flip to a clean "done" later without re-deriving context.

## 7. Execution order

1. Update the source-of-truth status docs first (§6 — `usl/HOWTO.md`, `usl-simple-advanced-build-plan.md` header), since the README and `FUTURES.md` rewrites both quote them.
2. Create `docs/plans/archive/`, move the six docs from §4 (five plan docs + root `handoff.md`), add supersession banners.
3. Refresh `FUTURES.md` (§5).
4. Rewrite `README.md` (§3).
5. Grep the whole repo for links to anything moved in step 2 and fix them (`FUTURES.md`, `HOWTO.md`s, and any cross-references between plan docs all link to each other by relative path).

§2's questions are answered — ready to execute on your go-ahead.
