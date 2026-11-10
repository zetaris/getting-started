# Status

Live checklist for `examples/help-app`. Updated 2026-11-09 (Phase 2 of 8).
Everything below was run against Zetaris Lightning 2.4.3.1 in a single-machine
local Docker deployment, with a Milvus already running locally and a local
Ollama (`gemma3:4b`, `nomic-embed-text`). One run each unless stated. "Verified"
is not used here; it is reserved by CONTRIBUTING.md.

## Smoke checklist from the seed bundle (Phase 0)

| Step                                                                                           | Result                                                                                           |
| ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 1. `VERIFY PIPELINE SPEC` accepts the ingest and search specs                                  | Ran: accepted (ingest spec).                                                                     |
| 2. Collection plus ingest over a few files, `LIMIT 100000`; Milvus count equals part count     | Ran on this repo's `docs/` (641 parts, 641 rows). `LIMIT 1` wrote 100 of 641.                    |
| 3. `RUN PIPELINE ON 'vs_search'` returns passages with the file prefix; expected file in top 3 | Ran: yes for a USL question.                                                                     |
| 4. `INSERT` one row and read back; NULL for an omitted column                                  | Ran against a scratch table in the local Postgres: appends, NULL for omitted, base64 round-trip. |
| 5. USL with FK; `RUN DQ` form                                                                  | Ran: `RUN DQ <column> TABLE <namespace>.<usl>.<table>` works; 100 records, 77 valid, 23 invalid. |
| 6. LLM step                                                                                    | Ran against local `gemma3:4b` only. Larger models on other hosts not re-run **[LLM]**.           |
| 7. Items marked [D]                                                                            | The vector-Postgres search was re-run once; the pipeline JDBC sink load speed was not.           |

Fixes to the seed bundle: `sql/06` needs the full `VSCHEMA` column list;
`RUN DQ` form added; `RUN PIPELINE` text containing `compile usl`,
`activate usl`, `run dq`, `show dq` or `register dq` fails to parse (escaped in
`core/specs.ts`). Details are in the companion guide, section 9.

## Phases

| Phase                 | State                                                                                                                                                                                                                                                                                                                                                                                             |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 Orientation         | Done (above).                                                                                                                                                                                                                                                                                                                                                                                     |
| 1 Corpus and chunking | Done. `deno task help:verify --corpus`: 78 files (equals `find`), 1,237 segments, 798,526 bytes, longest segment 1,299 characters. 9 unit tests pass.                                                                                                                                                                                                                                             |
| 1b Kbase corpus       | Done (see Phase 1b below).                                                                                                                                                                                                                                                                                                                                                                        |
| 2 Store and ingest    | Done. Re-run 2026-11-10 over both corpora: 2,347 segments (repo 1,254 + kbase 1,093) in 24 batches, about 5 minutes, Milvus count 2,347. Both known-question checks pass; `help_app.help_search` registered and `SELECT` returned 100 rows. `help_answer` is registered only when `OLLAMA_URL` is set; not registered here. The earlier repo-only run (1,237 segments, about 196 s) was replaced. |
| 3 Query core          | Done. Search 10/12; Answer run on all 15 with `gpt-oss:20b`. SQL scripts now indexed (2,767 segments); the REST answer is now a faithful template, the USL activate answer is still wrong. Details in evidence.md. See Phase 3 below and [evidence.md](evidence.md).                                                                                                                              |
| 4 USL and VDM         | Done. See Phase 4 below.                                                                                                                                                                                                                                                                                                                                                                          |
| 5 App shell and Ask   | Done. See Phase 5 below.                                                                                                                                                                                                                                                                                                                                                                          |
| 6 Docs and feedback   | Done. See Phase 6 below.                                                                                                                                                                                                                                                                                                                                                                          |

## Open items from Phase 2

