import { define } from "../../utils.ts";
import { resolveActor } from "../../core/actor.ts";
import { AskError } from "../../core/ask.ts";
import { candidatesEnabled } from "../../core/config.ts";
import { catalogFiles, saveCandidate } from "../../core/candidates.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";
import { getZetaris } from "../../core/server.ts";

export const handler = define.handlers({
  async POST(ctx) {
    try {
      if (!candidatesEnabled()) {
        throw new AskError("not_found", "Candidates are off.", 404);
      }
      const body = await readPost(ctx.req, 32_768);
      const z = getZetaris();
      if (!z) {
        throw new AskError(
          "zetaris_config",
          "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
          503,
        );
      }
      const r = await saveCandidate(
        z,
        {
          request: body.request,
          sql: body.sql,
          attempts: body.attempts,
          model: body.model,
          sources: body.sources,
          notes: body.notes,
          who: resolveActor(ctx.req.headers),
        },
        () => catalogFiles(z),
        async (sql) =>
          (await z.run(`EXPLAIN ${sql}`, 5)).rows.map((x) => x[0]).join("\n"),
      );
      console.log(`candidate ${r.existing ? "existing" : "saved"}`);
      return json(r, r.existing ? 200 : 201);
    } catch (e) {
      return errorResponse(e, "candidate");
    }
  },
});
