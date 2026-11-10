// Prints what the corpus walk finds and checks the file count against `find`.
// Usage: deno task help:verify --corpus
import { loadKbaseCorpus, loadRepoCorpus, MAX_TEXT } from "../core/corpus.ts";

export const ROOT = new URL("../../..", import.meta.url).pathname.replace(
  /\/$/,
  "",
);
export const SKIP = [
  "examples/help-app/corpus/",
  "examples/help-app/.cache/",
  "examples/help-app/docs/", // quotes the smoke questions, so indexing it would make the test circular
];

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
      "-o",
      "-path",
      `${ROOT}/examples/help-app/docs`,
      ")",
      "-prune",
      "-o",
      "-type",
      "f",
      "(",
      "-name",
      "*.md",
      "-o",
      "-name",
      "*.sql",
      ")",
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
  try {
    const kb = await loadKbaseCorpus("corpus/kbase");
    const manifest = JSON.parse(
      await Deno.readTextFile("corpus/kbase/manifest.json"),
    );
    const kbLongest = Math.max(...kb.segments.map((s) => s.text.length));
    console.log(
      `kbase pages: ${kb.docs.length} (manifest ok: ${manifest.ok}, of ${manifest.pages} in the sitemap)`,
    );
    console.log(`kbase segments: ${kb.segments.length}, longest ${kbLongest}`);
    if (kb.docs.length !== manifest.ok || kbLongest > MAX_TEXT) {
      console.error(
        "FAIL: kbase file count differs from the manifest, or a segment is too long.",
      );
      Deno.exit(1);
    }
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) throw e;
    console.log("kbase: no snapshot (run deno task help:fetch-kbase)");
  }
  console.log("ok");
}
