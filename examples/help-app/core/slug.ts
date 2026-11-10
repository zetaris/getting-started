// Kept apart from kbase.ts, which imports an HTML parser the server bundle must not pull in.
export function slugOf(url: string): string {
  return new URL(url).pathname.replace(/^\/knowledge\//, "").replace(
    /[^a-zA-Z0-9._-]+/g,
    "-",
  )
    .replace(/^-+|-+$/g, "") || "index";
}
