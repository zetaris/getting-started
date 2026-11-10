import type { ChunkRow, DocFile } from "../core/docs.ts";
import { Html } from "./Html.tsx";
import { renderMarkdown } from "../core/markdown.ts";

export function DocView({ doc, chunks }: { doc: DocFile; chunks: ChunkRow[] }) {
  const { row } = doc;
  const isKbase = row.corpus === "kbase";
  return (
    <>
      <p class="crumbs">
        <a href="/docs">Docs</a> / {isKbase ? "Knowledge base" : row.path}
      </p>
      <h1 style="font-size:1.6rem">{row.title}</h1>
      <div class="meta" style="margin-bottom:16px">
        <span class={`pill ${isKbase ? "warn" : ""}`}>
          {isKbase ? "Knowledge base" : "Repo docs"}
        </span>
        <span class="pill">{row.kind}</span>
        {isKbase && (
          <a href={row.path} target="_blank" rel="noopener noreferrer">
            Original page
          </a>
        )}
      </div>
      <p style="margin:-6px 0 14px">
        <a
          href={`/candidates?file=${encodeURIComponent(row.path)}`}
          data-testid="candidates-link"
        >
          Examples generated from this file
        </a>
      </p>
      <details data-testid="chunks" style="margin-bottom:20px">
        <summary>
          {chunks.length} chunks in the index ({row.chunkCount} in the catalog)
        </summary>
        {chunks.length === 0
          ? <p class="lead">No chunk rows found.</p>
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
        ? <pre class="answer" data-testid="doc-body">{doc.body}</pre>
        : <Html html={renderMarkdown(doc.body)} testid="doc-body" />}
    </>
  );
}
