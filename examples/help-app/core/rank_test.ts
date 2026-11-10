import { assert, assertEquals } from "@std/assert";
import { keywordShare, questionWords, rerank, topFiles } from "./rank.ts";
import type { Passage } from "./query.ts";

const p = (file: string, text: string, similarity: number): Passage => ({
  corpus: "repo",
  file,
  part: 0,
  section: "",
  text,
  similarity,
});

Deno.test("question words drop short words and stop words", () => {
  assertEquals(questionWords("How do I compile the USL model?").sort(), [
    "compile",
    "model",
  ]);
});

Deno.test("keyword share counts words in text or path", () => {
  const q = "register rest source";
  assertEquals(keywordShare(q, p("a/rest.md", "register the source", 0.5)), 1);
  assertEquals(keywordShare(q, p("a/x.md", "nothing here", 0.5)), 0);
});

Deno.test("the keyword weight can lift a lower-similarity passage", () => {
  const ps = [
    p("a.md", "unrelated words", 0.80),
    p("b.md", "register rest source steps", 0.78),
  ];
  assertEquals(
    rerank("register rest source", ps, { weight: 0 })[0].file,
    "a.md",
  );
  assertEquals(
    rerank("register rest source", ps, { weight: 0.15 })[0].file,
    "b.md",
  );
});

Deno.test("files are grouped and scored by their best passage", () => {
  const ranked = rerank("zzzz", [
    p("a.md", "x", 0.5),
    p("b.md", "x", 0.7),
    p("a.md", "x", 0.6),
  ], {
    weight: 0,
  });
  const files = topFiles(ranked, 5);
  assertEquals(files.map((f) => f.file), ["b.md", "a.md"]);
  assertEquals(files[1].passages.length, 2);
  assert(files[1].score === 0.6);
});

Deno.test("version numbers count as keywords", () => {
  assertEquals(questionWords("What changed in release 2.4.1.0?").sort(), [
    "2.4.1.0",
    "changed",
    "release",
  ]);
});
