import type { Source } from "../core/ask.ts";

export function SourceCard({ s, rank }: { s: Source; rank: number }) {
  return (
    <article class="card" data-testid="source">
      <h3>
        {s.url
          ? (
            <a href={s.url} target="_blank" rel="noopener noreferrer">
              {s.url.replace(/^https?:\/\//, "")}
            </a>
          )
          : s.file}
      </h3>
      <div class="meta">
        <span class="pill">{rank}</span>
        <span class={`pill ${s.corpus === "kbase" ? "warn" : ""}`}>
          {s.corpus === "kbase" ? "Knowledge base" : "Repo docs"}
        </span>
        {s.section && <span>{s.section}</span>}
        <span title="Cosine similarity of the best passage">
          similarity {s.similarity.toFixed(2)}
        </span>
      </div>
      <details>
        <summary>Best passage</summary>
        <pre>{s.excerpt}</pre>
      </details>
    </article>
  );
}
