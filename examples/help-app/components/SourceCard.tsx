import type { ComponentChildren } from "preact";
import { Html } from "./Html.tsx";
import type { Source } from "../core/ask.ts";

/** Position, and a bar of this file's score against the top file. Cosine stays in the tooltip. */
export function RankMark(
  { rank, score, top, similarity }: {
    rank: number;
    score: number;
    top: number;
    similarity: number;
  },
) {
  const width = top > 0 ? Math.round((score / top) * 100) : 0;
  const sim = `similarity ${similarity.toFixed(2)}`;
  return (
    <span class="rankline">
      <span class={`rank${rank <= 3 ? " top" : ""}`}>{rank}</span>
      <span
        class="meter"
        role="img"
        title={sim}
        aria-label={`Rank ${rank}, ${sim}`}
      >
        <span style={{ width: `${width}%` }} />
      </span>
    </span>
  );
}

/** Title row shared by Docs search and the Search page. The source pill sits on the right. */
export function ResultHead(
  { rank, score, top, similarity, href, title, corpus, section, extra }: {
    rank: number;
    score: number;
    top: number;
    similarity: number;
    href: string;
    title: string;
    corpus: string;
    section?: string;
    extra?: ComponentChildren;
  },
) {
  return (
    <div class="result-head">
      <div class="result-main">
        <h3>
          <RankMark
            rank={rank}
            score={score}
            top={top}
            similarity={similarity}
          />
          <a href={href}>{title}</a>
        </h3>
        {(section || extra) && (
          <div class="result-section">
            {section && <span>{section}</span>}
            {extra}
          </div>
        )}
      </div>
      <span class={`pill ${corpus === "kbase" ? "warn" : ""}`}>
        {corpus === "kbase" ? "Knowledge base" : "Repo docs"}
      </span>
    </div>
  );
}

export function SourceCard(
  { s, rank, top, testid = "source" }: {
    s: Source;
    rank: number;
    top: number;
    testid?: string;
  },
) {
  return (
    <li class="item" data-testid={testid}>
      <ResultHead
        rank={rank}
        score={s.score}
        top={top}
        similarity={s.similarity}
        href={s.docHref}
        title={s.url ? s.url.replace(/^https?:\/\//, "") : s.file}
        corpus={s.corpus}
        section={s.section}
        extra={s.url && (
          <a href={s.url} target="_blank" rel="noopener noreferrer">
            Original page
          </a>
        )}
      />
      {s.snippetHtml && (
        <Html html={s.snippetHtml} class="snippet" testid="snippet" />
      )}
      <details>
        <summary>Best passage</summary>
        <Html html={s.excerptHtml} class="md excerpt" />
      </details>
    </li>
  );
}
