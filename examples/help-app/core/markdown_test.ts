import { assert, assertEquals } from "@std/assert";
import { escapeHtml, renderMarkdown, safeUrl } from "./markdown.ts";

Deno.test("raw HTML in the source is escaped, never passed through", () => {
  for (
    const payload of [
      "<script>alert(1)</script>",
      '<img src=x onerror="alert(1)">',
      "text <b onmouseover=alert(1)>x</b> more",
      "<iframe src=//evil></iframe>",
      "<svg/onload=alert(1)>",
    ]
  ) {
    const html = renderMarkdown(payload);
    assert(!/<script|<img|<iframe|<svg|<b /i.test(html), html);
    assert(html.includes("&lt;"), html);
  }
});

Deno.test("dangerous link and image schemes are dropped, safe ones kept", () => {
  const bad = renderMarkdown(
    "[a](javascript:alert(1)) [b](JaVaScRiPt:alert(1)) [c](data:text/html,x) [d](vbscript:x) [e](java\tscript:alert(1)) ![f](javascript:alert(1)) [g](//evil.example/x)",
  );
  assert(!/href="(javascript|data|vbscript|\/\/)/i.test(bad), bad);
  assert(!/<img/.test(bad), bad);
  const good = renderMarkdown(
    "[ok](https://example.com/a?b=1&c=2) [rel](../x.md) [m](mailto:a@b.c)",
  );
  assert(good.includes('href="https://example.com/a?b=1&amp;c=2"'));
  assert(good.includes('href="../x.md"'));
  assert(good.includes("noopener"));
});

Deno.test("attribute values cannot break out of their quotes", () => {
  const html = renderMarkdown('[x](https://a.example/" onmouseover="alert(1))');
  assert(
    /^<p>\[x\]\(<a href="[^"]*" rel="noopener noreferrer">[^<]*<\/a>[^<]*<\/p>\s*$/
      .test(html),
    html,
  );
  const alt = renderMarkdown(
    '![a" onerror="alert(1)](https://a.example/i.png)',
  );
  // Structure check: exactly src, alt, loading, with no quote escaping out of the alt value.
  assert(
    /^<p><img src="[^"]*" alt="[^"]*" loading="lazy"><\/p>\s*$/.test(alt),
    alt,
  );
});

Deno.test("normal Markdown still renders: headings, tables, code fences", () => {
  const html = renderMarkdown(
    "# T\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\n```sql\nSELECT 1 < 2\n```\n",
  );
  assert(html.includes("<h1>"));
  assert(html.includes("<table>"));
  assert(html.includes("SELECT 1 &lt; 2"));
});

Deno.test("safeUrl and escapeHtml", () => {
  assertEquals(safeUrl("javascript:1"), null);
  assertEquals(safeUrl(" https://a.example "), "https://a.example");
  assertEquals(safeUrl("docs/a.md#x"), "docs/a.md#x");
  assertEquals(safeUrl(""), null);
  assertEquals(
    escapeHtml(`<a href="x">'&`),
    "&lt;a href=&quot;x&quot;&gt;&#39;&amp;",
  );
});

Deno.test("a bare <br> inside a table cell becomes a line break; other tags stay escaped", () => {
  const html = renderMarkdown(
    "| a | b |\n|---|---|\n| x<br>y<br/>z | <br onclick=alert(1)> |",
  );
  assert(html.includes("x<br>y<br>z"), html);
  assert(!/<br [^>]*onclick/i.test(html), html);
  assert(html.includes("&lt;br onclick"), html);
});
