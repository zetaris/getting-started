import { page } from "fresh";
import { define } from "../../utils.ts";
import { DocsShell } from "../../components/DocsShell.tsx";
import DocCatalog from "../../islands/DocCatalog.tsx";
import { type DocRow, kindLabel, listDocs } from "../../core/docs.ts";
import { toAskError } from "../../core/ask.ts";
import { getZetaris } from "../../core/server.ts";

export const handler = define.handlers({
  async GET(ctx) {
    const kind = ctx.url.searchParams.get("kind") ?? "";
    const corpus = ctx.url.searchParams.get("corpus") ?? "";
    try {
      const z = getZetaris(30_000);
      if (!z) throw new Error("no key");
      return page({ rows: await listDocs(z), kind, corpus, error: "" });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({ rows: [] as DocRow[], kind, corpus, error: msg });
    }
  },
});

export default define.page<typeof handler>(function Docs({ data }) {
  const { rows, kind, corpus, error } = data;
  return (
    <DocsShell
      rows={rows}
      current=""
      landing
      focusKind={kind}
      focusCorpus={corpus}
    >
      <p class="eyebrow">Documentation</p>
      <h1>{kind ? kindLabel(kind) : "Docs"}</h1>
      <p class="lead">
        {kind
          ? "Pages in this category. Search above to look across everything."
          : "Pick a category, or search above by meaning."}
      </p>
      {error && (
        <div class="alert" role="alert" data-testid="error">{error}</div>
      )}
      {!error && (
        <>
          <p class="fine" data-testid="doc-count">{rows.length} files</p>
          <DocCatalog rows={rows} kind={kind} corpus={corpus} />
        </>
      )}
    </DocsShell>
  );
});
