import { assert, assertEquals, assertRejects } from "@std/assert";
import {
  checkSql,
  exampleContext,
  type ExampleDeps,
  extractSql,
  generateExample,
  generatePrompt,
  hintedSections,
  isQuery,
  isSetupRequest,
  splitStatements,
} from "./example.ts";
import type { Ranked } from "./rank.ts";
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
  assert(r?.notes.includes("Here.") && !r.notes.includes("Drew from"));
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
  assertEquals(d.unchecked, ["CREATE NAMESPACE"]);
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
  const src = r.sources.find((s) => s.file === "open_data/a/x_select.sql");
  assert(src);
  assertEquals(src.section, "S");
  assert(src.snippetHtml.includes("t"));
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
  assert(r.reason?.includes("CREATE NAMESPACE"));
  assert(r.reason?.includes("not asked to check"));
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

Deno.test("hintedSections pulls the whole reference section a topic points to", async () => {
  const doc =
    "## 4. Data Sources\n\n### 4.1 CREATE DATASOURCE\n\nSyntax\n\n```sql\nCREATE DATASOURCE <name> OPTIONS (k 'v')\n```\n\n### 4.2 REGISTER DATASOURCE TABLE\n\nother";
  const read = (f: string) =>
    Promise.resolve(f.endsWith("commands.md") ? doc : null);
  const h = await hintedSections("Show me how I connect to a database", read);
  assertEquals(h.length, 1);
  assert(h[0].text.includes("OPTIONS") && !h[0].text.includes("other"));
  assert(h[0].header.includes("4.1 CREATE DATASOURCE"));
  assertEquals(await hintedSections("count the rows", read), []);
  assertEquals(
    await hintedSections("connect", () => Promise.resolve(null)),
    [],
  );
});

Deno.test("a connect request for company_dns follows that REST script", async () => {
  const request = "Show me how can I connect Zetaris to company_dns in SQL";
  const dns = "open_data/rest_apis/sql/rate_limited/12_company_dns_create.sql";
  const hit = (
    file: string,
    score: number,
    text: string,
    corpus = "repo",
  ): Ranked => ({
    corpus,
    file,
    part: 0,
    section: "",
    text,
    similarity: score,
    score,
    keyword: 0,
  });
  const japan = "open_data/rest_apis/sql/rate_limited/14_company_dns_japan_create.sql";
  const ranked = [
    hit("open_data/other_create.sql", 0.99, "CREATE LIGHTNING DATABASE OTHER"),
    hit(dns, 0.5, "CREATE LIGHTNING REST TABLE company_dns"),
    hit(japan, 0.4, "CREATE LIGHTNING REST TABLE japan_raw"),
    hit(
      "docs/guides/zetaris-lightning-sql-commands.md",
      0.7,
      "CREATE LIGHTNING REST TABLE daily_weather AUTH BY weather_oauth",
    ),
    hit(
      "https://kbase.zetaris.com/knowledge/how-to-access-microsoft-purview",
      0.8,
      "Purview",
      "kbase",
    ),
  ];
  const readSql = (f: string) =>
    Promise.resolve(
      f === dns
        ? "-- rate limit and host notes\n\nCREATE LIGHTNING REST TABLE company_dns REQUEST (url 'https://example.invalid')"
        : "CREATE LIGHTNING DATABASE OTHER",
    );
  const found = await exampleContext(ranked, readSql, true, request);
  assertEquals(found.files, [dns]);
  assert(found.restScript);
  assert(found.ctx[0].text.startsWith("CREATE LIGHTNING REST TABLE"));
  assert(!found.ctx[0].text.includes("rate limit"));
  const covered = found.ctx.some((c) =>
    /create\s+/i.test(c.text) &&
    `${c.header}\n${c.text}`.toLowerCase().includes("company_dns")
  );
  assert(covered);
  const prompt = generatePrompt(request, true, covered);
  assert(prompt.includes("Reproduce the registration statements"));
  assert(prompt.includes("CREATE LIGHTNING REST TABLE"));
  assert(prompt.includes("CREATE LIGHTNING FILESTORE TABLE"));
  assert(prompt.includes("Follow the named script"));
  assert(prompt.includes("Do not add AUTH BY"));
  assert(!prompt.includes("inspired by the supplied example files"));
  assert(!prompt.includes("Do not copy a file"));
  assert(!prompt.includes("one statement per query"));
  assert(!prompt.includes("Not covered in the supplied files"));
  assert(generatePrompt(request, true, false).includes(
    "Not covered in the supplied files",
  ));
  const query = generatePrompt("Count the rows in the docs table");
  assert(query.includes("Do not copy a file"));
  assert(query.includes("one statement per query"));
});

Deno.test("a REST request with no script still asks for the REST command section", async () => {
  const doc =
    "### 6.2 CREATE LIGHTNING REST TABLE\n\nrest syntax\n\n### 6.3 NEXT\n\nother";
  const h = await hintedSections(
    "How do I register a REST API?",
    (f) => Promise.resolve(f.endsWith("commands.md") ? doc : null),
  );
  assertEquals(h.length, 1);
  assert(h[0].header.includes("CREATE LIGHTNING REST TABLE"));
  assert(!h[0].text.includes("other"));
});

Deno.test("isSetupRequest separates setup asks from queries", () => {
  for (
    const q of [
      "Show me how I connect to a database with Zetaris",
      "How do I register a REST source?",
      "set up a pipeline",
    ]
  ) assert(isSetupRequest(q), q);
  for (
    const q of [
      "Count the files per kind in the help_usl docs table",
      "Show the five longest sic_code descriptions",
      "List docs larger than 20000 bytes with their title",
    ]
  ) assert(!isSetupRequest(q), q);
});
