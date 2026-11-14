import { assert, assertEquals } from "@std/assert";
import {
  fromBase64,
  kindOf,
  MAX_TEXT,
  splitByMode,
  splitDocument,
  splitWindows,
  titleOf,
  toBase64,
  withNeighborOverlap,
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

Deno.test("SQL scripts are cut at blank lines, take a section from comments, and stay under the guard", () => {
  const sql = "-- Create the table\nCREATE TABLE a (x INT)\n\n" +
    Array.from({ length: 80 }, (_, i) => `SELECT ${i} FROM a`).join("\n") +
    "\n\n-- Second\nSELECT 2";
  const segs = splitDocument("repo", "open_data/x/01_create.sql", sql);
  assert(segs.length >= 2);
  assert(segs.every((s) => s.text.length <= MAX_TEXT));
  assertEquals(segs[0].section, "Create the table");
  assertEquals(segs[segs.length - 1].section, "Second");
  assertEquals(kindOf("open_data/x/01_create.sql"), "sql");
});

Deno.test("windows share 100 characters and stay under the guard", () => {
  const body = "a".repeat(2500);
  const segs = splitWindows("repo", "x.md", `# Kept\n\n${body}`);
  assert(segs.length >= 3);
  assert(segs.every((s) => s.text.length <= MAX_TEXT));
  assertEquals(segs[0].section, "Kept");
  const second = segs[1].text;
  assert(segs[0].text.endsWith(second.slice(0, 80)));
});

Deno.test("neighbor overlap repeats the previous tail and does not pass the guard", () => {
  const segs = withNeighborOverlap([
    {
      corpus: "repo",
      file: "a.md",
      part: 0,
      section: "A",
      text: "x".repeat(200),
    },
    {
      corpus: "repo",
      file: "a.md",
      part: 1,
      section: "B",
      text: "y".repeat(1250),
    },
  ]);
  assertEquals(segs[0].text.length, 200);
  assert(segs[1].text.startsWith("x".repeat(50)));
  assert(segs[1].text.endsWith("y".repeat(50)));
  assertEquals(segs[1].text.length, MAX_TEXT);
});

Deno.test("overlap mode does not change the first segment of a file", () => {
  const md = `# One\n\n${"a".repeat(800)}\n\n# Two\n\n${"b".repeat(800)}\n`;
  const current = splitDocument("repo", "x.md", md);
  const overlapped = splitByMode("repo", "x.md", md, "overlap");
  assertEquals(overlapped[0].text, current[0].text);
  assert(overlapped.length === current.length);
  if (overlapped.length > 1) {
    assert(overlapped[1].text.endsWith(current[1].text));
    assert(overlapped[1].text.length <= MAX_TEXT);
    assert(overlapped[1].text.length >= current[1].text.length);
  }
});
