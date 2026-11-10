// Prints what the corpus walk finds and checks the file count against `find`.
// Usage: deno task help:verify --corpus
import { loadRepoCorpus, MAX_TEXT } from "../core/corpus.ts";

export const ROOT = new URL("../../..", import.meta.url).pathname.replace(
  /\/$/,
  "",
);
export const SKIP = ["examples/help-app/corpus/", "examples/help-app/.cache/"];

async function findCount(): Promise<number> {
  const out = await new Deno.Command("find", {
    args: [
      ROOT,
      "(",
      "-name",
      ".*",
      "-o",
      "-name",
      "node_modules",
      "-o",
      "-path",
      `${ROOT}/dist`,
      "-o",
      "-path",
      `${ROOT}/site`,
      "-o",
      "-path",
      `${ROOT}/tmp`,
      "-o",
      "-path",
      `${ROOT}/reports`,
      "-o",
      "-path",
      `${ROOT}/examples/help-app/corpus`,
      ")",
      "-prune",
      "-o",
      "-type",
      "f",
      "-name",
      "*.md",
      "-print",
    ],
  }).output();
  return new TextDecoder().decode(out.stdout).split("\n").filter(Boolean)
    .length;
}

if (import.meta.main) {
  if (!Deno.args.includes("--corpus")) {
    console.error("Usage: deno task help:verify --corpus");
    Deno.exit(2);
  }
  const { docs, segments } = await loadRepoCorpus(ROOT, { skipPrefixes: SKIP });
  const bytes = docs.reduce((n, d) => n + d.bytes, 0);
  const longest = Math.max(...segments.map((s) => s.text.length));
  const found = await findCount();
  console.log(`files:    ${docs.length}`);
  console.log(`segments: ${segments.length}`);
  console.log(`bytes:    ${bytes}`);
  console.log(`longest segment: ${longest} characters (limit ${MAX_TEXT})`);
  console.log(`find count: ${found}`);
  const kinds: Record<string, number> = {};
  for (const d of docs) kinds[d.kind] = (kinds[d.kind] ?? 0) + 1;
  console.log(`kinds: ${JSON.stringify(kinds)}`);
  if (found !== docs.length || longest > MAX_TEXT) {
    console.error(
      "FAIL: file count differs from find, or a segment is too long.",
    );
    Deno.exit(1);
  }
  console.log("ok");
}
