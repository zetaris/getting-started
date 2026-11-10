import { assert, assertEquals, assertRejects } from "@std/assert";
import { fromBase64 } from "./corpus.ts";
import type { Segment } from "./corpus.ts";
import {
  addEvent,
  createPin,
  findPast,
  listPins,
  normalizeQuestion,
  pinIdOf,
  pinPassage,
  type PinStore,
  staleness,
} from "./pins.ts";
import type { Passage } from "./query.ts";
import { AskError } from "./ask.ts";

const unb = (s: string) => fromBase64(s);
const decode = (sql: string) =>
  [...sql.matchAll(/unbase64\('([A-Za-z0-9+/=]*)'\)/g)].map((m) => unb(m[1]));

/** An in-memory stand-in for the Postgres tables behind Zetaris: it reads the SQL the module sends. */
function fakeStore(docs: Record<string, string>, hits: Passage[] = []) {
  const pins = new Map<
    string,
    {
      q: string;
      a: string;
      sources: string;
      who: string;
      status: string;
      at: number;
    }
  >();
  const events: { pin: string; kind: string; who: string }[] = [];
  const log: string[] = [];
  const embedded: Segment[] = [];
  let tick = 0;
  const likes = (id: string) =>
    events.filter((e) => e.pin === id).reduce(
      (n, e) => n + (e.kind === "like" ? 1 : e.kind === "unlike" ? -1 : 0),
      0,
    );
  const uses = (id: string) =>
    events.filter((e) => e.pin === id && e.kind === "use").length;
  const store: PinStore = {
    run(sql: string) {
      log.push(sql);
      const ok = (rows: string[][]) => Promise.resolve({ rows, headers: [] });
      if (sql.startsWith("SELECT count(*)")) {
        return ok([[pins.has(sql.match(/'([0-9a-f]{64})'/)![1]) ? "1" : "0"]]);
      }
      if (sql.startsWith("SELECT path, git_sha")) {
        return ok(
          decode(sql).filter((p) => p in docs).map((p) => [p, docs[p]]),
        );
      }
      if (sql.startsWith("SELECT likes, uses")) {
        const id = sql.match(/'([0-9a-f]{64})'/)![1];
        return ok([[String(likes(id)), String(uses(id))]]);
      }
      if (sql.startsWith("INSERT INTO help_pg.pins")) {
        const id = sql.match(/SELECT '([0-9a-f]{64})'/)![1];
        // Decoded values, in order: question, answer, model, collection, sources, who.
        const d = decode(sql);
        pins.set(id, {
          q: d[0],
          a: d[1],
          sources: d[4],
          who: d[5],
          status: "current",
          at: ++tick,
        });
        return ok([]);
      }
      if (sql.startsWith("INSERT INTO help_pg.pin_events")) {
        const m = sql.match(/SELECT '[^']+', '([0-9a-f]{64})', '(\w+)'/)!;
        events.push({ pin: m[1], kind: m[2], who: decode(sql)[0] });
        return ok([]);
      }
      if (sql.startsWith("SELECT p.pin_id")) {
        const inList = sql.match(/IN \(([^)]*)\)/)?.[1];
        const ids = inList
          ? [...inList.matchAll(/'([0-9a-f]{64})'/g)].map((m) => m[1])
          : [...pins.keys()];
        return ok(
          ids.filter((i) => pins.has(i) && pins.get(i)!.status === "current")
            .map((i) => {
              const p = pins.get(i)!;
              return [
                i,
                p.q,
                p.a,
                "answer",
                "m",
                p.sources,
                `t${p.at}`,
                p.who,
                p.status,
                String(likes(i)),
                String(uses(i)),
              ];
            }).sort((x, y) => Number(y[9]) - Number(x[9])),
        );
      }
      return Promise.reject(new Error(`unexpected sql: ${sql.slice(0, 60)}`));
    },
    embedPin: (seg) => (embedded.push(seg), Promise.resolve()),
    searchPins: () => Promise.resolve(hits),
  };
  return { store, pins, events, log, embedded };
}

