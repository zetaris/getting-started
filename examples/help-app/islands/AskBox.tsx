import { useSignal } from "@preact/signals";
import { useEffect, useRef } from "preact/hooks";
import type { AskResult, Mode } from "../core/ask.ts";
import { SourceCard } from "../components/SourceCard.tsx";

const MODE_KEY = "help_mode";
const CLIENT_TIMEOUT_MS = 130_000;

interface Props {
  llmConfigured: boolean;
  examples: string[];
}

type State =
  | { kind: "idle" }
  | { kind: "loading"; mode: Mode }
  | { kind: "done"; result: AskResult; seconds: number }
  | { kind: "error"; code: string; message: string };

export default function AskBox({ llmConfigured, examples }: Props) {
  const question = useSignal("");
  const mode = useSignal<Mode>("search");
  const state = useSignal<State>({ kind: "idle" });
  const copied = useSignal(false);
  const abort = useRef<AbortController | null>(null);

  useEffect(() => {
    try {
      if (llmConfigured && localStorage.getItem(MODE_KEY) === "answer") {
        mode.value = "answer";
      }
    } catch { /* storage blocked */ }
  }, []);

  function pick(m: Mode) {
    mode.value = m;
    try {
      localStorage.setItem(MODE_KEY, m);
    } catch { /* ignore */ }
  }

  async function submit(q = question.value) {
    const text = q.trim();
    if (!text) {
      state.value = {
        kind: "error",
        code: "empty_question",
        message: "Type a question first.",
      };
      return;
    }
    abort.current?.abort();
    const ctl = new AbortController();
    abort.current = ctl;
    const timer = setTimeout(() => ctl.abort(), CLIENT_TIMEOUT_MS);
    const started = performance.now();
    copied.value = false;
    state.value = { kind: "loading", mode: mode.value };
    try {
      const res = await fetch("/api/ask", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ question: text, mode: mode.value }),
        signal: ctl.signal,
      });
      const body = await res.json().catch(() => null);
      if (!res.ok || !body || body.error) {
        state.value = {
          kind: "error",
          code: body?.error?.code ?? "http",
          message: body?.error?.message ??
            `The server answered with an error (HTTP ${res.status}).`,
        };
        return;
      }
      state.value = {
        kind: "done",
        result: body as AskResult,
        seconds: (performance.now() - started) / 1000,
      };
    } catch (e) {
      if (ctl !== abort.current) return; // superseded by a newer question
      state.value = {
        kind: "error",
        code: "network",
        message: (e as Error).name === "AbortError"
          ? "That took too long. Try again, or use Search only."
          : "Could not reach the help app server. Is it still running?",
      };
    } finally {
      clearTimeout(timer);
    }
  }

  async function copy(text: string) {
    try {
      await navigator.clipboard.writeText(text);
      copied.value = true;
    } catch { /* clipboard blocked */ }
  }

  const s = state.value;
  const busy = s.kind === "loading";
  return (
    <div>
      <form
        class="ask"
        onSubmit={(e) => {
          e.preventDefault();
          submit();
        }}
      >
        <label for="q" class="lead" style="margin:0">Your question</label>
        <textarea
          id="q"
          name="question"
          data-testid="question"
          maxLength={500}
          rows={3}
          placeholder="For example: How do I onboard a REST API source?"
          value={question.value}
          onInput={(
            e,
          ) => (question.value = (e.target as HTMLTextAreaElement).value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
              e.preventDefault();
              submit();
            }
          }}
        />
        <div class="row">
          <fieldset class="modes" aria-label="Mode">
            <label>
              <input
                type="radio"
                name="mode"
                value="search"
                checked={mode.value === "search"}
                onChange={() => pick("search")}
              />
              Search only
            </label>
            <label
              title={llmConfigured
                ? ""
                : "Needs OLLAMA_URL and OLLAMA_MODEL in .env.local"}
            >
              <input
                type="radio"
                name="mode"
                value="answer"
                disabled={!llmConfigured}
                checked={mode.value === "answer"}
                onChange={() => pick("answer")}
              />
              Answer
            </label>
          </fieldset>
          <button
            type="submit"
            class="btn"
            data-testid="submit"
            disabled={busy}
          >
            {busy ? "Working…" : "Ask"}
          </button>
        </div>
        {!llmConfigured && (
          <div class="lead" style="margin:0;font-size:0.9rem">
            Answer mode is off: no LLM is configured. Search only works without
            one.
          </div>
        )}
        <div class="chips" aria-label="Example questions">
          {examples.map((ex) => (
            <button
              type="button"
              class="chip"
              disabled={busy}
              onClick={() => {
                question.value = ex;
                submit(ex);
              }}
            >
              {ex}
            </button>
          ))}
        </div>
      </form>

      <div class="status" role="status" aria-live="polite" data-testid="status">
        {s.kind === "loading" &&
          (s.mode === "answer"
            ? "Searching, then writing an answer. This can take up to a minute."
            : "Searching…")}
        {s.kind === "done" &&
          `Done in ${
            s.seconds.toFixed(1)
          } s. ${s.result.sources.length} sources${
            s.result.answer !== null ? " and an answer" : ""
          }.`}
      </div>

      {s.kind === "error" && (
        <div class="alert" role="alert" data-testid="error" data-code={s.code}>
          {s.message}
        </div>
      )}

      {s.kind === "done" && (
        <section aria-label="Results">
          <h2>Sources</h2>
          <p class="lead" style="margin:-4px 0 12px;font-size:0.9rem">
            Ordered by similarity plus a small bonus for matching words, so the
            numbers are not always in descending order.
          </p>
          {s.result.sources.length === 0
            ? (
              <p data-testid="no-sources">
                Nothing matched. Try different words.
              </p>
            )
            : s.result.sources.map((src, i) => (
              <SourceCard s={src} rank={i + 1} />
            ))}
          {s.result.answer !== null && (
            <>
              <h2>Answer</h2>
              <pre class="answer" data-testid="answer">{s.result.answer}</pre>
              <div class="actions">
                <button
                  type="button"
                  class="btn ghost"
                  onClick={() => copy(s.result.answer ?? "")}
                >
                  {copied.value ? "Copied" : "Copy"}
                </button>
              </div>
              <p class="lead" style="margin-top:10px;font-size:0.9rem">
                Written by a language model from the sources above. Check the
                cited files, and treat generated SQL as unverified.
              </p>
            </>
          )}
        </section>
      )}
    </div>
  );
}
