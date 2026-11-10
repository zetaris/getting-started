import { define } from "../../utils.ts";
import { AskError } from "../../core/ask.ts";
import { errorResponse, json, readPost } from "../../core/http.ts";
import { addEvent } from "../../core/pins.ts";
import { pinStore } from "../../core/server.ts";

export const handler = define.handlers({
  async POST(ctx) {
    try {
      const body = await readPost(ctx.req);
      const store = pinStore();
      if (!store) {
        throw new AskError(
          "zetaris_config",
          "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart.",
          503,
        );
      }
      const r = await addEvent(store, {
        pinId: body.pinId,
        kind: body.kind,
        who: body.who,
      });
      console.log(`pin-event kind=${String(body.kind)}`);
      return json(r);
    } catch (e) {
      return errorResponse(e, "pin-event");
    }
  },
});
