import { define } from "../../utils.ts";
import { ask, AskError, toAskError } from "../../core/ask.ts";
import { askDeps, inFlight } from "../../core/server.ts";
import { ZetarisError } from "../../core/zetaris.ts";

const MAX_BODY = 4096;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
    },
  });
}

export const handler = define.handlers({
  async POST(ctx) {
    const raw = await ctx.req.text();
    if (raw.length > MAX_BODY) {
      return json({
        error: { code: "bad_request", message: "That request is too large." },
      }, 413);
    }
    let body: { question?: unknown; mode?: unknown };
    try {
      body = JSON.parse(raw);
    } catch {
      return json({
        error: { code: "bad_request", message: "Send JSON: {question, mode}." },
      }, 400);
    }
    const mode = body.mode === "answer"
      ? "answer"
      : body.mode === "search"
      ? "search"
      : null;
    if (!mode || typeof body.question !== "string") {
      return json({
        error: {
          code: "bad_request",
          message: "Send {question: string, mode: search | answer}.",
        },
      }, 400);
    }
    let release: (() => void) | null = null;
    if (mode === "answer") {
      release = inFlight.tryStart(ctx.state.sessionId);
      if (!release) {
        return json({
          error: {
            code: "busy",
            message:
              "Your previous answer is still being written. Wait for it, then ask again.",
          },
        }, 429);
      }
    }
    try {
      const result = await ask(askDeps(), { question: body.question, mode });
      // Log lengths and timings only, never the question text.
      console.log(
        `ask mode=${mode} qlen=${body.question.length} search=${result.timings.searchMs}ms` +
          (result.timings.answerMs !== null
            ? ` answer=${result.timings.answerMs}ms`
            : ""),
      );
      return json(result);
    } catch (e) {
      const err = e instanceof AskError ? e : toAskError(e);
      // Kind and status only: a Zetaris error message can echo the statement, and so the question.
      const cause = e instanceof ZetarisError
        ? `${e.kind}/${e.status ?? "-"}`
        : (e as Error)?.name;
      console.log(`ask failed code=${err.code} cause=${cause}`);
      return json(
        { error: { code: err.code, message: err.message } },
        err.status,
      );
    } finally {
      release?.();
    }
  },
});
