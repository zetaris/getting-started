import { define } from "../../utils.ts";
import { AskError } from "../../core/ask.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";
import { createPin } from "../../core/pins.ts";
import { pinStore } from "../../core/server.ts";

export const handler = define.handlers({
  async POST(ctx) {
    try {
      const body = await readPost(ctx.req, 32_768);
      const store = pinStore();
      if (!store) {
        throw new AskError(
          "zetaris_config",
          "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
          503,
        );
      }
      const r = await createPin(store, {
        question: body.question,
        answer: body.answer,
        model: body.model,
        sources: body.sources,
        who: body.who,
      });
      console.log(`pin ${r.existing ? "existing" : "created"}`);
      return json(r, r.existing ? 200 : 201);
    } catch (e) {
      return errorResponse(e, "pin");
    }
  },
});
