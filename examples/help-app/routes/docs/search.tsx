import { page } from "fresh";
import { define } from "../../utils.ts";
import { DocsShell } from "../../components/DocsShell.tsx";
import { docHref, type DocRow, listDocs } from "../../core/docs.ts";
import { toAskError } from "../../core/ask.ts";
import { cleanQuestion } from "../../core/query.ts";
import { rerank, topFiles } from "../../core/rank.ts";
import { askDeps, getZetaris } from "../../core/server.ts";

/** Markdown as readable text for a result snippet: no heading marks, emphasis, images or link targets. */
export function plainExcerpt(md: string, max = 300): string {
  const t = md
    .replace(/```[a-z]*\n?/gi, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, " ")
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/^#{1,6}\s*/gm, "")
    .replace(/[*_`>|]+/g, "")
    .replace(/\s+/g, " ")
    .trim();
  return t.length > max ? `${t.slice(0, max).trimEnd()}…` : t;
}

interface Hit {
  file: string;
  corpus: string;
  title: string;
  href: string;
  section: string;
  similarity: number;
  excerpt: string;
}

export const handler = define.handlers({
  async GET(ctx) {
    const q = cleanQuestion(ctx.url.searchParams.get("q") ?? "");
    try {
      const z = getZetaris(30_000);
      if (!z) throw new Error("no key");
      const rows = await listDocs(z);
      if (!q) return page({ q, rows, hits: [] as Hit[], error: "" });
      const titles = new Map(rows.map((d) => [d.path, d.title]));
      const ranked = rerank(q, await askDeps().search(q, 100));
      const hits: Hit[] = topFiles(ranked, 12).map((h) => ({
        file: h.file,
        corpus: h.corpus,
        title: titles.get(h.file) ?? h.file,
        href: docHref(h.file),
        section: h.passages[0].section,
        similarity: h.passages[0].similarity,
        excerpt: plainExcerpt(h.passages[0].text),
      }));
      return page({ q, rows, hits, error: "" });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({ q, rows: [] as DocRow[], hits: [] as Hit[], error: msg });
    }
  },
});

export default define.page<typeof handler>(function DocsSearch({ data }) {
  const { q, rows, hits, error } = data;
  return (
    <DocsShell rows={rows} current="" q={q}>
      <p class="eyebrow">Search</p>
      <h1>{q ? "Results" : "Search the docs"}</h1>
      {q && (
        <p class="lead" data-testid="hit-count">
          {hits.length} pages for "{q}", ranked by meaning with a keyword boost.
        </p>
      )}
      {error && (
        <div class="alert" role="alert" data-testid="error">{error}</div>
      )}
      {!error && q && hits.length === 0 && (
        <p data-testid="no-hits">Nothing matched. Try different words.</p>
      )}
      <div>
        {hits.map((h) => (
          <div class="hit" data-testid="hit">
            <h3>
              <a href={h.href}>{h.title}</a>
            </h3>
            <div class="meta">
              <span class={`pill ${h.corpus === "kbase" ? "warn" : ""}`}>
                {h.corpus === "kbase" ? "Knowledge base" : "Repo docs"}
              </span>
              {h.section && <span>{h.section}</span>}
              <span>similarity {h.similarity.toFixed(2)}</span>
            </div>
            <p>{h.excerpt}</p>
          </div>
        ))}
      </div>
    </DocsShell>
  );
});
