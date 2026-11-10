import { page } from "fresh";
import { define } from "../../utils.ts";
import { TopBar } from "../../components/TopBar.tsx";
import {
  docHref,
  type DocRow,
  filterDocs,
  groupDocs,
  listDocs,
} from "../../core/docs.ts";
import { toAskError } from "../../core/ask.ts";
import { getZetaris } from "../../core/server.ts";

export const handler = define.handlers({
  async GET(ctx) {
    const u = new URL(ctx.req.url);
    const filter = {
      q: u.searchParams.get("q") ?? "",
      corpus: u.searchParams.get("corpus") ?? "",
      kind: u.searchParams.get("kind") ?? "",
    };
    try {
      const z = getZetaris(30_000);
      if (!z) throw new Error("no key");
      const all = await listDocs(z);
      return page({
        filter,
        all: all.length,
        rows: filterDocs(all, filter),
        kinds: [...new Set(all.map((d) => d.kind))].sort(),
        error: "",
      });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({
        filter,
        all: 0,
        rows: [] as DocRow[],
        kinds: [] as string[],
        error: msg,
      });
    }
  },
});

export default define.page<typeof handler>(function Docs({ data }) {
  const { filter, rows, kinds, all, error } = data;
  return (
    <>
      <TopBar path="/docs" />
      <main id="main">
        <h1>Docs</h1>
        <p class="lead">
          Every file in the index, from the <code>help_usl.docs</code>{" "}
          catalog: this repository's Markdown and SQL scripts, and the Zetaris
          Knowledge base snapshot.
        </p>
        <form class="filters" method="get" action="/docs" role="search">
          <input
            type="search"
            name="q"
            value={filter.q}
            placeholder="Filter by title or path"
            aria-label="Filter by title or path"
          />
          <select name="corpus" aria-label="Corpus">
            <option value="">All corpora</option>
            <option value="repo" selected={filter.corpus === "repo"}>
              Repo docs
            </option>
            <option value="kbase" selected={filter.corpus === "kbase"}>
              Knowledge base
            </option>
          </select>
          <select name="kind" aria-label="Kind">
            <option value="">All kinds</option>
            {kinds.map((k) => (
              <option value={k} selected={filter.kind === k}>{k}</option>
            ))}
          </select>
          <button class="btn" type="submit">Filter</button>
        </form>
        {error && (
          <div class="alert" role="alert" data-testid="error">{error}</div>
        )}
        {!error && (
          <p class="lead" data-testid="doc-count">
            {rows.length === all
              ? `${all} files`
              : `${rows.length} of ${all} files`}
          </p>
        )}
        {groupDocs(rows).map((g) => (
          <section>
            <h2>{g.corpus === "kbase" ? "Knowledge base" : "Repo docs"}</h2>
            {g.kinds.map((k) => (
              <details
                open={Boolean(filter.q || filter.kind) || g.kinds.length === 1}
              >
                <summary>{k.kind} ({k.docs.length})</summary>
                <ul class="doclist">
                  {k.docs.map((d) => (
                    <li data-testid="doc-item">
                      <a href={docHref(d.path)}>{d.title}</a>
                      <span class="path">
                        {g.corpus === "kbase"
                          ? `${d.chunkCount} chunks`
                          : `${d.path} · ${d.chunkCount} chunks`}
                      </span>
                    </li>
                  ))}
                </ul>
              </details>
            ))}
          </section>
        ))}
      </main>
    </>
  );
});
