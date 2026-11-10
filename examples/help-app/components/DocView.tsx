import type { ChunkRow, DocFile } from "../core/docs.ts";
import { Html } from "./Html.tsx";
import { renderMarkdown } from "../core/markdown.ts";

export function DocView({ doc, chunks }: { doc: DocFile; chunks: ChunkRow[] }) {
  const { row } = doc;
  const isKbase = row.corpus === "kbase";
  return (
    <article>
      <p class="crumbs">
        <a href="/docs">Docs</a> / {isKbase ? "Knowledge base" : "Repo docs"} /
        {" "}
        {row.kind}
      </p>
      <p class="eyebrow">{row.kind}</p>
      {doc.isSql && <h1>{row.title}</h1>}
      <div class="docbar">
        {!isKbase && <code>{row.path}</code>}
        <span class={`pill ${isKbase ? "warn" : ""}`}>
          {isKbase ? "Knowledge base" : "Repo docs"}
        </span>
        {isKbase && (
          <a href={row.path} target="_blank" rel="noopener noreferrer">
            Original page
          </a>
        )}
        <a
          href={`/candidates?file=${encodeURIComponent(row.path)}`}
          data-testid="candidates-link"
        >
          Examples generated from this file
        </a>
      </div>
      <details class="quiet" data-testid="chunks">
        <summary>
          {chunks.length} chunks in the index ({row.chunkCount} in the catalog)
        </summary>
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
      {doc.isSql
        ? <pre class="code" data-testid="doc-body">{doc.body}</pre>
        : <Html html={renderMarkdown(doc.body)} class="md" testid="doc-body" />}
    </article>
  );
}
