# Vector store notes

**Decision: Milvus.** The help app ships on Milvus. OpenSearch was **not tried**
(the plan made it a gated spike, kept for Phase 8), so there is no OpenSearch
result to report. This file records why Milvus, what was run, and what the
choice costs.

## What was run (Zetaris Lightning 2.4.3.1, local Docker)

| Fact                                                                                                                   | Source                          |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| The pipeline nodes `VectorStoreSink` and `VectorStoreSearch` work against Milvus through the Zetaris REST API          | the ingest and every search run |
| The collection must exist before the sink runs; the app creates it through Milvus's REST API                           | `core/milvus.ts`                |
| The sink's primary key is the chunk text, so identical chunks collapse                                                 | companion guide, section 9      |
| A search returns at most 100 rows                                                                                      | companion guide, section 9      |
| `RUN PIPELINE ON 'sink'` needs `LIMIT 100000`; a small limit silently writes a fragment                                | companion guide, section 9      |
| Re-ingest of 2,347 segments (repo and Kbase, before the SQL scripts were added) took about 5 minutes in batches of 100 | STATUS.md, Phase 2              |
| The count in Milvus can lag the end of a sink run, so the ingest polls before it compares counts                       | STATUS.md                       |
| Pinned answers use a second collection (`help_pins`) in the same Milvus                                                | Phase 6                         |

Search runs per question inside the pipeline spec; the saved relation
(`help_search`) has a fixed question, so the app does not use it for asks.

## Why Milvus

- It is the store the pilot and every later run used; the sink, the search node
  and the collection call are all exercised.
- The pipeline does the embedding (the Embedding node), so the app never sends
  vectors to the store.
- Nothing here needed a feature Milvus lacks.

## What it costs

- A second service to run next to Zetaris.
  [compose/docker-compose.yml](../compose/docker-compose.yml) is provided but
  **has not been run**; the example was tested against a Milvus already running
  on the default ports. Pin an image tag you have tested; none is recorded here.
- No delete path in the pipeline: re-ingesting means dropping and recreating the
  collection (`help:ingest` does this, and refuses a non-empty one without
  `--yes`). That is why incremental re-ingest by `git_sha` is a Phase 8 idea.
- Milvus is not a Zetaris data source in this build; it is only a sink and a
  search node, so the vector rows cannot be joined in SQL.

## OpenSearch: not tested

The pipeline designer lists OpenSearch. The plan's decision rule was to keep it
only if a spike ran the same two pipelines (ingest and search) in under half a
day. That spike has not been done. What is known from the plan, not from a run:
its neural query takes `query_text` and a model id, so an app would not need to
send floats, and its SQL plugin is not ANSI. Treat both as **[untested]**.

## Other things not tested

- PineCone (the other option in the designer).
- Postgres with pgvector as the store: one pilot comparison over 27,514 rows
  gave a top score of 0.875914 against 0.875904 from Milvus; see the companion
  guide, section 9. It was not built into the app.
- Milvus versions other than the one running here, and cluster deployments.
