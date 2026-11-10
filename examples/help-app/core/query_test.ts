import { assertEquals } from "@std/assert";
import { cleanQuestion, MAX_QUESTION, parsePassage } from "./query.ts";
import {
  isCodeQuestion,
  pickCodeFiles,
  stripSqlHeader,
  wholeFileContext,
} from "./prompt.ts";

Deno.test("question is trimmed, control characters removed and length capped", () => {
  assertEquals(cleanQuestion("  a\u0000b \n c  "), "a b c");
  assertEquals(cleanQuestion("x".repeat(2000)).length, MAX_QUESTION);
});

Deno.test("a search row becomes a passage", () => {
  const p = parsePassage([
    "q",
    "REPO: kbase\nFILE: https://k.example/knowledge/x\nPART: 3\nSECTION: Intro\nTEXT: hello\nworld",
    "0.81",
  ]);
  assertEquals(p, {
    corpus: "kbase",
    file: "https://k.example/knowledge/x",
    part: 3,
    section: "Intro",
    text: "hello\nworld",
    similarity: 0.81,
  });
});

Deno.test("code questions and SQL headers", () => {
  assertEquals(isCodeQuestion("Show me an example SELECT"), true);
  assertEquals(isCodeQuestion("Who owns this repo?"), false);
  assertEquals(
    stripSqlHeader("-- a\n-- b\n\nSELECT 1;\n-- keep"),
    "SELECT 1;\n-- keep",
  );
});

Deno.test("whole-file context caps size and skips unreadable files", async () => {
  const out = await wholeFileContext(
    ["a.sql", "missing.md", "b.md"],
    (f) =>
      Promise.resolve(
        f === "missing.md"
          ? null
          : f === "a.sql"
          ? "-- h\nSELECT 1"
          : "y".repeat(9000),
      ),
  );
  assertEquals(out.length, 2);
  assertEquals(out[0].text, "SELECT 1");
  assertEquals(out[1].text.length, 7000);
});

Deno.test("code questions get two SQL scripts and two other files", () => {
  assertEquals(
    pickCodeFiles(["a.md", "b.md", "c.sql", "d.md", "e.sql", "f.sql"]),
    ["c.sql", "e.sql", "a.md", "b.md"],
  );
});
