import { assert, assertEquals, assertRejects } from "@std/assert";
import { ask, type AskDeps, AskError, toAskError } from "./ask.ts";
import { InFlight } from "./limit.ts";
import type { Passage } from "./query.ts";
import { ZetarisError } from "./zetaris.ts";

const p = (
  file: string,
  text: string,
  similarity: number,
  corpus = "repo",
): Passage => ({
  corpus,
  file,
  part: 0,
  section: "Sec",
  text,
  similarity,
});

function deps(over: Partial<AskDeps> = {}): AskDeps {
  return {
    llmConfigured: true,
    search: () =>
      Promise.resolve([
        p("a.md", "register a rest source here", 0.8),
        p("b.md", "unrelated", 0.7),
        p("https://kbase.example/knowledge/x", "kbase text", 0.6, "kbase"),
      ]),
    answer: () => Promise.resolve("the answer"),
    readFile: () => Promise.resolve(null),
    ...over,
  };
}

Deno.test("search mode returns ranked sources and no answer", async () => {
  const r = await ask(deps(), {
    question: "register a rest source",
    mode: "search",
  });
  assertEquals(r.answer, null);
  assertEquals(r.sources.map((s) => s.file)[0], "a.md");
  assertEquals(r.sources[2].url, "https://kbase.example/knowledge/x");
  assertEquals(r.sources[0].url, null);
});

Deno.test("answer mode calls the model with contexts and returns its text", async () => {
  let seen = 0;
  const r = await ask(
    deps({ answer: (_q, c) => (seen = c.length, Promise.resolve("A")) }),
    { question: "how do I register", mode: "answer" },
  );
  assertEquals(r.answer, "A");
  assert(seen > 0);
});

Deno.test("empty and whitespace-only questions are refused", async () => {
  for (const q of ["", "   \n "]) {
    const e = await assertRejects(
      () => ask(deps(), { question: q, mode: "search" }),
      AskError,
    );
    assertEquals(e.code, "empty_question");
  }
});

Deno.test("answer mode without an LLM is refused, and search still works", async () => {
  const d = deps({ llmConfigured: false });
  const e = await assertRejects(
    () => ask(d, { question: "x y", mode: "answer" }),
    AskError,
  );
  assertEquals(e.code, "llm_not_configured");
  await ask(d, { question: "x y", mode: "search" });
});

Deno.test("Zetaris failures become clear messages with no server text", () => {
  const cases: [ZetarisError, string][] = [
    [
      new ZetarisError("Cannot reach http://h:1: boom", "unreachable"),
      "zetaris_unreachable",
    ],
    [new ZetarisError("No answer within 120 s", "timeout"), "zetaris_timeout"],
    [new ZetarisError("HTTP 401: SELECT secret", "http", 401), "zetaris_key"],
    [new ZetarisError("HTTP 400: SELECT secret", "http", 400), "zetaris_error"],
    [new ZetarisError("no key", "config"), "zetaris_config"],
  ];
  for (const [err, code] of cases) {
    const a = toAskError(err);
    assertEquals(a.code, code);
    assert(!/SELECT|http:\/\/|boom/.test(a.message), a.message);
  }
  assertEquals(toAskError(new Error("x")).code, "zetaris_error");
});

Deno.test("a search failure is reported, not thrown raw", async () => {
  const d = deps({
    search: () => Promise.reject(new ZetarisError("x", "unreachable")),
  });
  const e = await assertRejects(
    () => ask(d, { question: "hello there", mode: "search" }),
    AskError,
  );
  assertEquals(e.status, 503);
});

Deno.test("code questions give the model whole files", async () => {
  let headers: string[] = [];
  const d = deps({
    search: () =>
      Promise.resolve([
        p("x/create.sql", "select 1", 0.9),
        p("x/HOWTO.md", "t", 0.8),
      ]),
    readFile: (f) =>
      Promise.resolve(f.endsWith(".sql") ? "-- h\nSELECT 1" : "doc"),
    answer: (
      _q,
      c,
    ) => (headers = c.map((x) => x.header), Promise.resolve("ok")),
  });
  await ask(d, { question: "show me an example query", mode: "answer" });
  assert(headers.some((h) => h.includes("WHOLE FILE: yes")));
});

Deno.test("only one request per session is allowed at a time", () => {
  const l = new InFlight();
  const r1 = l.tryStart("s1");
  assert(r1);
  assertEquals(l.tryStart("s1"), null);
  assert(l.tryStart("s2"));
  r1();
  assert(l.tryStart("s1"));
});

const pastOf = (answer: string) =>
  ({
    pinId: "a".repeat(64),
    question: "How do I register a REST source?",
    answer,
    sources: [],
    likes: 2,
    uses: 0,
    stale: "current",
    similarity: 0.9,
    score: 0.93,
  }) as unknown as import("./pins.ts").PastAnswer;

Deno.test("past answers are returned with safe HTML", async () => {
  const r = await ask(
    deps({
      pastAnswers: () => Promise.resolve([pastOf("hi <script>x()</script>")]),
    }),
    { question: "register a rest source", mode: "search" },
  );
  assertEquals(r.pastAnswers.length, 1);
  assert(!r.pastAnswers[0].answerHtml.includes("<script>"));
});

Deno.test("a failing past-answer lookup does not fail the ask", async () => {
  const r = await ask(
    deps({ pastAnswers: () => Promise.reject(new Error("milvus down")) }),
    { question: "register a rest source", mode: "search" },
  );
  assertEquals(r.pastAnswers, []);
  assert(r.sources.length > 0);
});

Deno.test("answer HTML escapes raw HTML from the model", async () => {
  const r = await ask(
    deps({
      answer: () => Promise.resolve("ok <img src=x onerror=alert(1)>"),
    }),
    { question: "how do I register", mode: "answer" },
  );
  assert(r.answerHtml !== null && !r.answerHtml.includes("<img"));
});
