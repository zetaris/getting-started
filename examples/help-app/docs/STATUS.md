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
| 1b Kbase corpus       | **Not started.** Needs the live page template inspected first.                                                                                                                                                                                                                                                                                                                                    |
| 2 Store and ingest    | Done. Re-run 2026-11-10 over both corpora: 2,347 segments (repo 1,254 + kbase 1,093) in 24 batches, about 5 minutes, Milvus count 2,347. Both known-question checks pass; `help_app.help_search` registered and `SELECT` returned 100 rows. `help_answer` is registered only when `OLLAMA_URL` is set; not registered here. The earlier repo-only run (1,237 segments, about 196 s) was replaced. |
| 3 to 8                | Not started.                                                                                                                                                                                                                                                                                                                                                                                      |

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
