# Evidence: Phase 3 search smoke run

Run 2026-11-10 against the live index `help_index` (2,347 segments, E5 384-d,
COSINE), search-only, Zetaris 2.4.3.1 local. `deno task help:smoke`; search
results are cached in `.cache/` so every weight sees the same 100 candidates per
question.

## Set-up

15 questions in `core/smoke_set.ts`: 3 SQL-example, 3 "where is X", 6 other
in-scope (3 repo, 3 Kbase), 3 out-of-scope. Expected files were written down
before the first run. A hit is an expected file among the top 3 **files** after
re-ranking (`score = similarity + weight x keyword share`).

The plan's gate reads "12 of 15". Out-of-scope questions have no expected file,
so the equivalent used here is **10 of 12 in-scope questions** (the same 80%).

## Results **[S]** (one run)

| Weight | Hits (of 12) | Misses                                          |
| ------ | ------------ | ----------------------------------------------- |
| 0.00   | 10           | rest-view (rank 4), kb-release (not in the 100) |
| 0.05   | 10           | usl-compile (rank 5), kb-release (rank 14)      |
| 0.15   | 10           | usl-compile (rank 5), kb-release (rank 6)       |

- Gate met at every weight, narrowly, and **the keyword weight did not help**:
  it changes which two questions miss, not how many. With 12 questions, one
  question is 8 points; treat the weights as indistinguishable. The default is
  set to 0.05, which is a judgement call. It was chosen on this same set, so it
  is not an independent result.
- **Out-of-scope:** top similarity was 0.771, 0.806 and 0.793; the lowest
  in-scope top was 0.854. They separate, but the margin is about 0.05 on a scale
  where unrelated text already scores 0.77+. A cut-off would need a larger set.
  [U]
- **kb-release** ("What changed in Zetaris release 2.4.1.0?"): the release-note
  page is not among the 100 dense candidates. Allowing version numbers as
  keywords raised it from absent to rank 6 at best. This needs lexical (keyword)
  retrieval or a title match, not weighting. Left open.
- **usl-compile:** the compile/activate statements appear in the commands guide
  and `usl/HOWTO.md`; the top 3 were `permissions.md`, `usl/HOWTO.md` and the
  companion guide. Whether the expected file list was too narrow is a fair
  question, and it was not widened after seeing the result.

## Not covered

- **Answer mode [LLM]** was not run: only a 4B local model is reachable, and the
  plan requires a larger model checked by hand. The code (`answerFromTableSpec`,
  `core/prompt.ts`) has unit tests for the pieces that do not need a model.
- Whole-file context for code questions is written (`wholeFileContext`) but not
  exercised against a live LLM.

## Re-run after indexing the SQL scripts (2026-11-10)

Changes: the 55 `*.sql` scripts are now indexed (cut at blank lines, section
taken from the nearest `--` comment), the example's own `docs/` folder is
excluded (it quotes the smoke questions, so it ranked first for one of them: the
test was circular), and code questions give the model the two best SQL scripts
plus the two best other files whole. Index: 2,767 segments (repo 1,674 + Kbase
1,093), count verified. The remote LLM is now reached as `doppio-1.lan`.

**Search [S]:** 10 of 12 at weights 0 to 0.10, 9 of 12 from 0.15 up. The misses
are the same two: `usl-compile` (the guide with the right statements is not in
the top 3 files) and `kb-release` (the release-note page ranks 8th to 15th,
behind other release notes). `pudl-query` now hits
(`examples/pudl-chart/query.sql` is 2nd). Out-of-scope tops 0.776, 0.806, 0.799
against a lowest in-scope top of 0.854; the margin is unchanged. Weight 0.05
stays the default; again 12 questions cannot separate the weights.

**Answers [LLM], one run each, `gpt-oss:20b`, graded by reading and by `grep`
against the scripts:**

| Question      | Result                                                                                                                                                                                                                                                                                                                                                                                                          |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| pudl-query    | **Now correct.** Returns the query in `examples/pudl-chart/query.sql`, cited. Before: "not covered".                                                                                                                                                                                                                                                                                                            |
| rest-view     | **Much better, still a template.** Every keyword used (`CREATE LIGHTNING REST TABLE ... FROM`, `REQUEST(endpoint ... method ... response_type ... http_encoding)`, `HEADER`, `BODY`, `CACHE TABLE`, `CREATE SCHEMASTORE VIEW ... WITH CONTAINER`) occurs in the repo's scripts. URL and column names are placeholders. A source column cites a known_to_fail script as example syntax. Before: invented syntax. |
| usl-compile   | **Still wrong in one respect.** The compile form is right. It gives `ACTIVATE USL TABLE <model_name>` and says activation "loads data"; the commands guide (13.4) has `ACTIVATE USL TABLE <namespace.usl.table> AS <SELECT ...>`, and loading is `MATERIALIZE USL TABLE`. The guide's chunk was not among the context.                                                                                          |
| kb-release    | "not covered" (retrieval miss, as above).                                                                                                                                                                                                                                                                                                                                                                       |
| jdbc-settings | Unchanged: generic list, no actual URL or driver class.                                                                                                                                                                                                                                                                                                                                                         |

