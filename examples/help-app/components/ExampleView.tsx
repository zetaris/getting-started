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
  // Not checkable (a command, not a query) is different from rejected by the checker.
  const unchecked = !passed && result.attempts.at(-1)?.unchecked === true;

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
    <div class="codebox">
      <div class="codebar">
        <span>SQL</span>
        <button type="button" data-testid="copy" onClick={copy}>
          {copied.value ? "Copied" : "Copy"}
        </button>
      </div>
      <pre
        class="code"
        data-testid="example-sql"
      ><code>{result.sql}</code></pre>
    </div>
  );
  const nAttempts = result.attempts.length;
  return (
    <div class="example" data-testid="example">
      <div class="example-head">
        <h2>Generated example</h2>
        <span
          class={`pill ${passed ? "good" : "warn"}`}
          data-testid="example-status"
        >
          {passed ? "Generated, dry-run passed" : "Generated, unverified"}
        </span>
      </div>
      <p class="fine">
        {nAttempts} {nAttempts === 1 ? "attempt" : "attempts"} · {result.model}
        {" "}
        · {(result.ms / 1000).toFixed(0)} s
      </p>
      {result.notes && <p class="note-text">{result.notes}</p>}
      {passed ? code : unchecked
        ? (
          <>
            <div class="callout" role="note" data-testid="example-unchecked">
              <strong>Nothing checked this.</strong> {result.reason}{" "}
              Read it before you run it, and replace any placeholders.
            </div>
            {code}
          </>
        )
        : (
          <details class="callout bad" data-testid="example-unverified">
            <summary>
              The checker rejected every attempt: {result.reason}{" "}
              <span class="linkish">Show the SQL anyway</span>
            </summary>
            <p>Do not run this without reading it.</p>
            {code}
          </details>
        )}
      <div class="actions">
        <button
          type="button"
          class="btn"
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
        <p class="fine" role="status" data-testid="saved">
          {save.value.existing ? "Already saved." : "Saved."}{" "}
          <a href="/candidates">See Candidates</a>
        </p>
      )}
      {save.value.kind === "error" && (
        <div class="alert" role="alert" data-testid="save-error">
          {save.value.message}
        </div>
      )}
      <h3 class="sub">Inspired by</h3>
      <ul class="srclist" data-testid="example-sources">
        {result.sources.map((s) => (
          <li data-testid="example-source">
            {s.docHref ? <a href={s.docHref}>{s.file}</a> : s.file}
          </li>
        ))}
      </ul>
      <details data-testid="attempts" class="quiet">
        <summary>Attempts ({nAttempts})</summary>
        <ol>
          {result.attempts.map((a) => (
            <li>
              {a.error === null
                ? "Passed the dry-run."
                : a.unchecked
                ? `Not dry-run: ${a.error}`
                : `Rejected: ${a.error}`}
              {a.sql && <pre class="code"><code>{a.sql}</code></pre>}
            </li>
          ))}
        </ol>
      </details>
      <details class="quiet">
        <summary>How to read this label</summary>
        <p class="fine">
          Written by a language model from the files above. "Dry-run passed"
          means Zetaris's analyzer accepted the query (EXPLAIN); nothing was run
          against data, and it is not "verified" in the sense of
          CONTRIBUTING.md. Only queries can be checked; other statements stay
          unverified.
        </p>
      </details>
    </div>
  );
}
