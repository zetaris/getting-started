// Same-origin check for state-changing requests. The app has no login, so without this any web
// page the user visits could post pins or events to it. A browser sends Origin on cross-site
// POSTs and on same-site fetches; a request without Origin (curl, tests) is allowed.

export function sameOrigin(req: Request): boolean {
  const origin = req.headers.get("origin");
  if (!origin) return true;
  try {
    return new URL(origin).host ===
      (req.headers.get("host") ?? new URL(req.url).host);
  } catch {
    return false;
  }
}

/** Strip control characters, collapse whitespace and cap the length. */
export function cleanText(s: unknown, max: number): string {
  if (typeof s !== "string") return "";
  // deno-lint-ignore no-control-regex
  return s.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, " ")
    .trim().slice(0, max);
}