const DOCS = { "a/b.md": "sha-b", "c/d.sql": "sha-d" };
const input = (over: Record<string, unknown> = {}) => ({
  question: "How do I register a REST source?",
  answer: "Use CREATE LIGHTNING REST TABLE.",
  model: "m1",
  sources: [{ file: "a/b.md" }, { file: "not/in/catalog.md" }],
  who: "Ann",
  ...over,
});

Deno.test("trivial rewordings normalise to the same question; a changed answer is a new pin", async () => {
  assertEquals(
    normalizeQuestion("  How do I   Register a REST source??  "),
    "how do i register a rest source",
  );
  assertEquals(
    await pinIdOf("How do I X?", "A"),
    await pinIdOf("how do i x", "A"),
  );
  assert((await pinIdOf("q", "A")) !== (await pinIdOf("q", "B")));
  assertEquals((await pinIdOf("q", "A")).length, 64);
});

Deno.test("pinning writes one row and one vector; pinning again changes nothing", async () => {
  const f = fakeStore(DOCS);
  const first = await createPin(f.store, input());
  assertEquals(first.existing, false);
  assertEquals(f.pins.size, 1);
  assertEquals(f.embedded.length, 1);
  assertEquals(f.embedded[0].corpus, "pin");
  assert(f.embedded[0].text.startsWith("QUESTION: How do I register"));
  const again = await createPin(f.store, input({ who: "Bob" }));
  assertEquals(again.existing, true);
  assertEquals(again.pinId, first.pinId);
  assertEquals(f.pins.size, 1);
  assertEquals(f.embedded.length, 1);
});

Deno.test("sources are checked against the catalog and recorded with their current hash", async () => {
  const f = fakeStore(DOCS);
  const { pinId } = await createPin(f.store, input());
  assertEquals(JSON.parse(f.pins.get(pinId)!.sources), [{
    file: "a/b.md",
    sha: "sha-b",
  }]);
});

Deno.test("what a user types never appears in the SQL text", async () => {
  const f = fakeStore(DOCS);
  await createPin(
    f.store,
    input({
      question: "x'); DROP TABLE pins; --",
      answer: "a'b",
      who: "o'brien",
    }),
  );
  const insert = f.log.find((s) => s.startsWith("INSERT INTO help_pg.pins"))!;
  assert(!/DROP|o'brien|a'b/.test(insert), insert);
  assertEquals(decode(insert)[0], "x'); DROP TABLE pins; --");
});

Deno.test("an empty question or answer is refused", async () => {
  const f = fakeStore(DOCS);
  for (const bad of [{ question: "  " }, { answer: "" }, { question: 5 }]) {
    const e = await assertRejects(
      () => createPin(f.store, input(bad)),
      AskError,
    );
    assertEquals(e.status, 400);
  }
  assertEquals(f.pins.size, 0);
});

Deno.test("likes are counted from events: like twice gives 2, unlike takes one back", async () => {
  const f = fakeStore(DOCS);
  const { pinId } = await createPin(f.store, input());
  assertEquals(await addEvent(f.store, { pinId, kind: "like", who: "Ann" }), {
    likes: 1,
    uses: 0,
  });
  assertEquals(await addEvent(f.store, { pinId, kind: "like", who: "Bob" }), {
    likes: 2,
    uses: 0,
  });
  assertEquals(await addEvent(f.store, { pinId, kind: "use", who: "Bob" }), {
    likes: 2,
    uses: 1,
  });
  assertEquals(
    (await addEvent(f.store, { pinId, kind: "unlike", who: "Bob" })).likes,
    1,
  );
  assertEquals(f.events.length, 4);
});

