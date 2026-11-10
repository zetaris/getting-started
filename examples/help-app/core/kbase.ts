// Kbase page handling: sitemap parsing, HTML to Markdown, credential redaction, page kind.
// Pure functions (no network) so they can be unit tested; scripts/fetch_kbase.ts does the I/O.
import { DOMParser } from "@b-fuze/deno-dom";
import TurndownService from "turndown";
import { gfm } from "turndown-plugin-gfm";

export interface SitemapEntry {
  url: string;
  lastmod: string;
}

export function parseSitemap(xml: string): SitemapEntry[] {
  const out: SitemapEntry[] = [];
  for (const m of xml.matchAll(/<url>([\s\S]*?)<\/url>/g)) {
    const url = m[1].match(/<loc>([^<]+)<\/loc>/)?.[1]?.trim();
    const lastmod = m[1].match(/<lastmod>([^<]+)<\/lastmod>/)?.[1]?.trim() ??
      "";
    if (url) out.push({ url, lastmod });
  }
  return out;
}

export function slugOf(url: string): string {
  return new URL(url).pathname.replace(/^\/knowledge\//, "").replace(
    /[^a-zA-Z0-9._-]+/g,
    "-",
  )
    .replace(/^-+|-+$/g, "") || "index";
}

export function kindOfPage(slug: string, title: string): string {
  const s = `${slug} ${title}`.toLowerCase();
  if (/product-version|release|what-s-new|whats-new/.test(s)) {
    return "release-note";
  }
  if (/troubleshoot/.test(s)) return "troubleshooting";
  if (/\bfaq\b|frequently/.test(s)) return "faq";
  if (/sql-guide|sql-manual|sql-reference|command/.test(s)) {
    return "sql-reference";
  }
  if (/video|webinar/.test(s)) return "video";
  if (/how-to|how to|getting-started|guide|tutorial/.test(s)) return "how-to";
  return "other";
}

const CREDENTIAL_PATTERNS = [
  /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g,
  /(password|passwd|secret|token|api[_-]?key)(\s*[:=]\s*)\S+/gi,
  /(client[_-]?id|client[_-]?secret)(\s*[:=]\s*)["']?\w{10,}/gi,
];

/** Replace e-mail addresses and `name = value` credential pairs. Returns the text and the
 * number of replacements, so the manifest can say which pages needed it. */
export function redact(text: string): { text: string; count: number } {
  let count = 0;
  let out = text;
  CREDENTIAL_PATTERNS.forEach((re, i) => {
    out = out.replace(re, (...m) => {
      count++;
      return i === 0 ? "<REDACTED>" : `${m[1]}${m[2]}<REDACTED>`;
    });
  });
  return { text: out, count };
}

export interface ConvertedPage {
  title: string;
  markdown: string;
  textChars: number;
  images: number;
  embeds: number;
}

function turndown() {
  const td = new TurndownService({
    headingStyle: "atx",
    codeBlockStyle: "fenced",
    bulletListMarker: "-",
  });
  td.use(gfm);
  td.remove(["script", "style", "noscript", "iframe", "button", "form"]);
  // Keep image alt text and link, but drop the query string (size and cache parameters).
  td.addRule("imgNoQuery", {
    filter: "img",
    replacement: (
      _c: string,
      node: { getAttribute(n: string): string | null },
    ) => {
      const src = (node.getAttribute("src") ?? "").split("?")[0];
      return src ? `![${node.getAttribute("alt") ?? ""}](${src})` : "";
    },
  });
  // Any <pre> becomes a fenced block, also when it has no <code> child (the SQL Manual's).
  td.addRule("preAny", {
    filter: "pre",
    replacement: (_content: string, node: { textContent: string | null }) =>
      `\n\n\`\`\`\n${(node.textContent ?? "").replace(/\n+$/, "")}\n\`\`\`\n\n`,
  });
  return td;
}

/** The article body as Markdown. Navigation, cookie banners and related-article blocks live
 * outside `article.knowledgebase-post` on this site's template, so selecting it drops them. */
export function convertPage(html: string): ConvertedPage | null {
  const doc = new DOMParser().parseFromString(html, "text/html");
  const article = doc.querySelector("article.knowledgebase-post");
  if (!article) return null;
  const title = article.querySelector("h1")?.textContent.trim() ??
    doc.querySelector("title")?.textContent.trim() ?? "";
  article.querySelector("h1")?.remove();
  const images = article.querySelectorAll("img").length;
  const embeds =
    article.querySelectorAll("iframe, video, embed, object").length;
  let textChars = article.textContent.replace(/\s+/g, " ").trim().length;
  let body = article.innerHTML;
  // A second template: the SQL Manual keeps its text in Sphinx-style `div.section` blocks
  // outside the article wrapper (the wrapper holds only a placeholder word).
  if (textChars < 200) {
    const top = [...doc.querySelectorAll("div.section")].filter((d) =>
      !d.parentElement?.closest("div.section")
    );
    const sectionChars = top.reduce(
      (n, d) => n + d.textContent.replace(/\s+/g, " ").trim().length,
      0,
    );
    if (top.length > 0 && sectionChars > textChars) {
      top.forEach((d) =>
        d.querySelectorAll("a.headerlink").forEach((a) => a.remove())
      );
      body = top.map((d) => d.innerHTML).join("\n");
      textChars = sectionChars;
    }
  }
  const md = turndown().turndown(body).replace(/\n{3,}/g, "\n\n").trim();
  return { title, markdown: md, textChars, images, embeds };
}

export async function sha256(text: string): Promise<string> {
  const d = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** A page with almost no text but images or embeds is skipped in v1 (text only). */
export function isTextless(p: ConvertedPage): boolean {
  return p.textChars < 200 && (p.images > 0 || p.embeds > 0);
}
