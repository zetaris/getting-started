import { assert, assertEquals, assertRejects } from "@std/assert";
import {
  checkSql,
  type ExampleDeps,
  extractSql,
  generateExample,
  isQuery,
  splitStatements,
} from "./example.ts";
import type { Passage } from "./query.ts";

Deno.test("splitStatements ignores semicolons in strings and comments", () => {
  const s = splitStatements(
    "-- header; not a split\nSELECT 'a;b' AS x; /* c; */ SELECT 2;\n",
  );
  assertEquals(s, ["SELECT 'a;b' AS x", "SELECT 2"]);
});

Deno.test("isQuery accepts SELECT and WITH only", () => {
  assert(isQuery("  select 1"));
  assert(isQuery("WITH a AS (SELECT 1) SELECT * FROM a"));
  assert(!isQuery("CREATE TABLE x"));
  assert(!isQuery("INSERT INTO t SELECT 1"));
});

Deno.test("extractSql takes the first fenced block and the note around it", () => {
  const r = extractSql("Here.\n```sql\nSELECT 1\n```\nDrew from: a.sql");
  assertEquals(r?.sql, "SELECT 1");
  assert(r?.notes.includes("Here.") && r.notes.includes("Drew from"));
  assertEquals(extractSql("no code here"), null);
  assertEquals(extractSql("```sql\n\n```"), null);
});

Deno.test("checkSql: a pass, an analysis error, a parse error, and unchecked DDL", async () => {
  assertEquals(
    await checkSql(() => Promise.resolve("== Physical Plan =="), "SELECT 1"),
    { error: null, unchecked: [] },
  );
  const a = await checkSql(
    () =>
      Promise.resolve(
        "== Physical Plan ==\norg.apache.spark.sql.AnalysisException: [TABLE_OR_VIEW_NOT_FOUND] x",
      ),
    "SELECT * FROM nope",
  );
  assert(a.error?.includes("TABLE_OR_VIEW_NOT_FOUND"));
  assert(!a.error?.includes("org.apache"));
  const p = await checkSql(
    () => Promise.reject(new Error("mismatched input 'SELEC'")),
    "SELEC 1",
  );
  assert(p.error?.includes("mismatched input"));
  const d = await checkSql(
    () => Promise.resolve("ok"),
    "CREATE NAMESPACE x; SELECT 1",
  );
  assertEquals(d.error, null);
  assertEquals(d.unchecked, ["CREATE NAMESPACE X"]);
});

const passage = (file: string, corpus = "repo"): Passage => ({
  corpus,
  file,
  part: 0,
  section: "S",
  text: "t",
  similarity: 0.8,
});

function deps(over: Partial<ExampleDeps> = {}): ExampleDeps {
  return {
    search: () =>
      Promise.resolve([
        passage("open_data/a/x_select.sql"),
        passage("docs/guides/zetaris-lightning-sql-companion.md"),
      ]),
    readFile: (f) =>
      Promise.resolve(f.endsWith(".sql") ? "-- header\nSELECT 1" : null),
    llm: () => Promise.resolve("Note.\n```sql\nSELECT 1\n```"),
    explain: () => Promise.resolve("== Physical Plan =="),
    model: "m",
    ...over,
  };
}

Deno.test("a passing example is labelled dry-run passed and cites its sources", async () => {
  const r = await generateExample(deps(), "same as the x example");
  assertEquals(r.status, "dry-run passed");
  assertEquals(r.attempts.length, 1);
  assertEquals(r.reason, null);
  assert(r.sources.some((s) => s.file === "open_data/a/x_select.sql"));
});

Deno.test("a rejected example is repaired with the error, then passes", async () => {
  const prompts: string[] = [];
  let calls = 0;
  const r = await generateExample(
    deps({
      llm: (
        p,
      ) => (prompts.push(p),
        Promise.resolve("```sql\nSELECT " + ++calls + "\n```")),
      explain: (s) =>
        s.endsWith("1")
          ? Promise.resolve(
            "org.apache.spark.sql.AnalysisException: [UNRESOLVED_COLUMN] foo",
          )
          : Promise.resolve("ok"),
    }),
    "x",
  );
  assertEquals(r.status, "dry-run passed");
  assertEquals(r.attempts.map((a) => a.error === null), [false, true]);
  assert(
    prompts[1].includes("UNRESOLVED_COLUMN") && prompts[1].includes("SELECT 1"),
  );
});

Deno.test("three failures give unverified with the last error and every attempt", async () => {
  const r = await generateExample(
    deps({ explain: () => Promise.resolve("AnalysisException: [BAD] y") }),
    "x",
  );
  assertEquals(r.status, "unverified");
  assertEquals(r.attempts.length, 3);
  assert(r.reason?.includes("BAD"));
});

Deno.test("DDL is never called dry-run passed", async () => {
  const r = await generateExample(
    deps({ llm: () => Promise.resolve("```sql\nCREATE NAMESPACE x\n```") }),
    "x",
  );
  assertEquals(r.status, "unverified");
  assert(r.reason?.includes("cannot run"));
  assertEquals(r.attempts.length, 1);
});

Deno.test("no example scripts found means nothing is generated", async () => {
  let called = false;
  await assertRejects(() =>
    generateExample(
      deps({
        search: () => Promise.resolve([passage("README.md")]),
        llm: () => (called = true, Promise.resolve("")),
      }),
      "x",
    )
  );
  assert(!called);
});

Deno.test("a model that never returns SQL is an error, and an empty request is refused", async () => {
  await assertRejects(() =>
    generateExample(deps({ llm: () => Promise.resolve("sorry") }), "x")
  );
  await assertRejects(() => generateExample(deps(), "  "));
});