- **A known-question miss.** "How do I register a REST API source as a Zetaris
  table?" did not put `open_data/rest_apis/HOWTO.md` in the top 3 files (it
  ranked 5th); "How do I onboard a REST API source?" ranks it 1st. The
  post-ingest check now uses the second phrasing, changed after seeing the miss.
  The first phrasing belongs in the Phase 3 question set as a hard case.
- **`compose/docker-compose.yml` has not been run.** It carries no image tag.
  The example was tested against an existing Milvus on the default ports.
- **Segment count.** The plan's estimate was about 1,000; heading-aware
  segmentation gave 1,237. The pilot found heading-aware splitting gave no
  retrieval gain and more chunks; Phase 3 should compare it with plain 1000/900
  windows on the question set before keeping it.
- **Corpus size changes** as this example's own README and docs are added to the
  repo (they are part of the corpus).
- **Not tested:** concurrent ingest, other Zetaris builds, Milvus version (the
  version of the Milvus used here was v3.0.5; behaviour on others is unknown).

## Phase 1b: Kbase snapshot (2026-11-10)

- **Gate.** Sitemap pages 233 = 171 converted + 59 image-only + 3 non-content
  (`kb-404`, `kb-search-results`, `knowledge`). Every sitemap page is accounted
  for in `corpus/kbase/manifest.json`.
- **Template.** Page text sits in `article.knowledgebase-post`. The SQL Manual
  is a second template (Sphinx-style `div.section` blocks, with only the word
  "test" in the article wrapper); a fallback handles it (48,876 characters, 208
  fenced blocks). Only that page was found to need it.
- **Spot-check of 5 pages** (SQL Guide, an internal-network troubleshooting
  page, the 2.4.1.0 release note, the support FAQ page, a how-to): text reads
  cleanly, SQL and shell blocks are fenced, no credentials remain. Not checked
  page by page: the other 166.
- **Redaction** is regex-based and over-matches: it replaced documentation
  placeholders (for example `password=<your_password>` and a `token@host` URL)
  as well as the e-mail addresses of named employees. 37 pages needed at least
  one replacement; counts are in the manifest. It can also eat a word after
  `password:` in prose.
- **Skipped as image-only (text only in v1):** 59 pages, mostly step-by-step
  how-tos made of screenshots (the Query Builder, SQL editor, Cloud Gateway,
  coding-agent connection guides). Their slugs are in the manifest with status
  `skipped-textless`. Pages that mix text and screenshots were kept, with the
  image links (query strings removed) and no alt text, since most images have
  none.
- **Kinds.** The kind labels come from slug and title patterns and are weak: 132
  of 171 pages are `other`. Treat `kind` on kbase pages as provisional.
- **SQL Guide** is marked "CURRENTLY IN REVISION" on the live page; the snapshot
  says so.
- **Not covered:** per-page change detection (`help:sync-kbase`), and whether
  any page is internal or customer-specific (the README asks for that check
  before publishing).
- **Counts.** About 814,000 characters and 1,093 segments for the kbase; the
  repo corpus is 80 files and 1,254 segments (it grew by this example's own
  docs).

## Command reference vs the Kbase SQL Manual (2026-11-10)

Question: is `docs/guides/zetaris-lightning-sql-commands.md` the same as the
Kbase SQL Manual? Answer: **similar in part, not the same**, so both stay
indexed and are labelled by corpus. This was a comparison of statement forms,
not a line-by-line read.

- The repo reference has about 138 statement forms: USL, DQ, pipelines, VDM,
  REST, Hive and Glue.
- The Kbase SQL Manual has about 54: SELECT and the function reference, older
  per-vendor `CREATE DATASOURCE`, `ANALYZE DATASOURCE TABLE`, `CACHE`/`UNCACHE`,
  partitioning, CSV import.
- About 19 forms overlap. The three compared closely
  (`CREATE LIGHTNING DATABASE`, `REGISTER DATASOURCE TABLES`,
  `CREATE LIGHTNING FILESTORE`) agree.
