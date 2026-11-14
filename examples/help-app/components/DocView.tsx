import { candidatesEnabled } from "../core/config.ts";
import type { ChunkRow, DocFile } from "../core/docs.ts";
import { categoryHref, corpusLabel, kindLabel } from "../core/docs.ts";
import { Html } from "./Html.tsx";
import { renderMarkdown } from "../core/markdown.ts";

export function DocView({ doc, chunks }: { doc: DocFile; chunks: ChunkRow[] }) {
  const { row } = doc;
  const isKbase = row.corpus === "kbase";
  return (
    <article>
      <p class="crumbs">
        <a href="/docs">Docs</a> / {corpusLabel(row.corpus)} /{" "}
        <a href={categoryHref(row.corpus, row.kind)}>
          {kindLabel(row.kind)}
        </a>
      </p>
      {doc.isSql && <h1>{row.title}</h1>}
      <div class="docbar">
        {!isKbase && <code>{row.path}</code>}
        <span class={`pill ${isKbase ? "warn" : ""}`}>
          {corpusLabel(row.corpus)}
        </span>
        {isKbase && (
          <a href={row.path} target="_blank" rel="noopener noreferrer">
            Original page
          </a>
        )}
      </div>
      {doc.isSql
        ? <pre class="code" data-testid="doc-body">{doc.body}</pre>
        : <Html html={renderMarkdown(doc.body)} class="md" testid="doc-body" />}
      <details class="quiet" data-testid="chunks">
        <summary>
          {chunks.length} chunks in the index ({row.chunkCount} in the catalog)
        </summary>
        {candidatesEnabled() && (
          <p>
            <a
              href={`/candidates?file=${encodeURIComponent(row.path)}`}
              data-testid="candidates-link"
            >
              Examples generated from this file
            </a>
          </p>
        )}
        {chunks.length === 0
          ? <p class="fine">No chunk rows found.</p>
          : (
            <table>
              <thead>
                <tr>
                  <th>Part</th>
                  <th>Section</th>
                  <th>Characters</th>
                </tr>
              </thead>
              <tbody>
                {chunks.map((c) => (
                  <tr>
                    <td>{c.part}</td>
                    <td>{c.section}</td>
                    <td>{c.chars}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
      </details>
    </article>
  );
}
