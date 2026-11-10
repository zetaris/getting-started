import { define } from "../../utils.ts";
import { AskError, toAskError } from "../../core/ask.ts";
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
      const run = async (onStage: (s: string) => void) => {
        const r = await generateExample(exampleDeps(), body.request, onStage);
        // Lengths, counts and timings only: never the request or the SQL.
        console.log(
          `example status=${r.status} attempts=${r.attempts.length} sources=${r.sources.length} ms=${r.ms}`,
        );
        return r;
      };
      if (!(ctx.req.headers.get("accept") ?? "").includes("ndjson")) {
        return json(await run(() => {}));
      }
      // Progress as it happens: one JSON object per line, ending with {result} or {error}.
      const lock = release;
      release = null; // the stream owns it now
      const enc = new TextEncoder();
      return new Response(
        new ReadableStream({
          async start(ctl) {
            const send = (o: unknown) =>
              ctl.enqueue(enc.encode(JSON.stringify(o) + "\n"));
            try {
              send({ result: await run((stage) => send({ stage })) });
            } catch (e) {
              const err = e instanceof AskError ? e : toAskError(e);
              console.log(`example failed code=${err.code}`);
              send({ error: { code: err.code, message: err.message } });
            } finally {
              lock?.();
              ctl.close();
            }
          },
        }),
        {
          headers: {
            "content-type": "application/x-ndjson",
            "cache-control": "no-store",
          },
        },
      );
    } catch (e) {
      return errorResponse(e, "example");
    } finally {
      release?.();
    }
  },
});
