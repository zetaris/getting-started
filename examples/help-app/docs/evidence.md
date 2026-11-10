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
