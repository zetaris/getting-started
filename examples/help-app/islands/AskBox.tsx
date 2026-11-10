import { useSignal } from "@preact/signals";
import { useEffect, useRef } from "preact/hooks";
import type { AskResult, Mode, PastAnswerOut } from "../core/ask.ts";
import { SourceCard } from "../components/SourceCard.tsx";
import { StaleBadge } from "../components/StaleBadge.tsx";
import { Html } from "../components/Html.tsx";
import LikeButton from "./LikeButton.tsx";
import NameField from "./NameField.tsx";
import { getName, postEvent } from "./prefs.ts";

const MODE_KEY = "help_mode";
const CLIENT_TIMEOUT_MS = 130_000;

interface Props {
  llmConfigured: boolean;
  model: string;
  examples: string[];
}

type State =
  | { kind: "idle" }
  | { kind: "loading"; mode: Mode }
  | { kind: "done"; result: AskResult; question: string; seconds: number }
  | { kind: "error"; code: string; message: string };

type PinState =
  | { kind: "none" }
  | { kind: "pinning" }
  | { kind: "pinned"; existing: boolean }
  | { kind: "error"; message: string };

export default function AskBox({ llmConfigured, model, examples }: Props) {
  const question = useSignal("");
  const mode = useSignal<Mode>("search");
  const state = useSignal<State>({ kind: "idle" });
  const copied = useSignal(false);
  const pin = useSignal<PinState>({ kind: "none" });
  const used = useSignal<PastAnswerOut | null>(null);
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
    pin.value = { kind: "none" };
    used.value = null;
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
        question: text,
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

  async function pinAnswer(s: Extract<State, { kind: "done" }>) {
    pin.value = { kind: "pinning" };
    try {
      const res = await fetch("/api/pins", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          question: s.question,
          answer: s.result.answer,
          model,
          sources: s.result.sources.map((x) => ({ file: x.file })),
          who: getName(),
        }),
      });
      const body = await res.json().catch(() => null);
      if (!res.ok || body?.error) {
        throw new Error(body?.error?.message ?? `HTTP ${res.status}`);
      }
      pin.value = { kind: "pinned", existing: Boolean(body.existing) };
    } catch (e) {
      pin.value = { kind: "error", message: (e as Error).message };
    }
  }

  function useAnswer(p: PastAnswerOut) {
    used.value = p;
    postEvent(p.pinId, "use").catch(() => {}); // a missed count is not worth an error
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
        <NameField />
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
          {s.result.pastAnswers.length > 0 && (
            <section aria-label="Past answers" data-testid="past">
              <h2>Past answers</h2>
              <p class="lead" style="margin:-4px 0 12px;font-size:0.9rem">
                Someone asked something similar and pinned an answer. Using it
                needs no model call.
              </p>
              {s.result.pastAnswers.map((p) => (
                <article class="card past" data-testid="past-answer">
                  <h3>
                    <span
                      class="lead"
                      style="font-size:0.85rem;font-weight:400"
                    >
                      Pinned for:
                    </span>{" "}
                    {p.question}
                  </h3>
                  <div class="meta">
                    <span
                      class="pill"
                      title="Cosine similarity to your question"
                    >
                      similarity {p.similarity.toFixed(2)}
                    </span>
                    <span>pinned by {p.pinnedBy}</span>
                    {p.model && <span>{p.model}</span>}
                    <StaleBadge stale={p.stale} />
                  </div>
                  <div class="actions">
                    <button
                      type="button"
                      class="btn ghost"
                      data-testid="use"
                      onClick={() =>
                        useAnswer(p)}
                    >
                      Use this answer
                    </button>
                    <LikeButton pinId={p.pinId} likes={p.likes} />
                  </div>
                </article>
              ))}
              {used.value && (
                <div data-testid="used-answer">
                  <h2>Pinned answer</h2>
                  <Html html={used.value.answerHtml} class="md answer-md" />
                </div>
              )}
            </section>
          )}
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
              <Html
                html={s.result.answerHtml ?? ""}
                class="md answer-md"
                testid="answer"
              />
              <div class="actions">
                <button
                  type="button"
                  class="btn ghost"
                  onClick={() => copy(s.result.answer ?? "")}
                >
                  {copied.value ? "Copied" : "Copy"}
                </button>
                <button
                  type="button"
                  class="btn ghost"
                  data-testid="pin"
                  disabled={pin.value.kind === "pinning" ||
                    pin.value.kind === "pinned"}
                  onClick={() => pinAnswer(s)}
                >
                  {pin.value.kind === "pinning"
                    ? "Pinning…"
                    : pin.value.kind === "pinned"
                    ? "Pinned"
                    : "Pin this answer"}
                </button>
              </div>
              {pin.value.kind === "pinned" && (
                <p class="lead" role="status" data-testid="pinned">
                  {pin.value.existing
                    ? "This answer was already pinned."
                    : "Pinned. People who ask something similar will see it under Past answers."}
                </p>
              )}
              {pin.value.kind === "error" && (
                <div class="alert" role="alert" data-testid="pin-error">
                  {pin.value.message}
                </div>
              )}
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
