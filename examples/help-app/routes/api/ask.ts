import { define } from "../../utils.ts";
import { logSearch } from "../../core/activity.ts";
import { resolveActor } from "../../core/actor.ts";
import { ask, AskError, toAskError } from "../../core/ask.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";
import { askDeps, getZetaris, inFlight } from "../../core/server.ts";

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
      const question = body.question;
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
      const who = resolveActor(ctx.req.headers);
      const run = async (onStage: (s: string) => void) => {
        const result = await ask(askDeps(), {
          question,
          mode,
          fresh: body.fresh === true,
        }, onStage);
        const z = getZetaris();
        if (z) await logSearch(z, question, who, mode);
        // Log lengths and timings only, never the question text.
        console.log(
          `ask mode=${mode} qlen=${question.length} search=${result.timings.searchMs}ms` +
            (result.timings.answerMs !== null
              ? ` answer=${result.timings.answerMs}ms`
              : "") +
            ` past=${result.pastAnswers.length}`,
        );
        return result;
      };
      if (!(ctx.req.headers.get("accept") ?? "").includes("ndjson")) {
        return json(await run(() => {}));
      }
      const lock = release;
      release = null;
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
              console.log(`ask failed code=${err.code}`);
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
      return errorResponse(e, "ask");
    } finally {
      release?.();
    }
  },
});
