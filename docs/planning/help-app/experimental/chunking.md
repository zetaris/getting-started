# Chunking: keep the split in Deno

Experimental note. This does not change the splitter or the live index. Re-ingest only after this comparison is accepted and a run is asked for.

## Judgment

Deno should own the boundaries. The Zetaris Chunking node stays in the pipeline because the Embedding node reads `llm_chunk` from it, but it stays a 1,500-character guard so it does not cut again. That is the pattern already in [`examples/help-app/core/specs.ts`](../../../../examples/help-app/core/specs.ts) and [`examples/help-app/core/corpus.ts`](../../../../examples/help-app/core/corpus.ts).

Letting the node split a whole file was measured and lost provenance. Section 9.3 of [`docs/guides/zetaris-lightning-sql-companion.md`](../../../guides/zetaris-lightning-sql-companion.md) records that the node writes its `REPO/FILE/…` header only on a document's first chunk: on this repo's `docs/`, 49 of 819 chunks carried it. Later chunks cannot be cited. The app avoids that by sending one segment per row, with `repo`, `file`, `part`, and `section` as columns.

The node's other strategies are a poor fit for this index:

- **SemanticChunking** produced chunks up to 15,406 characters. `e5-small-v2` reads on the order of 1,000 characters, so most of that text never enters the vector.
- **AgentChunking** called `localhost:11434` from inside the Zetaris container and failed.
- A heading-aware split, tried on one document, gave no retrieval gain and about 24% more chunks than plain windows.

The current Deno overlap is easy to over-read. `OVERLAP` is 100, but `windows()` applies it only when one paragraph or code block is longer than 1,300 characters. Neighboring sections are packed end to end with no shared text.

Chunking will not fix every known miss. "What changed in Zetaris release 2.4.1.0?" fails because the release-note page never enters the 100 dense candidates. That needs a title or version lookup beside the vector search. The bake-off below treats it as a control: a chunking change that only "fixes" that question is not a chunking win.

## Experiment

Compare three splitters on the existing 12 in-scope smoke questions in [`examples/help-app/core/smoke_set.ts`](../../../../examples/help-app/core/smoke_set.ts). Use a new Milvus collection per variant. Leave `help_index` in place.

1. **Current.** Heading-aware pack to about 1,000 characters. Overlap only inside an oversized unit.
2. **Windows.** Plain 1,000-character parts stepped every 900, the pilot pattern. File and part still travel as columns. Section is the nearest preceding heading, attached in Deno.
3. **Heading plus overlap.** Same as current, but each segment after the first in a file repeats the last 100 characters of the previous segment. Still capped so the Chunking guard does not re-split.

Score each variant the way [`examples/help-app/docs/evidence.md`](../../../../examples/help-app/docs/evidence.md) already does: expected file in the top 3 files after the current rerank, and how many segments were written. For the USL compile question, also record whether a passage that contains both the `ACTIVATE USL TABLE … AS` form and `MATERIALIZE` is among the passages sent to the model. One run per variant is enough to see a large difference. A one-question swing on 12 questions is not.

Adopt a variant only if it raises the top-3 hit count, or puts the USL activate passage into the answer context, without a large increase in segment count. Otherwise keep the current splitter.

A semantic merge in Deno is a later experiment, and only if the overlap run shows that heading cuts are the problem. Merge adjacent paragraphs while they stay under 1,000 characters. Do not call the Zetaris SemanticChunking node. Do not start that until the three-way comparison above is written into this note.

## Results (2026-11-13)

One run of each variant, searched through Zetaris and re-ranked at keyword weight 0.05, the same rule as [`examples/help-app/docs/evidence.md`](../../../../examples/help-app/docs/evidence.md). Each variant has its own Milvus collection. `help_index` still holds 2,797 rows and was not written. The runner is `deno task help:chunk-bakeoff` in `examples/help-app`. Ingest of each collection took about 6 minutes. Exact duplicate chunk texts were dropped before the sink, because the sink uses the chunk text as its primary key.

The model context for the USL question is the top 6 passages after re-ranking. That question does not ask for a query in the sense `isCodeQuestion` uses, so Answer mode does not send whole files.

| Variant | Collection | Segments written | Milvus rows | Top-3 hits of 12 | USL form in the top 6 | USL form anywhere in the 100 |
| --- | --- | --- | --- | --- | --- | --- |
| Current | `help_chunk_current` | 2,777 (30 duplicate texts dropped) | 2,777 | 10 | no | yes |
| Windows | `help_chunk_windows` | 2,354 | 2,354 | 10 | no | yes |
| Heading plus overlap | `help_chunk_overlap` | 2,791 (16 duplicate texts dropped) | 2,792 | 10 | yes | yes |

The same two questions miss for every variant. `usl-compile` ranks 7th, 6th, and 6th. `kb-release` ranks 16th, 12th, and 17th. The release-note page stays outside the 100 dense candidates' top files, which is what the control predicted.

The overlap variant's "yes" is one passage, `docs/plans/archive/usl-build-plan.md`, in position 6. It lists "ACTIVATE USL TABLE ... AS SELECT" and "MATERIALIZE USL TABLE" in a build checklist. The commands guide, which is the expected file, is still outside the top 3. The other five passages sent to the model do not contain that pair. Windows puts the same kind of passage in the 100 retrieved rows and not in the top 6. Current does the same.

Milvus holds one more overlap row than segments sent (2,792 against 2,791). One segment was long enough, once the Chunking node's header was added, that the 1,500-character guard split it.

**Decision: keep the current splitter.** The top-3 hit count did not move, and a single checklist sentence in an archived plan is not the commands-guide passage this question misses. Windows uses about 15% fewer segments and scores the same. Heading cuts are not what moves these questions, so the semantic-merge experiment stays unstarted. The default in `splitDocument` is unchanged.
