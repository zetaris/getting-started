import type { ComponentChildren } from "preact";
import { TopBar } from "./TopBar.tsx";
import { docHref, type DocRow, groupDocs } from "../core/docs.ts";

const CORPUS = { repo: "Repo docs", kbase: "Knowledge base" } as Record<
  string,
  string
>;

/** The docs index: groups by corpus and kind, every file a link, the current one marked. */
function SideNav({ rows, current }: { rows: DocRow[]; current: string }) {
  return (
    <>
      {groupDocs(rows).map((g) => (
        <div class="side-group">
          <p class="side-title">{CORPUS[g.corpus] ?? g.corpus}</p>
          {g.kinds.map((k) => (
            <details
              open={k.docs.some((d) => docHref(d.path) === current)}
            >
              <summary>{k.kind} ({k.docs.length})</summary>
              <ul>
                {k.docs.map((d) => (
                  <li>
                    <a
                      href={docHref(d.path)}
                      aria-current={docHref(d.path) === current
                        ? "page"
                        : undefined}
                    >
                      {d.title}
                    </a>
                  </li>
                ))}
              </ul>
            </details>
          ))}
        </div>
      ))}
    </>
  );
}

/** Docs-site layout: index on the left, search at the top, the page on the right. The search
 * is the app's vector search (meaning, with the keyword re-rank), not a text filter. */
export function DocsShell(
  { rows, current, q = "", children }: {
    rows: DocRow[];
    current: string;
    q?: string;
    children: ComponentChildren;
  },
) {
  return (
    <>
      <TopBar path="/docs" />
      <div class="docs">
        <aside class="side" aria-label="Documentation index">
          <SideNav rows={rows} current={current} />
        </aside>
        <main id="main" class="docs-main">
          <div class="docs-inner">
            <div class="docsearch" role="search">
              <form method="get" action="/docs/search">
                <input
                  type="search"
                  name="q"
                  value={q}
                  maxLength={500}
                  placeholder="Search the docs by meaning, e.g. connect a database"
                  aria-label="Search the docs"
                  data-testid="docs-search"
                />
                <button class="btn" type="submit">Search</button>
              </form>
            </div>
            <details class="browse">
              <summary>Browse all docs</summary>
              <SideNav rows={rows} current={current} />
            </details>
            {children}
          </div>
        </main>
      </div>
    </>
  );
}
