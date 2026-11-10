import { useSignal } from "@preact/signals";
import type { ExampleResult } from "../core/example.ts";
import { getName } from "../islands/prefs.ts";

interface Props {
  result: ExampleResult;
  request: string;
  onRegenerate: () => void;
}

type Save =
  | { kind: "none" }
  | { kind: "saving" }
  | { kind: "saved"; existing: boolean }
  | { kind: "error"; message: string };

/** A generated example. One badge only: "Generated, dry-run passed" or "Generated, unverified".
 * Never "Verified". Unverified SQL is collapsed behind a warning. */
export function ExampleView({ result, request, onRegenerate }: Props) {
  const save = useSignal<Save>({ kind: "none" });
  const copied = useSignal(false);
  const passed = result.status === "dry-run passed";

  async function copy() {
    try {
      await navigator.clipboard.writeText(result.sql);
      copied.value = true;
    } catch { /* clipboard blocked */ }
  }

  async function saveCandidate() {
    save.value = { kind: "saving" };
    try {
      const res = await fetch("/api/candidates", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          request,
          sql: result.sql,
          attempts: result.attempts.length,
          model: result.model,
          sources: result.sources.map((s) => s.file),
          notes: result.notes,
          who: getName(),
        }),
      });
      const body = await res.json().catch(() => null);
      if (!res.ok || body?.error) {
        throw new Error(body?.error?.message ?? `HTTP ${res.status}`);
      }
      save.value = { kind: "saved", existing: Boolean(body.existing) };
    } catch (e) {
      save.value = { kind: "error", message: (e as Error).message };
    }
  }

  const code = (
    <pre class="code" data-testid="example-sql"><code>{result.sql}</code></pre>
  );
  return (
    <div data-testid="example">
      <h2>Inspired by</h2>
      <div class="strip" data-testid="example-sources">
        {result.sources.map((s) => (
          <article class="card" data-testid="example-source">
            <h3>
              {s.docHref ? <a href={s.docHref}>{s.file}</a> : s.file}
            </h3>
          </article>
        ))}
      </div>
      <h2>Generated example</h2>
      <div class="meta">
        <span
          class={`pill ${passed ? "good" : "warn"}`}
          data-testid="example-status"
        >
          {passed ? "Generated, dry-run passed" : "Generated, unverified"}
        </span>
        <span>
          {result.attempts.length}{" "}
          {result.attempts.length === 1 ? "attempt" : "attempts"}
        </span>
        <span>{result.model}</span>
        <span>{(result.ms / 1000).toFixed(0)} s</span>
      </div>
      {result.notes && <p class="lead" style="margin:8px 0">{result.notes}</p>}
      {passed ? code : (
        <details data-testid="example-unverified">
          <summary>
            Unverified: {result.reason ?? "it was not checked"}{" "}
            Show the SQL anyway
          </summary>
          <p class="alert" role="note">
            Do not run this without reading it. It was not accepted by the
            checker.
          </p>
          {code}
        </details>
      )}
      <div class="actions">
        <button
          type="button"
          class="btn ghost"
          data-testid="copy"
          onClick={copy}
        >
          {copied.value ? "Copied" : "Copy"}
        </button>
        <button
          type="button"
          class="btn ghost"
          data-testid="save-candidate"
          disabled={save.value.kind === "saving" || save.value.kind === "saved"}
          onClick={saveCandidate}
        >
          {save.value.kind === "saved" ? "Saved" : "Save as candidate"}
        </button>
        <button
          type="button"
          class="btn ghost"
          data-testid="regenerate"
          onClick={onRegenerate}
        >
          Regenerate
        </button>
      </div>
      {save.value.kind === "saved" && (
        <p class="lead" role="status" data-testid="saved">
          {save.value.existing ? "Already saved." : "Saved."}{" "}
          <a href="/candidates">See Candidates</a>
        </p>
      )}
      {save.value.kind === "error" && (
        <div class="alert" role="alert" data-testid="save-error">
          {save.value.message}
        </div>
      )}
      <details data-testid="attempts">
        <summary>Attempts ({result.attempts.length})</summary>
        <ol>
          {result.attempts.map((a) => (
            <li>
              {a.error === null
                ? "Passed the dry-run."
                : `Rejected: ${a.error}`}
              {a.sql && <pre class="code"><code>{a.sql}</code></pre>}
            </li>
          ))}
        </ol>
      </details>
      <p class="lead" style="margin-top:10px;font-size:0.9rem">
        Written by a language model from the files above. "Dry-run passed" means
        Zetaris's analyzer accepted the query (EXPLAIN); nothing was run against
        data, and it is not "verified" in the sense of CONTRIBUTING.md. Only
        queries can be checked; other statements stay unverified.
      </p>
    </div>
  );
}
