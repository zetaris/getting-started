// Re-ranking: similarity plus a small bonus for question words found in the passage text or
// path. Pure functions so the weight can be tuned offline against cached search results.
import type { Passage } from "./query.ts";

const STOP = new Set(
  ("about after again also because been before being between both could does doing done from " +
    "have having here into just like make many more most much only other over same should show " +
    "some such than that their them then there these they this those through under very what when " +
    "where which while will with would your how why who can the and for are but not you our")
    .split(
      " ",
    ),
);

export function questionWords(question: string): string[] {
  const words = question.toLowerCase().match(/\d+(?:\.\d+)+|[a-z0-9_]{4,}/g) ??
    [];
  return [...new Set(words.filter((w) => !STOP.has(w)))];
}

/** Share of the question's content words found in the passage text, file path or section. */
export function keywordShare(question: string, p: Passage): number {
  const words = questionWords(question);
  if (words.length === 0) return 0;
  const hay = `${p.text} ${p.file} ${p.section}`.toLowerCase();
  return words.filter((w) => hay.includes(w)).length / words.length;
}

export interface Ranked extends Passage {
  score: number;
  keyword: number;
}

export interface RankOptions {
  /** Weight of the keyword share. Default 0.05; see docs/evidence.md (0.15 was the pilot value). */
  weight?: number;
  /** Optional per-file bonus (the pins phase adds a like bonus here). */
  fileBonus?: (file: string) => number;
}

export function rerank(
  question: string,
  passages: Passage[],
  opts: RankOptions = {},
): Ranked[] {
  const weight = opts.weight ?? 0.05;
  return passages
    .map((p) => {
      const keyword = keywordShare(question, p);
      return {
        ...p,
        keyword,
        score: p.similarity + weight * keyword +
          (opts.fileBonus?.(p.file) ?? 0),
      };
    })
    .sort((a, b) => b.score - a.score);
}

export interface FileHit {
  file: string;
  corpus: string;
  score: number;
  passages: Ranked[];
}

/** Group ranked passages by file; a file's score is its best passage's score. */
export function topFiles(ranked: Ranked[], n: number): FileHit[] {
  const byFile = new Map<string, FileHit>();
  for (const p of ranked) {
    const hit = byFile.get(p.file);
    if (hit) hit.passages.push(p);
    else {byFile.set(p.file, {
        file: p.file,
        corpus: p.corpus,
        score: p.score,
        passages: [p],
      });}
  }
  return [...byFile.values()].sort((a, b) => b.score - a.score).slice(0, n);
}