- The Kbase SQL Guide is a third, smaller set (about 18 forms).

## Phase 3: query core (2026-11-10)

Added `core/rank.ts`, `core/prompt.ts`, `core/query.ts` and `scripts/smoke.ts`
(15 questions in `core/smoke_set.ts`). 24 unit tests pass. Results and caveats
are in [evidence.md](evidence.md). Not done: the Answer side was never run, and
the segmentation comparison (heading-aware vs plain windows) is still open.

## Phase 4: USL and data mart (2026-11-10)

Built: a Postgres service (`compose/docker-compose.postgres.yml`, Postgres
16.15), `sql/01` to `03`, `core/catalog.ts` and `scripts/build_usl.ts`
(`deno task help:usl`, `--dry-run`, `--rebuild`). 30 unit tests pass.

Gate results, all on the local instance **[S]** (one build, then a rebuild):

- Counts through the USL equal Postgres counted directly: `docs` 309, `chunks`
  2,775, 0 orphans. `search` returns 100 rows. `answers` returns its row (the
  LLM ran). `pins`, `pin_events` and `pin_scores` are 0, as expected.
- Data quality: the `chunks.path` foreign key rule reports 2,775 checked, 2,775
  valid, 0 invalid. It is not vacuous: with one orphan chunk inserted it
  reported 2,776 / 2,775 / 1, and 0 invalid again after the orphan was removed.
- The mart: `help_mart.doc_catalog` 309 rows, `answer_scores` 0 rows (no pins
  yet). It still returned 309 after `--rebuild` replaced the USL underneath it.
- `--rebuild` re-run end to end, after adding `--skip-exists` for the mart (it
  failed on the first try because the mart existed).

Found:

- `COMPILE USL` needs the namespace to exist first
  (`CREATE NAMESPACE IF NOT EXISTS`); it was already in the AGENTS notes and I
  missed it the first time.
- `help_answer.contexts` is an array, which a USL rejects by the known rule, so
  `answers.contexts` is `concat_ws(...)` of it. I avoided the array by design
  and did not test the rejection here.
- Zetaris `INSERT` appends only and there is no way to clear a table from it, so
  refilling means a `TRUNCATE` in Postgres.
- The corpus now has 309 docs and 2,775 segments; the Milvus index holds 2,767
  (before this phase added SQL files). Re-ingest to realign.

No construct was rejected, so there is no `known_to_fail` pair. Not done or not
tested: pin rows through the USL (Phase 6), the Milvus compose file (still never
run), teardown of the datasource and mart.

## Phase 5: app shell and Ask (2026-11-10)

Built: Fresh 2 + Vite app (`main.ts`, `routes/`, `islands/`, `components/`,
`design/tokens.css`), the Ask page, the Status page, `/api/ask` and
`/api/status`, `core/ask.ts` (flow and error mapping), `core/limit.ts`,
`core/status.ts`, `scripts/start.ts`, and a Playwright suite in `e2e/`.

Gate results **[S]** (one run each):

- `deno task check` clean; `deno task test` 42 unit tests pass.
- e2e: 17 tests pass (desktop 15, phone 2) against the mock: ask and see
  sources, Answer mode, example chip, empty question (nothing sent), no matches,
  Zetaris down (clear message, no host, no SQL), a Zetaris error with server
  text that must not appear, Answer disabled without an LLM, bad JSON and
  oversized body, one Answer at a time per session (429 on the second), theme
  toggle persists, no console errors, no sideways scroll at phone width.
- Live, against the real stack: search 0.2 to 0.4 s; Answer about 4 to 5 s with
  `gpt-oss:20b`; the PUDL question returns the query from
  `examples/pudl-chart/query.sql`; the status page reports every check OK.
  Screenshots at desktop and phone widths are in `docs/screenshots/`.

Differences from the plan, on purpose:

