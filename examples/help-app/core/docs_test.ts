import { assert, assertEquals } from "@std/assert";
import {
  clearDocsCache,
  docChunks,
  docHref,
  filterDocs,
  groupDocs,
  listDocs,
  openDoc,
  stripFrontMatter,
  validRepoPath,
  validSlug,
} from "./docs.ts";

const ROWS = [
  ["a/b.md", "repo", "B doc", "guide", "3"],
  ["x/y.sql", "repo", "", "sql", "1"],
  [
    "https://kbase.zetaris.com/knowledge/how-to",
    "kbase",
    "How to",
    "how-to",
    "2",
  ],
];
const z = (calls: string[] = []) => ({
  run: (sql: string) => {
    calls.push(sql);
    return Promise.resolve({
      rows: sql.includes("FROM") && sql.includes(".chunks")
        ? [["0", "Intro", "120"]]
        : ROWS,
      headers: [],
    });
  },
});

Deno.test("only plain repo-relative .md and .sql paths are valid", () => {
  for (const ok of ["a.md", "a/b/c.sql", "docs/guides/x-y_z.md"]) {
    assert(validRepoPath(ok), ok);
  }
  for (
    const bad of [
      "",
      "/etc/passwd",
      "../x.md",
      "a/../b.md",
      "a//b.md",
      "./a.md",
      "a\\b.md",
      "a.txt",
      "a.md\0",
      "x".repeat(401) + ".md",
      "a/.env",
    ]
  ) assert(!validRepoPath(bad), bad);
  assert(validSlug("how-to-clone-pipeline"));
  assert(!validSlug("../x") && !validSlug("a/b") && !validSlug(""));
});

Deno.test("links: repo paths and Kbase URLs map to in-app routes", () => {
  assertEquals(docHref("a b/c.md"), "/docs/a%20b/c.md");
  assertEquals(
    docHref("https://kbase.zetaris.com/knowledge/how-to"),
    "/docs/kbase/how-to",
  );
  // A URL with a slash or %2F in it links by its snapshot file slug, which is a valid slug.
  for (
    const u of [
      "https://kbase.zetaris.com/knowledge/processes-for-automation-table-view-schema-creation-/-deletion",
      "https://kbase.zetaris.com/knowledge/product-version-2.3.0-2023%2F06%2F13",
    ]
  ) {
    const slug = decodeURIComponent(docHref(u).slice("/docs/kbase/".length));
    assert(validSlug(slug), slug);
  }
});

Deno.test("the catalog is listed once and cached", async () => {
  clearDocsCache();
  const calls: string[] = [];
  const a = await listDocs(z(calls), 1000);
  await listDocs(z(calls), 2000);
  assertEquals(calls.length, 1);
  assertEquals(a[1].title, "x/y.sql"); // empty title falls back to the path
  await listDocs(z(calls), 1000 + 61_000);
  assertEquals(calls.length, 2);
});

Deno.test("filtering and grouping", async () => {
  clearDocsCache();
  const rows = await listDocs(z());
  assertEquals(filterDocs(rows, { corpus: "kbase" }).length, 1);
  assertEquals(filterDocs(rows, { q: "B DOC" }).length, 1);
  assertEquals(filterDocs(rows, { kind: "sql", corpus: "kbase" }).length, 0);
  const g = groupDocs(rows);
  assertEquals(g.map((x) => x.corpus), ["kbase", "repo"]);
  assertEquals(g[1].kinds.map((k) => k.kind), ["guide", "sql"]);
});

Deno.test("a file outside the catalog is never read, even if the path is valid", async () => {
  clearDocsCache();
  let reads = 0;
  const io = {
    readRepo: () => (reads++, Promise.resolve("x")),
    readKbase: () => Promise.resolve("---\nk: v\n---\nbody"),
  };
  assertEquals(await openDoc(z(), io, "repo", "not/in/catalog.md"), null);
  assertEquals(await openDoc(z(), io, "repo", "../../etc/passwd"), null);
  assertEquals(reads, 0);
  const d = await openDoc(z(), io, "repo", "a/b.md");
  assertEquals(d?.body, "x");
  const k = await openDoc(z(), io, "kbase", "how-to");
  assertEquals(k?.body, "body");
  assertEquals((await openDoc(z(), io, "repo", "x/y.sql"))?.isSql, true);
});

Deno.test("chunk query encodes the path, and the front matter is stripped", async () => {
  const calls: string[] = [];
  const c = await docChunks(z(calls), "it's/odd.md");
  assertEquals(c, [{ part: 0, section: "Intro", chars: 120 }]);
  assert(!calls[0].includes("it's"));
  assertEquals(stripFrontMatter("---\na: b\n---\ntext"), "text");
  assertEquals(stripFrontMatter("no header"), "no header");
});
