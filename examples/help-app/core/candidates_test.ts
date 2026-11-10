import { assert, assertEquals, assertRejects } from "@std/assert";
import {
  candidateIdOf,
  candidateInsertSql,
  listCandidates,
  saveCandidate,
} from "./candidates.ts";

const unb = (sql: string) =>
  [...sql.matchAll(/unbase64\('([A-Za-z0-9+/=]*)'\)/g)].map((m) =>
    new TextDecoder().decode(
      Uint8Array.from(atob(m[1]), (c) => c.charCodeAt(0)),
    )
  );

function store() {
  const rows = new Map<string, string>();
  const sent: string[] = [];
  return {
    sent,
    rows,
    run: (sql: string) => {
      sent.push(sql);
      if (sql.startsWith("SELECT candidate_id FROM")) {
        const id = sql.match(/'([0-9a-f]{64})'/)![1];
        return Promise.resolve({
          headers: [],
          rows: rows.has(id) ? [[id]] : [],
        });
      }
      if (sql.startsWith("INSERT")) {
        rows.set(sql.match(/SELECT '([0-9a-f]{64})'/)![1], sql);
      }
      return Promise.resolve({ headers: [], rows: [] });
    },
  };
}

const catalog = () => Promise.resolve(new Set(["a.sql", "b.md"]));
const input = {
  request: "r",
  sql: "SELECT 1",
  attempts: 1,
  model: "m",
  sources: ["a.sql"],
  notes: "n",
  who: "Ann",
};

Deno.test("status is computed on the server, not taken from the input", async () => {
  const s = store();
  const ok = await saveCandidate(
    s,
    { ...input, status: "dry-run passed" } as never,
    catalog,
    () => Promise.resolve("plan"),
  );
  assertEquals(ok.existing, false);
  assert(s.sent.at(-1)!.includes("'dry-run passed', 1"));
  const ddl = await saveCandidate(
    s,
    { ...input, sql: "DROP TABLE x", status: "dry-run passed" } as never,
    catalog,
    () => Promise.resolve("plan"),
  );
  assert(ddl.id !== ok.id);
  assert(s.sent.at(-1)!.includes("'unverified', 1"));
  const bad = await saveCandidate(
    s,
    { ...input, sql: "SELECT nope" } as never,
    catalog,
    () => Promise.resolve("AnalysisException: [UNRESOLVED_COLUMN] nope"),
  );
  assert(s.rows.get(bad.id)!.includes("'unverified'"));
});

Deno.test("the same request and SQL saves once", async () => {
  const s = store();
  const ex = () => Promise.resolve("plan");
  assertEquals(
    (await saveCandidate(s, input as never, catalog, ex)).existing,
    false,
  );
  assertEquals(
    (await saveCandidate(s, input as never, catalog, ex)).existing,
    true,
  );
  assertEquals(s.rows.size, 1);
});

Deno.test("sources must be in the catalog, and at least one is required", async () => {
  const s = store();
  const ex = () => Promise.resolve("plan");
  for (const sources of [[], ["x.sql"], "a.sql", undefined]) {
    await assertRejects(() =>
      saveCandidate(s, { ...input, sources } as never, catalog, ex)
    );
  }
  await saveCandidate(
    s,
    { ...input, sources: ["x.sql", "b.md"] } as never,
    catalog,
    ex,
  );
  assertEquals(unb([...s.rows.values()][0])[3], '["b.md"]');
});

Deno.test("bad input is refused: empty request or SQL, attempts out of range", async () => {
  const s = store();
  const ex = () => Promise.resolve("plan");
  for (
    const bad of [{ request: "" }, { sql: " " }, { attempts: 0 }, {
      attempts: 4,
    }, { attempts: 1.5 }]
  ) {
    await assertRejects(() =>
      saveCandidate(s, { ...input, ...bad } as never, catalog, ex)
    );
  }
  assertEquals(s.sent.length, 0);
});

Deno.test("user text is only ever sent base64-encoded", async () => {
  const id = await candidateIdOf("r", "SELECT 1");
  const sql = candidateInsertSql({
    id,
    request: "it's a '; DROP TABLE x; --",
    sql: "SELECT 1",
    status: "unverified",
    attempts: 2,
    model: "m",
    sources: ["a.sql"],
    notes: "",
    who: "x'y",
  });
  assert(!sql.includes("DROP TABLE"));
  assertEquals(unb(sql)[0], "it's a '; DROP TABLE x; --");
  assertEquals(unb(sql).at(-1), "x'y");
});

Deno.test("listCandidates parses rows and filters by cited file", async () => {
  const rows = [
    [
      "i1",
      "req1",
      "SELECT 1",
      "unverified",
      "2",
      "m",
      '["a.sql"]',
      "",
      "2026-01-01",
      "Ann",
    ],
    [
      "i2",
      "req2",
      "SELECT 2",
      "dry-run passed",
      "1",
      "m",
      "not json",
      "",
      "2026-01-02",
      "Bob",
    ],
  ];
  const z = { run: () => Promise.resolve({ headers: [], rows }) };
  const all = await listCandidates(z);
  assertEquals(all.length, 2);
  assertEquals(all[1].sources, []);
  assertEquals((await listCandidates(z, "a.sql")).map((c) => c.id), ["i1"]);
});