- No separate `/api/search`: Search only is a mode of `/api/ask`.
- No `AnswerStream` island: the pipeline returns the whole answer, so there is
  nothing to stream.
- System fonts instead of Plus Jakarta Sans, so the app makes no requests to a
  font CDN. Colours are atlas's tokens.
- Answer text was plain text in Phase 5; Phase 6 renders it as safe Markdown.
- No Docs, Pinned or Candidates pages yet (Phases 6 and 6b).

Found:

- Built server code resolves `import.meta.url` inside `_fresh/`, so file paths
  must come from the working directory (the app folder). The tasks run from
  there; running the server from elsewhere breaks the Status page's last-ingest
  and whole-file reads.
- `nodeModulesDir: "manual"` changed how `turndown` is typed in the older Kbase
  code; it now has an `any` cast with a comment.
- The sources are ordered by similarity plus the keyword bonus, so the displayed
  similarity is not strictly descending; the page says so.
- The e2e mock cannot catch a change in what real Zetaris returns; the live
  check above covers that for now.

Not done or not tested: WebKit and Firefox runs (Chromium only), a keyboard-only
walkthrough beyond the skip link and labelled controls, running the server from
another directory, the Milvus compose file.

## Phase 6: docs browser and feedback (2026-11-10)

Built: `/docs` (index, file view with chunks, Kbase view), `/pins`, the Past
answers panel, `POST /api/pins` and `/api/pin-event`, safe Markdown
(`core/markdown.ts`), `core/pins.ts`, `core/docs.ts`, `core/security.ts`
(same-origin check on POSTs), `core/http.ts`, and e2e specs `pins` and `docs`.

Gate (pin, like twice, ask a paraphrase) **[S]** (one run, real stack): an
Answer-mode ask pinned in about 1 s; pinning again returned the existing pin;
two likes (two names) gave likes 1 then 2; the paraphrases "What are the steps
to clone a pipeline in Zetaris?" (similarity 0.911) and "how can I make a copy
of an existing pipeline" (0.868) showed the pin first with likes 2; "capital of
France" showed none. Postgres `pin_events` had 2 `like` rows, USL `pin_scores`
likes = 2, USL `pin_events` count = 2, and `help_pins` held 1 entry. The test
rows were removed afterwards.

Also checked: `deno task check` clean; 70 unit tests; 33 e2e tests (pin once,
like persists, paraphrase shows the pin with its likes, Use this answer calls no
model, unrelated question shows nothing, stale flag, cross-site POSTs 403,
script in model output stays inert, docs index and filter, traversal and
uncatalogued paths 404, phone width). Live: `/docs`, a repo file (16 chunks), a
SQL file and a Kbase page return 200; 9 traversal variants return 404; two test
pins with a wrong git sha and a missing file were flagged stale, the real one
was not.

Found:

- **Precision of the threshold.** Similarity cannot tell the same question from
  the same topic. With one pin ("clone a pipeline"), at 0.82 these also showed
  it: "create a new pipeline" 0.869, "delete a pipeline" 0.846, "clone a git
  repository" 0.847, "clone a data source" 0.842, "schedule a pipeline daily"
  0.834. "What is a virtual pipeline?" (0.806) and unrelated questions (0.73 to
  0.76) did not. So the panel names the pinned question and using it is opt-in.
  See [evidence.md](evidence.md).
- The remembered Answer mode is restored after the page is live, which can
  override an early click; the e2e test waits for it.

Differences from the plan: "Use this answer" still lets Answer mode run the
model for the ask itself (the panel sits beside the results). Example mode and
Candidates are Phase 6b and not started.

Not done or not tested: Chromium only; no Content-Security-Policy header;
staleness is only as current as the last `help:usl` fill; a pin vector with no
row is ignored, and a retry after a partly failed embed could hit a duplicate
key; no user identity (names are free text). Phases 6b, 7 and 8 not started.
