import type { ComponentChildren } from "preact";
import { TopBar } from "./TopBar.tsx";
import ScrollCurrent from "../islands/ScrollCurrent.tsx";
import {
  corpusLabel,
  docHref,
  type DocRow,
  groupDocs,
  kindLabel,
  kindStartsOpen,
} from "../core/docs.ts";

/** The docs index: groups by corpus and kind, every file a link, the current one marked. */
function SideNav(
  { rows, current, focusKind, focusCorpus }: {
    rows: DocRow[];
    current: string;
    focusKind: string;
    focusCorpus: string;
  },
) {
  return (
    <>
      {groupDocs(rows).map((g) => (
        <div class="side-group">
          <p class="side-title">{corpusLabel(g.corpus)}</p>
          {g.kinds.map((k) => (
            <details
              open={kindStartsOpen(k.kind, {
                containsCurrent: k.docs.some((d) =>
                  docHref(d.path) === current
                ),
                focusKind,
                focusCorpus,
                corpus: g.corpus,
              })}
            >
              <summary>
                {kindLabel(k.kind)} ({k.docs.length})
              </summary>
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
  {
    rows,
    current,
    q = "",
    landing = false,
    focusKind = "",
    focusCorpus = "",
    children,
  }: {
    rows: DocRow[];
    current: string;
    q?: string;
    /** Wider main column for the category cards. */
    landing?: boolean;
    /** Category opened from a card or breadcrumb. */
    focusKind?: string;
    focusCorpus?: string;
    children: ComponentChildren;
  },
) {
  const nav = (key: string) => (
    <SideNav
      key={key}
      rows={rows}
      current={current}
      focusKind={focusKind}
      focusCorpus={focusCorpus}
    />
  );
  return (
    <>
      <TopBar path="/docs" />
      {current && <ScrollCurrent />}
      <div class="docs">
        <aside class="side" aria-label="Documentation index">
          {nav("side")}
        </aside>
        <main id="main" class="docs-main">
          <div class={`docs-inner${landing ? " wide" : ""}`}>
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
              {nav("browse")}
            </details>
            {children}
          </div>
        </main>
      </div>
    </>
  );
}
