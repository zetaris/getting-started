import { define } from "../../utils.ts";
import { ask } from "../../core/ask.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";
import { AskError } from "../../core/ask.ts";
import { askDeps, inFlight } from "../../core/server.ts";

export const handler = define.handlers({
  async POST(ctx) {
    let release: (() => void) | null = null;
    try {
      const body = await readPost(ctx.req, 4096);
      const mode = body.mode === "answer"
        ? "answer"
        : body.mode === "search"
        ? "search"
        : null;
      if (!mode || typeof body.question !== "string") {
        throw new AskError(
          "bad_request",
          "Send {question: string, mode: search | answer}.",
          400,
        );
      }
      if (mode === "answer") {
        release = inFlight.tryStart(ctx.state.sessionId);
        if (!release) {
          throw new AskError(
            "busy",
            "Your previous answer is still being written. Wait for it, then ask again.",
            429,
          );
        }
      }
      const result = await ask(askDeps(), { question: body.question, mode });
      // Log lengths and timings only, never the question text.
      console.log(
        `ask mode=${mode} qlen=${body.question.length} search=${result.timings.searchMs}ms` +
          (result.timings.answerMs !== null
            ? ` answer=${result.timings.answerMs}ms`
            : "") +
          ` past=${result.pastAnswers.length}`,
      );
      return json(result);
    } catch (e) {
      return errorResponse(e, "ask");
    } finally {
      release?.();
    }
  },
});
