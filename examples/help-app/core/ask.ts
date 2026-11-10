// The Ask flow, with its dependencies passed in so it can be tested without Zetaris or an LLM:
// clean the question, search, re-rank, group by file, and (Answer mode) build context and ask the model.
import { isCodeQuestion, pickCodeFiles, wholeFileContext } from "./prompt.ts";
import { cleanQuestion, type Passage } from "./query.ts";
import { type FileHit, rerank, topFiles } from "./rank.ts";
import { ZetarisError } from "./zetaris.ts";

export type Mode = "search" | "answer";

export interface Source {
  file: string;
  corpus: string;
  /** Section of the best passage. */
  section: string;
  similarity: number;
  /** Best passage text, trimmed for display. */
  excerpt: string;
  /** A link only when the file is a web page (the Kbase). */
  url: string | null;
}

export interface AskResult {
  mode: Mode;
  sources: Source[];
  answer: string | null;
  timings: { searchMs: number; answerMs: number | null };
}

export interface AskDeps {
  search(question: string, limit: number): Promise<Passage[]>;
  answer(
    question: string,
    contexts: { header: string; text: string; similarity: number }[],
  ): Promise<string>;
  /** Read a repo file for whole-file context; null when it cannot be read. */
  readFile(file: string): Promise<string | null>;
  llmConfigured: boolean;
  /** Keyword weight for re-ranking. */
  weight?: number;
}

export type AskErrorCode =
  | "empty_question"
  | "bad_request"
  | "llm_not_configured"
  | "busy"
  | "zetaris_unreachable"
  | "zetaris_timeout"
  | "zetaris_key"
  | "zetaris_config"
  | "zetaris_error";

/** An error safe to show: the message never carries SQL, stack traces or server text. */
export class AskError extends Error {
  constructor(
    public code: AskErrorCode,
    message: string,
    public status: number,
  ) {
    super(message);
  }
}

/** Turn anything thrown while talking to Zetaris into an AskError with a clear message. */
export function toAskError(e: unknown): AskError {
  if (e instanceof AskError) return e;
  if (e instanceof ZetarisError) {
    switch (e.kind) {
      case "unreachable":
        return new AskError(
          "zetaris_unreachable",
          "Zetaris is not reachable. Check that it is running and that ZETARIS_REST_URL is right.",
          503,
        );
      case "timeout":
        return new AskError(
          "zetaris_timeout",
          "Zetaris did not answer in time. The model may be busy; try again, or use Search only.",
          504,
        );
      case "config":
        return new AskError(
          "zetaris_config",
          "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
          503,
        );
      default:
        if (e.status === 401 || e.status === 403) {
          return new AskError(
            "zetaris_key",
            "Zetaris refused the API key. Check ZETARIS_API_KEY and ZETARIS_ORG_ID in .env.local.",
            502,
          );
        }
        return new AskError(
          "zetaris_error",
          "Zetaris returned an error. See the server log for details.",
          502,
        );
    }
  }
  return new AskError(
    "zetaris_error",
    "Something went wrong. See the server log for details.",
    500,
  );
}

const EXCERPT = 600;

export function toSource(h: FileHit): Source {
  const best = h.passages[0];
  return {
    file: h.file,
    corpus: h.corpus,
    section: best.section,
    similarity: Number(best.similarity.toFixed(3)),
    excerpt: best.text.length > EXCERPT
      ? `${best.text.slice(0, EXCERPT)}…`
      : best.text,
    url: /^https?:\/\//.test(h.file) ? h.file : null,
  };
}

/** Context for the model: whole files for SQL and example questions, else the top passages. */
export async function buildContexts(
  question: string,
  ranked: ReturnType<typeof rerank>,
  readFile: (f: string) => Promise<string | null>,
) {
  if (isCodeQuestion(question)) {
    const files = topFiles(ranked, 12).filter((f) => f.corpus === "repo").map((
      f,
    ) => f.file);
    const whole = await wholeFileContext(pickCodeFiles(files), readFile, 4);
    if (whole.length > 0) {
      const sim = ranked[0]?.similarity ?? 0;
      return whole.map((w) => ({ ...w, similarity: sim }));
    }
  }
  return ranked.slice(0, 6).map((p) => ({
    header: `REPO: ${p.corpus}\nFILE: ${p.file}\nSECTION: ${p.section}`,
    text: p.text,
    similarity: p.similarity,
  }));
}

export async function ask(
  deps: AskDeps,
  input: { question: string; mode: Mode },
): Promise<AskResult> {
  const question = cleanQuestion(input.question ?? "");
  if (!question) {
    throw new AskError("empty_question", "Type a question first.", 400);
  }
  if (input.mode !== "search" && input.mode !== "answer") {
    throw new AskError("bad_request", "Mode must be search or answer.", 400);
  }
  if (input.mode === "answer" && !deps.llmConfigured) {
    throw new AskError(
      "llm_not_configured",
      "Answer mode needs OLLAMA_URL and OLLAMA_MODEL in .env.local. Search only works without them.",
      400,
    );
  }
  const t0 = performance.now();
  let passages: Passage[];
  try {
    passages = await deps.search(question, 100);
  } catch (e) {
    throw toAskError(e);
  }
  const ranked = rerank(question, passages, { weight: deps.weight });
  const sources = topFiles(ranked, 5).map(toSource);
  const searchMs = Math.round(performance.now() - t0);
  if (input.mode === "search") {
    return {
      mode: "search",
      sources,
      answer: null,
      timings: { searchMs, answerMs: null },
    };
  }
  const t1 = performance.now();
  try {
    const contexts = await buildContexts(question, ranked, deps.readFile);
    const answer = await deps.answer(question, contexts);
    return {
      mode: "answer",
      sources,
      answer,
      timings: { searchMs, answerMs: Math.round(performance.now() - t1) },
    };
  } catch (e) {
    throw toAskError(e);
  }
}