The other 10 answers were not re-run after the index change; their earlier
grades stand only for the earlier index.

**Takeaway:** indexing the scripts fixes the cases where the example is in a
script. It does not stop the model from mixing a statement's syntax with what it
does. Show generated SQL as unverified, and prefer linking the source script.
[S]

## Pinned-answer threshold (2026-11-10, Phase 6)

One pin ("How do I clone a pipeline?") against questions at the default 0.82
threshold (E5, similarity on the question alone) **[S]**, one run:

| Question                                           | Similarity | Shown? |
| -------------------------------------------------- | ---------- | ------ |
| What are the steps to clone a pipeline in Zetaris? | 0.911      | yes    |
| how can I make a copy of an existing pipeline      | 0.868      | yes    |
| create a new pipeline                              | 0.869      | yes    |
| clone a git repository                             | 0.847      | yes    |
| delete a pipeline                                  | 0.846      | yes    |
| clone a data source                                | 0.842      | yes    |
| schedule a pipeline daily                          | 0.834      | yes    |
| What is a virtual pipeline?                        | 0.806      | no     |
| unrelated questions                                | 0.73-0.76  | no     |

Paraphrases score about the same as near-miss questions, so no threshold
separates them. The app shows the pinned question with each past answer and
makes using it opt-in. The threshold is `HELP_PIN_THRESHOLD`. [S]

## Example mode bake-off (2026-11-10, Phase 6b) **[LLM]**

Ten requests ([scripts/example_bakeoff.ts](../scripts/example_bakeoff.ts)), each
retrieving the closest example scripts and asking for a new query, checked with
`EXPLAIN` on the instance (up to 3 attempts, the checker's message fed back).
All ten are queries over objects that exist on this instance (the
`sic_edgar_usl` tables and `help_usl`), because only queries can be dry-run. One
run per model, `num_ctx` not set by the app, wall-clock times include other work
on the same LLM host, so read the times roughly.

| Model                        | Size  | Pass at attempt 1 | Dry-run passed within 3 | Total time |
| ---------------------------- | ----- | ----------------- | ----------------------- | ---------- |
| `gpt-oss:20b`                | 14 GB | 6/10              | 9/10                    | 245 s      |
| `gpt-oss:120b`               | 65 GB | 8/10              | 10/10                   | 476 s      |
| `qwen3-next:80b-a3b-...q8_0` | 85 GB | 6/10              | 6/10                    | 156 s      |

Second run (2026-11-09), after the Example-mode changes made for the "connect to
a database" complaint (command-reference section hints, a "not covered"
refusal, applied only to setup-style requests). The first run gave 8/10, 8/10
and 9/10 at attempt 1, and 9/10, 10/10 and 9/10 within 3. The table above
replaces it. Both `gpt-oss` models still meet the bar of 8 of 10 within 3
attempts. `qwen3-next` does not: in this run it answered three of the ten
requests with `SHOW NAMESPACES` or `COMPILE USL` (commands the checker cannot
dry-run, so they stay "unverified") and once returned no SQL. I did not
investigate why it changed, and one run per model is a weak measurement, so
treat the qwen drop as unexplained, not as a finding about the model.

`qwen3-coder:30b` (the plan's default) is not installed on this LLM host, so it
was not run. The acceptance bar (8 of 10 within 3 attempts) is met by the two `gpt-oss` models and missed by `qwen3-next` in the second run.

Error classes: the repairs fixed **wrong table names** (`help_usl` or
`help_usl.chunks` without the full `lightning.metastore...` path); the two
failures were different in kind. `gpt-oss:20b` kept using a table name the
analyzer could not resolve (3 attempts, "chunks"), and `qwen3-next` answered a
query request with a `CREATE`/`COMPILE USL` script, which cannot be dry-run, so
it is labelled unverified (correctly, but it did not do what was asked).

**What a pass means.** "Dry-run passed" is the analyzer accepting the query. It
does not prove the query answers the request. One example was run and read
(`five longest sic_code descriptions`): it returned lengths 103, 101, 101, 95,
92, as intended. The other nine were not read. DDL cannot be dry-run at all.

**Default.** Nothing separates the models by more than one request in one run.
`gpt-oss:120b` is the only one that reached 10/10 and is not slower in this run,
so set `HELP_EXAMPLE_MODEL=gpt-oss:120b` where it is available; `gpt-oss:20b` is
an acceptable fallback. The code default is `OLLAMA_MODEL`. [S] [LLM]
