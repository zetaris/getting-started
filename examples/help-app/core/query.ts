// The query path: one-off Zetaris pipeline runs for search, and for answers over passages the
// app has ranked itself. The question goes into the spec (the saved relation's prompt is fixed),
// base64-encoded where it enters SQL, and length-capped.
import type { Config } from "./config.ts";
import { answerFromTableSpec, runPipeline, searchSpec } from "./specs.ts";
import type { Zetaris } from "./zetaris.ts";

export const MAX_QUESTION = 500;

export interface Passage {
  corpus: string;
  file: string;
  part: number;
  section: string;
  text: string;
  similarity: number;
}

/** Trim, drop control characters and cap the length. */
export function cleanQuestion(q: string): string {
  // deno-lint-ignore no-control-regex
  return q.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, " ")
    .replace(/\s+/g, " ")
    .trim().slice(0, MAX_QUESTION);
}

/** Parse one search row: [prompt, content, similarity], content being the chunk with its header. */
export function parsePassage(row: string[]): Passage {
  const content = row[1] ?? "";
  const field = (k: string) =>
    content.match(new RegExp(`^${k}: (.*)$`, "m"))?.[1]?.trim() ?? "";
  const text = content.includes("\nTEXT: ")
    ? content.slice(content.indexOf("\nTEXT: ") + 7)
    : content;
  return {
    corpus: field("REPO") || "repo",
    file: field("FILE"),
    part: Number(field("PART")) || 0,
    section: field("SECTION"),
    text,
    similarity: Number(row[row.length - 1]),
  };
}

export async function search(
  cfg: Config,
  z: Zetaris,
  question: string,
  limit = 30,
): Promise<Passage[]> {
  const q = cleanQuestion(question);
  if (!q) throw new Error("Empty question.");
  const r = await z.run(
    runPipeline("vs_search", limit, searchSpec(cfg, q)),
    limit,
  );
  return r.rows.map(parsePassage);
}

/** Answer from passages the caller chose: they go in as a one-table SQLTable source with the
 * columns the LLM node reads (prompt, content, similarity). Needs OLLAMA_URL and OLLAMA_MODEL. */
export async function answer(
  cfg: Config,
  z: Zetaris,
  question: string,
  passages: { header: string; text: string; similarity: number }[],
  promptText?: string,
): Promise<{ answer: string; contexts: string }> {
  if (!cfg.ollamaUrl || !cfg.ollamaModel) {
    throw new Error("Set OLLAMA_URL and OLLAMA_MODEL to use Answer mode.");
  }
  const q = cleanQuestion(question);
  const r = await z.run(
    runPipeline(
      "llm_answer",
      passages.length,
      answerFromTableSpec(cfg, q, passages, promptText),
    ),
    1,
  );
  const row = r.rows[0];
  return { answer: row?.[1] ?? "", contexts: row?.[2] ?? "" };
}
