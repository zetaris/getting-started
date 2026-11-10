// Small helpers shared by the API routes.
import { AskError, toAskError } from "./ask.ts";
import { sameOrigin } from "./security.ts";
import { ZetarisError } from "./zetaris.ts";

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "cache-control": "no-store",
    },
  });
}

export function errorResponse(e: unknown, label: string): Response {
  const err = e instanceof AskError ? e : toAskError(e);
  // Kind and status only: a Zetaris error message can echo the statement, and so the question.
  const cause = e instanceof ZetarisError
    ? `${e.kind}/${e.status ?? "-"}`
    : (e as Error)?.name;
  console.log(`${label} failed code=${err.code} cause=${cause}`);
  return json({ error: { code: err.code, message: err.message } }, err.status);
}

/** Refuse cross-site posts, then read a small JSON object body. Throws AskError. */
export async function readPost(
  req: Request,
  maxBytes = 16_384,
): Promise<Record<string, unknown>> {
  if (!sameOrigin(req)) {
    throw new AskError("bad_request", "Cross-site requests are refused.", 403);
  }
  const raw = await req.text();
  if (raw.length > maxBytes) {
    throw new AskError("bad_request", "That request is too large.", 413);
  }
  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    throw new AskError("bad_request", "Send a JSON object.", 400);
  }
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    throw new AskError("bad_request", "Send a JSON object.", 400);
  }
  return body as Record<string, unknown>;
}
