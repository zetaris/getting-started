import { assert, assertEquals } from "@std/assert";
import { fromBase64 } from "./corpus.ts";
import {
  exampleInsertSql,
  logExample,
  logsDocsSearch,
  logSearch,
  searchInsertSql,
} from "./activity.ts";
import type { ExampleResult } from "./example.ts";

const decode = (sql: string) =>
  [...sql.matchAll(/unbase64\('([A-Za-z0-9+/=]*)'\)/g)].map((m) =>
    fromBase64(m[1])
  );

const ID = "12345678-1234-1234-1234-123456789abc";

Deno.test("a search row stores the question and the surface, not raw quotes", () => {
  const sql = searchInsertSql(
    ID,
    "it's a search",
    "person:a1b2c3d4e5f67890",
    "search",
  );
  assert(sql.startsWith("INSERT INTO help_pg.searches"));
  assert(!sql.includes("it's"));
  assertEquals(decode(sql)[0], "it's a search");
  assert(sql.includes("'search'"));
});

Deno.test("docs results after page 1 are not a new search", () => {
  assert(logsDocsSearch(1));
  assert(logsDocsSearch(Number.NaN));
  assert(!logsDocsSearch(2));
});

Deno.test("an example row is written when SQL comes back, and not when it does not", async () => {
  const ran: string[] = [];
  const store = {
    run(sql: string) {
      ran.push(sql);
      return Promise.resolve();
    },
  };
  const result = {
    status: "dry-run passed",
    sql: "SELECT 1",
    notes: "",
    attempts: [{ n: 1, sql: "SELECT 1", error: null }],
    sources: [{ file: "a.sql" }],
    reason: null,
    model: "m",
    ms: 1,
  } as ExampleResult;
  await logExample(store, result, "count rows", "anonymous");
  assertEquals(ran.length, 1);
  assertEquals(decode(ran[0])[1], "SELECT 1");
  assert(ran[0].includes("'dry-run passed'"));

  ran.length = 0;
  await logExample(store, { ...result, sql: "" }, "count rows", "anonymous");
  assertEquals(ran.length, 0);
});

Deno.test("a failed search insert does not throw", async () => {
  await logSearch(
    {
      run() {
        return Promise.reject(new Error("down"));
      },
    },
    "how do I register",
    "anonymous",
    "answer",
  );
});

Deno.test("example insert rejects a status the checker does not use", () => {
  let threw = false;
  try {
    exampleInsertSql({
      id: ID,
      request: "q",
      sql: "SELECT 1",
      status: "verified" as "unverified",
      attempts: 1,
      model: "m",
      sources: "[]",
      who: "anonymous",
    });
  } catch {
    threw = true;
  }
  assert(threw);
});
