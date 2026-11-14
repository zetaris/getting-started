import { App, staticFiles } from "fresh";
import { actorCookie, personFromCookie } from "./core/actor.ts";
import { define, type State } from "./utils.ts";

export const app = new App<State>();

app.use(staticFiles());

// A random id in a cookie, used only to allow one LLM request in flight per browser. Not an identity.
const session = define.middleware(async (ctx) => {
  const m = ctx.req.headers.get("cookie")?.match(
    /(?:^|; )help_sid=([A-Za-z0-9-]{16,64})/,
  );
  ctx.state.sessionId = m?.[1] ?? crypto.randomUUID();
  const res = await ctx.next();
  if (!m) {
    res.headers.append(
      "set-cookie",
      `help_sid=${ctx.state.sessionId}; Path=/; HttpOnly; SameSite=Lax`,
    );
  }
  return res;
});
app.use(session);

// Refresh the person cookie when this browser still has one. The value is not replaced.
app.use(define.middleware(async (ctx) => {
  const res = await ctx.next();
  const person = personFromCookie(ctx.req.headers.get("cookie"));
  if (person) res.headers.append("set-cookie", actorCookie(person));
  return res;
}));

// Log method and path only: never the query string, which can carry a question.
app.use(define.middleware((ctx) => {
  console.log(`${ctx.req.method} ${new URL(ctx.req.url).pathname}`);
  return ctx.next();
}));

app.fsRoutes();
