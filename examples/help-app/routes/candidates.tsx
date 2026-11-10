import { page } from "fresh";
import { define } from "../utils.ts";
import { TopBar } from "../components/TopBar.tsx";
import { toAskError } from "../core/ask.ts";
import { type CandidateView, listCandidates } from "../core/candidates.ts";
import { docHref, validRepoPath } from "../core/docs.ts";
import { getZetaris } from "../core/server.ts";

export const handler = define.handlers({
  async GET(ctx) {
    const raw = ctx.url.searchParams.get("file") ?? "";
    const file = raw && (validRepoPath(raw) || /^https?:\/\//.test(raw))
      ? raw
      : "";
    try {
      const z = getZetaris();
      if (!z) throw new Error("no key");
      return page({
        items: await listCandidates(z, file || undefined),
        file,
        error: "",
      });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({ items: [] as CandidateView[], file, error: msg });
    }
  },
});

export default define.page<typeof handler>(function Candidates({ data }) {
  return (
    <>
      <TopBar path="/candidates" />
      <main id="main">
        <p class="eyebrow">Candidates</p>
        <h1>Saved examples</h1>
        <p class="lead">
          SQL examples the Example mode generated and someone saved for review.
          Nothing here is added to the repo or run against data.
        </p>
        {data.file && (
          <p class="fine" data-testid="file-filter">
            Only examples that cite <code>{data.file}</code>.{" "}
            <a href="/candidates">Show all</a>
          </p>
        )}
        {data.error && (
          <div class="alert" role="alert" data-testid="error">{data.error}</div>
        )}
        {!data.error && data.items.length === 0 && (
          <p data-testid="no-candidates">
            Nothing saved yet. In Search, choose Example, generate one and press
            "Save as candidate".
          </p>
        )}
        {data.items.length > 0 && (
          <ul class="list">
            {data.items.map((c) => (
              <li class="item" data-testid="candidate">
                <h3>{c.request}</h3>
                <div class="meta">
                  <span
                    class={`pill ${
                      c.status === "dry-run passed" ? "good" : "warn"
                    }`}
                    data-testid="candidate-status"
                  >
                    {c.status === "dry-run passed"
                      ? "Generated, dry-run passed"
                      : "Generated, unverified"}
                  </span>
                  <span>
                    {c.attempts} {c.attempts === 1 ? "attempt" : "attempts"}
                  </span>
                  <span>{c.model}</span>
                  <span>saved by {c.createdBy}</span>
                  <span>{c.createdAt}</span>
                </div>
                <details>
                  <summary>Show SQL</summary>
                  <pre class="code"><code>{c.sql}</code></pre>
                </details>
                {c.sources.length > 0 && (
                  <p class="meta">
                    Inspired by:{" "}
                    {c.sources.map((f) => (
                      <a href={docHref(f)}>{f.replace(/^https?:\/\//, "")}</a>
                    ))}
                  </p>
                )}
              </li>
            ))}
          </ul>
        )}
      </main>
    </>
  );
});
