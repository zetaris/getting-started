import { page } from "fresh";
import { define } from "../../utils.ts";
import { DocsShell } from "../../components/DocsShell.tsx";
import { type DocRow, groupDocs, listDocs } from "../../core/docs.ts";
import { toAskError } from "../../core/ask.ts";
import { getZetaris } from "../../core/server.ts";

export const handler = define.handlers({
  async GET() {
    try {
      const z = getZetaris(30_000);
      if (!z) throw new Error("no key");
      return page({ rows: await listDocs(z), error: "" });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({ rows: [] as DocRow[], error: msg });
    }
  },
});

const CORPUS = { repo: "Repo docs", kbase: "Knowledge base" } as Record<
  string,
  string
>;

export default define.page<typeof handler>(function Docs({ data }) {
  const { rows, error } = data;
  return (
    <DocsShell rows={rows} current="">
      <p class="eyebrow">Documentation</p>
      <h1>Docs</h1>
      <p class="lead">
        Everything in the index: this repository's Markdown and SQL scripts, and
        a snapshot of the Zetaris Knowledge base. Search above by meaning, or
        pick a page from the index.
      </p>
      {error && (
        <div class="alert" role="alert" data-testid="error">{error}</div>
      )}
      {!error && (
        <>
          <p class="fine" data-testid="doc-count">{rows.length} files</p>
          <div class="kv">
            {groupDocs(rows).flatMap((g) =>
              g.kinds.map((k) => (
                <div>
                  <b>{k.docs.length}</b>
                  <span>
                    {CORPUS[g.corpus] ?? g.corpus} · {k.kind}
                  </span>
                </div>
              ))
            )}
          </div>
        </>
      )}
    </DocsShell>
  );
});
