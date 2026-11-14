import { useSignal } from "@preact/signals";
import {
  categoryHref,
  corpusLabel,
  docHref,
  type DocRow,
  filterDocs,
  groupDocs,
  kindBlurb,
  kindLabel,
} from "../core/docs.ts";

/** Category cards, then the pages of the category you open. Filtering stays in the browser. */
export default function DocCatalog(
  { rows, kind = "", corpus = "" }: {
    rows: DocRow[];
    kind?: string;
    corpus?: string;
  },
) {
  const q = useSignal("");
  const opened = Boolean(kind);
  const shown = filterDocs(rows, {
    q: q.value,
    ...(kind ? { kind } : {}),
    ...(corpus ? { corpus } : {}),
  });
  const groups = groupDocs(shown);
  return (
    <div>
      <form role="search" onSubmit={(e) => e.preventDefault()}>
        <label class="filter">
          <span class="sr-only">Filter the docs by title or path</span>
          <input
            type="search"
            value={q.value}
            placeholder={opened
              ? "Filter this category"
              : "Filter by title or path"}
            data-testid="doc-filter"
            onInput={(e) => q.value = (e.target as HTMLInputElement).value}
          />
        </label>
      </form>
      {opened && (
        <p class="crumbs">
          <a href="/docs">All categories</a>
          {corpus && <>/ {corpusLabel(corpus)}</>}
          {" / "}
          {kindLabel(kind)}
        </p>
      )}
      {shown.length === 0
        ? <p data-testid="no-docs">Nothing matches that filter.</p>
        : opened
        ? (
          <div class="doc-list">
            {shown.map((d) => (
              <a class="doc-row" href={docHref(d.path)}>
                <span class="doc-row-title">{d.title}</span>
                <span class="doc-row-path">
                  {d.path.startsWith("http") ? corpusLabel(d.corpus) : d.path}
                </span>
              </a>
            ))}
          </div>
        )
        : (
          <div class="catalog">
            {groups.map((g) => (
              <section>
                <h2>{corpusLabel(g.corpus)}</h2>
                <div class="cat-grid">
                  {g.kinds.map((k) => (
                    <a
                      class="cat-card"
                      href={categoryHref(g.corpus, k.kind)}
                    >
                      <span class="cat-mark" aria-hidden="true">
                        {kindLabel(k.kind).slice(0, 1)}
                      </span>
                      <span class="cat-title">{kindLabel(k.kind)}</span>
                      <span class="cat-blurb">{kindBlurb(k.kind)}</span>
                      <span class="cat-count">
                        {k.docs.length} {k.docs.length === 1 ? "page" : "pages"}
                      </span>
                    </a>
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
    </div>
  );
}
