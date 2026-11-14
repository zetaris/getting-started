import { page } from "fresh";
import { define } from "../../utils.ts";
import { DocsShell } from "../../components/DocsShell.tsx";
import { Html } from "../../components/Html.tsx";
import { ResultHead } from "../../components/SourceCard.tsx";
import { docHref, type DocRow, listDocs } from "../../core/docs.ts";
import { toAskError } from "../../core/ask.ts";
import { pageWindow } from "../../core/page.ts";
import { cleanQuestion } from "../../core/query.ts";
import { rerank, topFiles } from "../../core/rank.ts";
import { matchSnippet } from "../../core/snippet.ts";
import { askDeps, getZetaris } from "../../core/server.ts";

interface Hit {
  file: string;
  corpus: string;
  title: string;
  href: string;
  section: string;
  similarity: number;
  score: number;
  snippetHtml: string;
}

export const handler = define.handlers({
  async GET(ctx) {
    const q = cleanQuestion(ctx.url.searchParams.get("q") ?? "");
    const requested = Number(ctx.url.searchParams.get("page") ?? "1");
    try {
      const z = getZetaris(30_000);
      if (!z) throw new Error("no key");
      const rows = await listDocs(z);
      if (!q) {
        return page({
          q,
          rows,
          hits: [] as Hit[],
          total: 0,
          topScore: 0,
          win: null,
          error: "",
        });
      }
      const titles = new Map(rows.map((d) => [d.path, d.title]));
      const ranked = rerank(q, await askDeps().search(q, 100));
      const all: Hit[] = topFiles(ranked, 50).map((h) => ({
        file: h.file,
        corpus: h.corpus,
        title: titles.get(h.file) ?? h.file,
        href: docHref(h.file),
        section: h.passages[0].section,
        similarity: h.passages[0].similarity,
        score: h.score,
        snippetHtml: matchSnippet(q, h.passages[0].text).html,
      }));
      const win = pageWindow(all, requested);
      return page({
        q,
        rows,
        hits: win.items,
        total: all.length,
        topScore: all[0]?.score ?? 0,
        win,
        error: "",
      });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({
        q,
        rows: [] as DocRow[],
        hits: [] as Hit[],
        total: 0,
        topScore: 0,
        win: null,
        error: msg,
      });
    }
  },
});

export default define.page<typeof handler>(function DocsSearch({ data }) {
  const { q, rows, hits, total, topScore, win, error } = data;
  const hrefFor = (n: number) =>
    `/docs/search?q=${encodeURIComponent(q)}&page=${n}`;
  return (
    <DocsShell rows={rows} current="" q={q}>
      <p class="eyebrow">Search</p>
      <h1>{q ? "Results" : "Search the docs"}</h1>
      {q && (
        <p class="lead" data-testid="hit-count">
          {total} pages for "{q}", ranked by meaning with a keyword boost.
        </p>
      )}
      {error && (
        <div class="alert" role="alert" data-testid="error">{error}</div>
      )}
      {!error && q && hits.length === 0 && (
        <p data-testid="no-hits">Nothing matched. Try different words.</p>
      )}
      <div>
        {hits.map((h, i) => (
          <div class="hit" data-testid="hit">
            <ResultHead
              rank={(win?.start ?? 0) + i + 1}
              score={h.score}
              top={topScore}
              similarity={h.similarity}
              href={h.href}
              title={h.title}
              corpus={h.corpus}
              section={h.section}
            />
            <Html html={h.snippetHtml} class="snippet" />
          </div>
        ))}
        {win && win.pages > 1 && (
          <nav class="pager" aria-label="Search results pages">
            {win.current > 1
              ? <a href={hrefFor(win.current - 1)}>Previous</a>
              : <span>Previous</span>}
            <span>{win.start + 1}–{win.end} of {total}</span>
            {win.current < win.pages
              ? <a href={hrefFor(win.current + 1)}>Next</a>
              : <span>Next</span>}
          </nav>
        )}
      </div>
    </DocsShell>
  );
});
