import { assert, assertEquals } from "@std/assert";
import {
  fromBase64,
  kindOf,
  MAX_TEXT,
  splitDocument,
  titleOf,
  toBase64,
} from "./corpus.ts";

const SAMPLE = `# Title here

Intro paragraph.

## Small

tiny.

## Big section

${"word ".repeat(400)}

\`\`\`sql
${Array.from({ length: 120 }, (_, i) => `SELECT ${i} FROM t;`).join("\n")}
\`\`\`

### Last

Final text with 'quotes', "double" and a newline.
`;

Deno.test("no segment is over the guard size and every one has a file and part", () => {
  const segs = splitDocument("repo", "docs/x.md", SAMPLE);
  assert(segs.length > 3);
  segs.forEach((s, i) => {
    assert(s.text.length <= MAX_TEXT, `segment ${i} has ${s.text.length}`);
    assertEquals(s.file, "docs/x.md");
    assertEquals(s.part, i);
  });
});

Deno.test("small sections are carried into the next one, not emitted alone", () => {
  const segs = splitDocument("repo", "x.md", SAMPLE);
  assert(!segs.some((s) => s.text === "tiny."));
  assert(segs.some((s) => s.text.includes("tiny.")));
});

Deno.test("a fenced block that fits is kept whole", () => {
  const md = "# A\n\n" + "x".repeat(600) +
    "\n\n```sql\nSELECT 1;\nSELECT 2;\n```\n";
  const segs = splitDocument("repo", "x.md", md);
  assert(
    segs.some((s) => s.text.includes("```sql\nSELECT 1;\nSELECT 2;\n```")),
  );
});

Deno.test("headings inside a code fence do not start sections", () => {
  const md = "# A\n\n```\n# not a heading\n```\n\n" + "y".repeat(500) + "\n";
  const segs = splitDocument("repo", "x.md", md);
  assertEquals(segs[0].section, "A");
});

Deno.test("base64 round-trips quotes, newlines and non-ASCII", () => {
  const t = 'It\'s a "test"; DROP TABLE pins; --\nline2 é — ✓';
  assertEquals(fromBase64(toBase64(t)), t);
});

Deno.test("title and kind", () => {
  assertEquals(titleOf("a/b.md", "x\n# My `Title`\n"), "My Title");
  assertEquals(titleOf("a/b.md", "no heading"), "b.md");
  assertEquals(kindOf("AGENTS.md"), "agent-rules");
  assertEquals(kindOf("open_data/rest_apis/HOWTO.md"), "howto");
  assertEquals(kindOf("docs/guides/first-dataset.md"), "guide");
  assertEquals(kindOf("docs/plans/archive/x.md"), "plan");
});
