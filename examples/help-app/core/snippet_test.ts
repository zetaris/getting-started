import { assert, assertEquals } from "@std/assert";
import { matchSnippet } from "./snippet.ts";

const lead = "Intro heading stays at the front. ".repeat(12);
const body = `${lead}Register the REST source after the introduction.`;

Deno.test("the snippet windows around the first question word", () => {
  const { text, html } = matchSnippet("register a rest source", body);
  assert(text.startsWith("…"));
  assert(text.toLowerCase().includes("register the rest source"));
  assert(!text.startsWith("Intro"));
  assert(html.includes("<mark>Register</mark>"));
  assert(html.includes("<mark>REST</mark>"));
  assert(!html.includes("<script"));
});

Deno.test("a passage with no question word starts at the beginning", () => {
  const { text, html } = matchSnippet(
    "register a rest source",
    "Nothing here.",
  );
  assertEquals(text, "Nothing here.");
  assertEquals(html, "Nothing here.");
});

Deno.test("markup in the passage is escaped, and a match inside it is still marked", () => {
  const { html } = matchSnippet(
    "register a rest source",
    "See <script>alert(1)</script> then register the source.",
  );
  assert(!html.includes("<script"));
  assert(html.includes("&lt;script"));
  assert(html.includes("<mark>register</mark>"));
});
