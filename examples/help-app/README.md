# Help app: a RAG worked example on Zetaris

> **Status: in progress (Phase 4 of 8).** Corpus, ingest, the saved search
> relation and a search-only query core exist. The app, USL and VDM, and
> feedback do not yet. See [docs/STATUS.md](docs/STATUS.md) for what has been
> run and what has not. Nothing here is hosted: you run it yourself, on your own
> infrastructure.

This example turns the Markdown in this repository into a searchable help index,
and does as much of the work as possible inside Zetaris: the file text goes
through a pipeline of **SQLTable → Chunking → Embedding → VectorStoreSink**, and
a question goes through **VectorStoreSearch** (and, later, an LLM node). The
rules and gotchas it relies on are written up in the
[SQL companion guide, section 9](../../docs/guides/zetaris-lightning-sql-companion.md#9-rag-on-zetaris-chunking-embeddings-search-and-answers)
(draft). The guide states the rules; this example shows them in context.

## What you need

| Need              | Detail                                                                                                                                                                                                                                                     |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Zetaris Lightning | A running instance (local or AWS, per the [install guides](../../docs/install)), reachable over REST. The example was tested on Zetaris Lightning 2.4.3.1 in a local Docker deployment.                                                                    |
| Deno              | 2.9 or later (`deno --version`).                                                                                                                                                                                                                           |
| A vector store    | Milvus. [compose/docker-compose.yml](compose/docker-compose.yml) is provided but **has not been run** yet; the example was tested against a Milvus already running locally. About 1 GB of RAM is a reasonable floor for a corpus this size (not measured). |
| Postgres          | 16. [compose/docker-compose.postgres.yml](compose/docker-compose.postgres.yml) starts one on port 5434 (tested: 16.15, arm64, local Docker). It holds the doc and chunk catalogs and, later, the pin log.                                                  |
| An LLM endpoint   | Only for Answer mode (later phases): Ollama, or any server the Zetaris LLM node can reach. Search-only mode needs none.                                                                                                                                    |

The Zetaris containers must be able to reach Milvus (and Ollama). On a single
machine that means `host.docker.internal`, not `localhost`.

## Configure

Add the settings in [.env.example](.env.example) to the repo's `.env.local` (the
only env file the repo reads; it is gitignored). The Zetaris settings
(`ZETARIS_REST_URL`, `ZETARIS_API_KEY`, `ZETARIS_ORG_ID`) are the ones the other
scripts already use. No hostnames, tokens or model names are committed.

## Run it

From this folder:

```bash
deno task help:verify --corpus      # walk the repo's Markdown: files, segments, bytes
deno task help:ingest --dry-run     # show exactly what would be sent; changes nothing
deno task help:ingest               # create the collection, ingest, verify, register relations
deno task help:smoke                # 15 curated questions, search only, several keyword weights
```

`help:ingest` drops and recreates only the collection named by
`HELP_COLLECTION`, and refuses to drop a non-empty one without `--yes`. It
always sends `LIMIT 100000` on the sink run: a small `LIMIT` silently writes
only part of the data.

## The USL and the data mart

`deno task help:usl` registers the Postgres database in Zetaris as datasource
`help_pg`, fills its `docs` and `chunks` tables (one row per file and per
segment, written through Zetaris `INSERT`), then builds `help_usl` and
`help_mart` from the numbered scripts in [sql/](sql/). Start Postgres first:

```bash
docker compose --env-file ../../.env.local -f compose/docker-compose.postgres.yml up -d
deno task help:usl --dry-run   # the steps; sends nothing
deno task help:usl             # add --rebuild to drop and recompile help_usl
```

Set `HELP_PG_PASSWORD` (your own choice) in `.env.local` first; the other
`HELP_PG_*` settings are in [.env.example](.env.example). The password only
travels in the datasource statement and is never printed.

| USL table                          | Over                                    | Note                                                                                  |
| ---------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------- |
| `docs`                             | `help_pg.docs`                          | one row per file: path, corpus, title, kind, bytes, git_sha, chunk_count              |
| `chunks`                           | `help_pg.chunks`                        | one row per segment; `path` is a foreign key to `docs.path`                           |
| `search`                           | relation `help_app.help_search`         | a fixed question, 100 rows; a `SELECT` runs the search pipeline                       |
| `answers`                          | relation `help_app.help_answer`         | a fixed question; **a `SELECT` calls the LLM every time**. Do not join it to anything |
| `pins`, `pin_events`, `pin_scores` | `help_pg.pins` and `help_pg.pin_events` | empty until pins exist (Phase 6)                                                      |

Three queries to try in the Zetaris UI (the namespace is
`lightning.metastore.help_app_usl.help_usl`):

```sql
-- how much of each corpus is indexed
SELECT d.corpus, count(*) AS chunks
FROM lightning.metastore.help_app_usl.help_usl.chunks c
JOIN lightning.metastore.help_app_usl.help_usl.docs d ON d.path = c.path
GROUP BY d.corpus
```

```sql
-- the doc catalog by kind, through the data mart
SELECT kind, count(*) AS n FROM help_mart.doc_catalog GROUP BY kind ORDER BY n DESC
```

```sql
-- which files have the most segments
SELECT path, chunk_count FROM help_mart.doc_catalog ORDER BY chunk_count DESC LIMIT 10
```

Things to know:

- Zetaris `INSERT` only appends, so `help:usl` fills the catalog **once**. To
  refill after the corpus changes, run `TRUNCATE docs, chunks` in Postgres and
  run it again.
- The catalog is the corpus as the script walks it now. The Milvus index is only
  as current as the last `help:ingest`, so the two can differ until you
  re-ingest.
- These scripts are not in `open_data/manifest.json`: its `usl` kind runs
  scripts over REST alone, and these need a Postgres datasource created with a
  password and a filled catalog first.

## How it works (so far)

1. **Walk.** Every `*.md` and `*.sql` in the repo, skipping dot directories,
   `node_modules`, and the top-level `dist`, `site`, `tmp` and `reports`
   folders, plus this example's own `corpus/` and `docs/`.
2. **Segment in the app, not the pipeline.** Each file is cut at headings into
   segments of about 1,000 characters (code blocks kept whole where they fit).
   The Chunking node only acts as a guard (1,500 characters), because it writes
   its `REPO/FILE/…` header only on a document's first chunk. Giving every
   segment its own `repo`, `file`, `part` and `section` columns means every
   chunk carries provenance.
3. **Send as SQL.** Each segment becomes a `select` with base64-encoded values,
   so quotes and newlines in the Markdown cannot break the statement.
4. **Embed and store in Zetaris.** The Embedding node uses an in-engine model
   (default `e5-small-v2`, 384 dimensions). The Milvus collection is created by
   the script through Milvus's REST API, because the sink does not create it.
5. **Search.** `RUN PIPELINE ON 'vs_search'` with the question inside the spec.
   A saved relation `help_search` is also registered, but its question is fixed,
   and `SELECT` on a relation runs the whole pipeline.

## Tests

```bash
deno task test    # unit tests, no Zetaris needed
deno task check   # fmt, lint, type check
```

## Tags used in this folder

Claims are marked as in the companion guide: **[C]** repeated, **[S]** one run,
**[U]** untested. "Verified" is reserved for statements that ran on a live
instance, per [CONTRIBUTING.md](../../CONTRIBUTING.md).
