import { useSignal } from "@preact/signals";
import type { ExampleResult } from "../core/example.ts";
import { SourceCard } from "./SourceCard.tsx";

interface Props {
  result: ExampleResult;
  request: string;
  onRegenerate: () => void;
  /** Save-for-review shelf. The page passes this from HELP_CANDIDATES. */
  candidatesEnabled?: boolean;
}

type Save =
  | { kind: "none" }
  | { kind: "saving" }
  | { kind: "saved"; existing: boolean }
  | { kind: "error"; message: string };

/** A generated example. One badge only: "Generated, dry-run passed" or "Generated, unverified".
 * Never "Verified". A query Zetaris rejected stays collapsed until opened. */
export function ExampleView(
  { result, request, onRegenerate, candidatesEnabled = false }: Props,
) {
  const save = useSignal<Save>({ kind: "none" });
  const copied = useSignal(false);
  const face = useSignal<"example" | "sources">("example");
  const passed = result.status === "dry-run passed";
  // Not checkable (a command, not a query) is different from rejected by the checker.
  const unchecked = !passed && result.attempts.at(-1)?.unchecked === true;
  const tip = passed
    ? "Zetaris accepted this query with EXPLAIN. Nothing was run against data."
    : unchecked
    ? `Nothing checked this. ${result.reason} Read it before you run it, and replace any placeholders.`
    : `Zetaris rejected every attempt. ${
      result.reason ?? ""
    } Do not run this without reading it.`;

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
  const exampleFace = (
    <>
      <div class="example-meta">
        <span class="tiptip">
          <span
            class={`pill ${passed ? "good" : "warn"}${
              passed ? "" : " with-info"
            }`}
            data-testid="example-status"
            tabIndex={0}
            aria-describedby="example-status-tip"
          >
            {passed ? "Generated, dry-run passed" : "Generated, unverified"}
            {!passed && (
              <svg class="info-i" viewBox="0 0 16 16" aria-hidden="true">
                <circle
                  cx="8"
                  cy="8"
                  r="6.25"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.4"
                />
                <circle cx="8" cy="5.1" r="0.85" fill="currentColor" />
                <path
                  d="M8 7.3v4"
                  stroke="currentColor"
                  stroke-width="1.4"
                  stroke-linecap="round"
                />
              </svg>
            )}
          </span>
          <span
            class="tiptip-box"
            id="example-status-tip"
            role="tooltip"
            data-testid={unchecked ? "example-unchecked" : undefined}
          >
            {tip}
          </span>
        </span>
        <span class="fine">{result.model}</span>
      </div>
      {result.notes && <p class="note-text">{result.notes}</p>}
      {passed || unchecked
        ? code
        : (
          <details class="callout bad" data-testid="example-unverified">
            <summary>
              Zetaris rejected every attempt.{" "}
              <span class="linkish">Show the SQL anyway</span>
            </summary>
            {code}
          </details>
        )}
      <div class="actions">
        {candidatesEnabled && (
          <button
            type="button"
            class="btn"
            data-testid="save-candidate"
            disabled={save.value.kind === "saving" ||
              save.value.kind === "saved"}
            onClick={saveCandidate}
          >
            {save.value.kind === "saved" ? "Saved" : "Save as candidate"}
          </button>
        )}
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
    </>
  );
  return (
    <div class="example flipcard" data-testid="example">
      <div class="flipbar" role="tablist" aria-label="Example or sources">
        <button
          type="button"
          role="tab"
          aria-selected={face.value === "example"}
          class={face.value === "example" ? "on" : ""}
          onClick={() => face.value = "example"}
        >
          Example
        </button>
        <button
          type="button"
          role="tab"
          data-testid="example-sources-tab"
          aria-selected={face.value === "sources"}
          class={face.value === "sources" ? "on" : ""}
          onClick={() => face.value = "sources"}
        >
          Inspired by ({result.sources.length})
        </button>
      </div>
      <div class="example-stage">
        <div
          class={`flipbody example-face${
            face.value === "sources" ? " away" : ""
          }`}
          aria-hidden={face.value === "sources"}
        >
          {exampleFace}
        </div>
        <div class="flipbody sources-face" hidden={face.value !== "sources"}>
          <ul class="list" data-testid="example-sources">
            {result.sources.map((s, i) => (
              <SourceCard
                s={s}
                rank={i + 1}
                top={Math.max(...result.sources.map((x) => x.score), 0)}
                testid="example-source"
              />
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
