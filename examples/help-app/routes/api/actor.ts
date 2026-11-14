import { define } from "../../utils.ts";
import { actorDecision } from "../../core/actor.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";

export const handler = define.handlers({
  async POST(ctx) {
    try {
      const body = await readPost(ctx.req);
      const decision = actorDecision(ctx.req.headers, body.id);
      const res = json({ id: decision.id });
      for (const cookie of decision.cookies) {
        res.headers.append("set-cookie", cookie);
      }
      return res;
    } catch (e) {
      return errorResponse(e, "actor");
    }
  },
});
