import { define } from "../../utils.ts";
import { AskError } from "../../core/ask.ts";
import { generateExample } from "../../core/example.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";
import {
  exampleDeps,
  getConfig,
  getZetaris,
  inFlight,
} from "../../core/server.ts";

export const handler = define.handlers({
  async POST(ctx) {
    let release: (() => void) | null = null;
    try {
      const body = await readPost(ctx.req, 4096);
      const c = getConfig();
      if (!c.ollamaUrl || !c.exampleModel) {
        throw new AskError(
          "llm_not_configured",
          "Example mode needs OLLAMA_URL and OLLAMA_MODEL (or HELP_EXAMPLE_MODEL) in .env.local.",
          400,
        );
      }
      if (!getZetaris()) {
        throw new AskError(
          "zetaris_config",
          "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
          503,
        );
      }
      // Shares the Answer lock: one model call chain per browser session at a time.
      release = inFlight.tryStart(ctx.state.sessionId);
      if (!release) {
        throw new AskError(
          "busy",
          "Your previous answer or example is still being written. Wait for it, then try again.",
          429,
        );
      }
      const r = await generateExample(exampleDeps(), body.request);
      // Lengths, counts and timings only: never the request or the SQL.
      console.log(
        `example status=${r.status} attempts=${r.attempts.length} sources=${r.sources.length} ms=${r.ms}`,
      );
      return json(r);
    } catch (e) {
      return errorResponse(e, "example");
    } finally {
      release?.();
    }
  },
});