Deno.test("events for unknown pins, bad ids and unsupported kinds are refused", async () => {
  const f = fakeStore(DOCS);
  const cases: [Record<string, unknown>, number][] = [
    [{ pinId: "0".repeat(64), kind: "like" }, 404],
    [{ pinId: "nope", kind: "like" }, 400],
    [{ pinId: "0".repeat(64), kind: "delete" }, 400],
    [{ pinId: "0".repeat(64), kind: "retire" }, 400],
  ];
  for (const [c, status] of cases) {
    const e = await assertRejects(
      () => addEvent(f.store, { who: "x", ...c } as never),
      AskError,
    );
    assertEquals(e.status, status);
  }
  assertEquals(f.events.length, 0);
});

Deno.test("past answers: the threshold applies to similarity, and likes can reorder close matches", async () => {
  const a = await pinIdOf("question a", "answer a");
  const b = await pinIdOf("question b", "answer b");
  const c = await pinIdOf("question c", "answer c");
  const hit = (file: string, similarity: number): Passage => ({
    corpus: "pin",
    file,
    part: 0,
    section: "",
    text: "",
    similarity,
  });
  const f = fakeStore(DOCS, [hit(a, 0.85), hit(b, 0.84), hit(c, 0.80)]);
  for (
    const [q, ans] of [["question a", "answer a"], ["question b", "answer b"], [
      "question c",
      "answer c",
    ]]
  ) {
    await createPin(f.store, input({ question: q, answer: ans, sources: [] }));
  }
  let past = await findPast(f.store, "anything", 0.82);
  assertEquals(past.map((p) => p.pinId), [a, b]); // c is under 0.82
  for (let i = 0; i < 5; i++) {
    await addEvent(f.store, { pinId: b, kind: "like", who: `u${i}` });
  }
  past = await findPast(f.store, "anything", 0.82);
  assertEquals(past.map((p) => p.pinId), [b, a]); // 0.84 + 0.03 ln 6 beats 0.85
  assertEquals(past[0].likes, 5);
  assert(Math.abs(past[0].score - (0.84 + 0.03 * Math.log(6))) < 1e-9);
});

Deno.test("a vector with no row is ignored, and a non-hex id never reaches SQL", async () => {
  const hit = (file: string): Passage => ({
    corpus: "pin",
    file,
    part: 0,
    section: "",
    text: "",
    similarity: 0.95,
  });
  const f = fakeStore(DOCS, [hit("1".repeat(64)), hit("x'; DROP")]);
  assertEquals(await findPast(f.store, "q", 0.82), []);
  assert(!f.log.some((s) => s.includes("DROP")));
});

Deno.test("staleness: changed hash, missing file, or current", () => {
  const src = [{ file: "a.md", sha: "1" }, { file: "b.md", sha: "2" }];
  assertEquals(
    staleness(src, new Map([["a.md", "1"], ["b.md", "2"]])).state,
    "current",
  );
  assertEquals(staleness(src, new Map([["a.md", "1"], ["b.md", "9"]])), {
    state: "changed",
    files: ["b.md"],
  });
  assertEquals(staleness(src, new Map([["a.md", "1"]])), {
    state: "missing",
    files: ["b.md"],
  });
  assertEquals(staleness([], new Map()).state, "current");
});

Deno.test("the listing carries the stale flag against the current catalog", async () => {
  const f = fakeStore(DOCS);
  await createPin(f.store, input({ sources: [{ file: "a/b.md" }] }));
  assertEquals((await listPins(f.store))[0].stale.state, "current");
  DOCS["a/b.md"] = "sha-b-NEW"; // the file changed after pinning
  try {
    const l = await listPins(f.store);
    assertEquals(l[0].stale, { state: "changed", files: ["a/b.md"] });
  } finally {
    DOCS["a/b.md"] = "sha-b";
  }
});

Deno.test("the pin passage stays under the chunking guard", () => {
  const seg = pinPassage("a".repeat(64), "q".repeat(500), "x".repeat(8000));
  assert(seg.text.length <= 1200 && seg.text.startsWith("QUESTION: "));
});
