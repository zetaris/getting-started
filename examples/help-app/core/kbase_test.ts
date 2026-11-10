import { assert, assertEquals } from "@std/assert";
import {
  convertPage,
  isTextless,
  kindOfPage,
  parseSitemap,
  redact,
  slugOf,
} from "./kbase.ts";

Deno.test("sitemap entries with lastmod", () => {
  const xml =
    "<urlset><url><loc>https://k.example/knowledge/a-b</loc><lastmod>2026-01-02</lastmod></url><url><loc>https://k.example/knowledge/c</loc></url></urlset>";
  assertEquals(parseSitemap(xml), [
    { url: "https://k.example/knowledge/a-b", lastmod: "2026-01-02" },
    { url: "https://k.example/knowledge/c", lastmod: "" },
  ]);
  assertEquals(slugOf("https://k.example/knowledge/a-b"), "a-b");
});

Deno.test("redaction hides e-mails and credential pairs and counts them", () => {
  const r = redact("mail me@example.com, password = hunter2, token: abc123");
  assertEquals(r.count, 3);
  assert(!/hunter2|abc123|me@example/.test(r.text));
  assert(r.text.includes("password = <REDACTED>"));
});

Deno.test("page kinds", () => {
  assertEquals(kindOfPage("product-version-2.3", ""), "release-note");
  assertEquals(
    kindOfPage("x", "Troubleshooting - credential drift"),
    "troubleshooting",
  );
  assertEquals(kindOfPage("sql-guide", "Zetaris SQL Guide"), "sql-reference");
});

Deno.test("article is converted; navigation outside it is dropped; SQL stays fenced", () => {
  const html =
    `<html><body><nav>MENU LINKS</nav><main><article class="knowledgebase-post">
    <h1>My Page</h1><div><h2>Step one</h2><p>Run this:</p>
    <pre><code>SELECT 1;</code></pre>
    <table><tr><th>a</th><th>b</th></tr><tr><td>1</td><td>2</td></tr></table>
    <p>${
      "more text ".repeat(30)
    }</p></div></article></main><footer>FOOTER</footer></body></html>`;
  const p = convertPage(html)!;
  assertEquals(p.title, "My Page");
  assert(!p.markdown.includes("MENU") && !p.markdown.includes("FOOTER"));
  assert(p.markdown.includes("## Step one"));
  assert(p.markdown.includes("```\nSELECT 1;\n```"));
  assert(p.markdown.includes("| a | b |"));
  assertEquals(isTextless(p), false);
});

Deno.test("an image-only page is textless", () => {
  const p = convertPage(
    `<article class="knowledgebase-post"><h1>T</h1><p><img src="x.png" alt=""></p></article>`,
  )!;
  assert(isTextless(p));
});

Deno.test("a Sphinx-style page whose article holds only a placeholder uses its sections", () => {
  const html =
    `<html><body><main><article class="knowledgebase-post"><h1>Manual</h1><div>test</div></article>
    <div class="section" id="a"><h2>1. SELECT<a class="headerlink" href="#a">¶</a></h2>
    <p>${
      "select text ".repeat(30)
    }</p><div class="highlight-sql"><pre>SELECT 1</pre></div>
    <div class="section" id="b"><h3>Nested</h3><p>nested body</p></div></div></main></body></html>`;
  const p = convertPage(html)!;
  assert(p.markdown.includes("SELECT"));
  assert(p.markdown.includes("nested body"));
  assert(!p.markdown.includes("¶"));
  assert(p.textChars > 200);
});
