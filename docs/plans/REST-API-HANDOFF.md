# REST API work — handoff to next session

Scoped context for picking up `open_data/rest_apis/` work without re-deriving what's already been found. Companion to `handoff.md` (the original Cowork → Claude Code handoff for the whole repo) and `docs/plans/FUTURES.md` (the full category roadmap) — this doc is narrowly about the REST API package.

## Where everything lives

- `open_data/rest_apis/HOWTO.md` — full `CREATE LIGHTNING REST TABLE` / `CREATE SCHEMASTORE VIEW` syntax reference, confirmed gotchas, the JSON-shape taxonomy, and a suggested testing order (§3)
- `open_data/rest_apis/rest-api-sources.md` — catalog of all 9 candidate sources: license, shape, status, per-source detail
- `open_data/rest_apis/sql/01_edgar_company_facts.sql` through `09_abs_data_api.sql` — one script per source
- `docs/plans/recipes/01-rest-json-apis.md` — the tracked plan and work-items for this category
- `docs/plans/recipes/00-parquet-csv.md` — the sibling filestore-table package; a couple of findings below apply to both, not just REST

## Status as of 2026-09-19

| # | Source | Status |
|---|---|---|
| 1 | SEC EDGAR XBRL Company Facts | ✅ Live-tested — 7 companies working |
| 2 | PokéAPI | ✅ Live-tested — Pikachu + Charizard, cross-Pokémon views, 6 example queries all working |
| 3 | Open Food Facts (live API) | 📋 Scripted, real JSON shape investigated, not yet run against Zetaris |
| 4 | Singapore data.gov.sg PM2.5 | 📋 Scripted, not yet tested |
| 5 | NASA NeoWs (`/neo/browse`) | 📋 Scripted, not yet tested |
| 6 | NASA DONKI (CME) | ⚠️ Scripted, high risk — top-level JSON **array**, not object; unverified whether `CREATE LIGHTNING REST TABLE` accepts that at all |
| 7 | Eurostat REST API | ⚠️ Scripted, high risk — JSON-stat 2.0 format, no array-of-structs anywhere to flatten; likely drop candidate |
| 8 | Statistics Canada WDS (`getChangedCubeList`) | 📋 Scripted, not yet tested — simplest shape of the whole batch, good smoke test |
| 9 | Australian ABS Data API (CPI) | ⚠️ Scripted, high risk — SDMX-JSON 2.0.0, same risk class as Eurostat plus an extra layer of compound dynamic keys; likely drop candidate |
| — | JSONPlaceholder | 🔴 Not scripted at all yet — wasn't part of the 2026-09-19 investigation batch |

**Next concrete step:** test sources 3–9 one at a time in the order `HOWTO.md` §3 suggests (lowest-risk/simplest shape first: 8 → 3 → 4 → 5 → 6 → 7 → 9), fix what breaks, drop what can't be fixed, update `rest-api-sources.md` and the recipe plan's status as each one resolves — same loop already used successfully for EDGAR and PokéAPI.

## Confirmed Zetaris findings (some apply beyond just REST)

1. **`CREATE LIGHTNING DATABASE <name> DESCRIBE BY "..."` is a required prerequisite** before anything can `FROM <name>` it — missing from this package's (and the Parquet/CSV package's) original scripts, now fixed everywhere in both.
2. **`CREATE SCHEMASTORE CONTAINER` can only be run once per name** — no `IF NOT EXISTS`, throws `LightningDdlParseException` on a second attempt. No workaround found yet; open question is whether Zetaris exposes any query/API surface outside the SQL Editor that an external script could use to precheck existence.
3. **Zetaris always signs S3 requests** (Parquet/CSV finding, not REST, but same instance) — no anonymous/credential-less mode exists; a real AWS IAM key is required even for publicly-readable buckets.
4. **Mixed-case and reserved-word JSON field names need backtick-quoting** — e.g. `` `entityName` ``, `` fact.`start` ``.
5. **Nested dot-access through an exploded array goes at least 2 levels deep** — confirmed via PokéAPI's `ability.ability.name`. This was an open question; resolving it favorably derisks other deeply-nested sources (NeoWs in particular).
6. **JSON shape taxonomy** (`HOWTO.md` §2) — only the first of these four is actually confirmed working; the rest are scripted best-effort, unconfirmed:
   - **Confirmed:** top-level object + array-of-structs (EDGAR, PokéAPI)
   - **Unconfirmed:** array-of-structs nested under a non-array wrapper key (Singapore PM2.5, source 4)
   - **Unconfirmed, real risk:** top-level JSON array with no wrapping object (DONKI, source 6)
   - **Unconfirmed, real risk:** SDMX-family sparse multi-dimensional formats (Eurostat, ABS — sources 7, 9)
7. **Possible response-truncation bug** on EDGAR — a table's row count came back suspiciously low in a way that looks like the connector truncating mid-array. Not confirmed as a real bug vs. some other explanation; `HOWTO.md` §4 has the verification method (compare Zetaris's row count against a direct `curl`/`jq` count).

## Environment notes

- AWS credentials used for the Parquet/CSV package's live testing live in a gitignored `.env` at the repo root (never committed) — ask the user if you need them re-provisioned, don't assume they're still valid.
- The Zetaris SQL Editor instance itself is the user's own — ask for the URL/access rather than assuming a fixed one; it wasn't recorded anywhere in this repo (intentionally — it's environment-specific, not a project fact).
- A harness bug can cause the Write/Edit tools to wrongly refuse file edits, claiming the session is "still bound to worktree X" after that worktree was deleted outside the normal create/exit lifecycle. If hit: work around via Bash (write to scratchpad, `cp` into place; edit via Python/`sed` instead of the Edit tool) or just start a fresh session — a new session won't carry the stale binding.
