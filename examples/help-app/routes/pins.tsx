import { page } from "fresh";
import { define } from "../utils.ts";
import { TopBar } from "../components/TopBar.tsx";
import { Html } from "../components/Html.tsx";
import { StaleBadge } from "../components/StaleBadge.tsx";
import LikeButton from "../islands/LikeButton.tsx";
import { docHref } from "../core/docs.ts";
import { toAskError } from "../core/ask.ts";
import { renderMarkdown } from "../core/markdown.ts";
import { listPins, type PinView } from "../core/pins.ts";
import { pinStore } from "../core/server.ts";

export const handler = define.handlers({
  async GET() {
    try {
      const store = pinStore();
      if (!store) throw new Error("no key");
      return page({ pins: await listPins(store), error: "" });
    } catch (e) {
      const msg = e instanceof Error && e.message === "no key"
        ? "Zetaris is not configured: set ZETARIS_API_KEY in .env.local and restart."
        : toAskError(e).message;
      return page({ pins: [] as PinView[], error: msg });
    }
  },
});

export default define.page<typeof handler>(function Pins({ data }) {
  return (
    <>
      <TopBar path="/pins" />
      <main id="main">
        <p class="eyebrow">Pinned</p>
        <h1>Pinned answers</h1>
        <p class="lead">
          Answers people pinned, most liked first. A pin is flagged when a file
          it cites has changed or gone since it was pinned.
        </p>
        {data.error && (
          <div class="alert" role="alert" data-testid="error">{data.error}</div>
        )}
        {!data.error && data.pins.length === 0 && (
          <p data-testid="no-pins">
            Nothing is pinned yet. Ask a question in Answer mode and pin the
            answer.
          </p>
        )}
        {data.pins.length > 0 && (
          <ul class="list">
            {data.pins.map((p) => (
              <li class="item" data-testid="pin-card">
                <h3>{p.question}</h3>
                <div class="meta">
                  <span class="pill good" data-testid="pin-likes">
                    {p.likes} {p.likes === 1 ? "like" : "likes"}
                  </span>
                  <span>used {p.uses}×</span>
                  <span>pinned by {p.pinnedBy}</span>
                  {p.model && <span>{p.model}</span>}
                  <StaleBadge stale={p.stale} />
                </div>
                <details>
                  <summary>Answer</summary>
                  <Html html={renderMarkdown(p.answer)} class="md" />
                </details>
                {p.sources.length > 0 && (
                  <p class="meta">
                    Cites: {p.sources.map((s) => (
                      <a href={docHref(s.file)}>
                        {s.file.replace(/^https?:\/\//, "")}
                      </a>
                    ))}
                  </p>
                )}
                <div class="actions">
                  <LikeButton pinId={p.pinId} likes={p.likes} />
                </div>
              </li>
            ))}
          </ul>
        )}
      </main>
    </>
  );
});
