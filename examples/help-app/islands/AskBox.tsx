import { useSignal } from "@preact/signals";
import { useEffect, useRef } from "preact/hooks";
import type { AskResult, Mode, PastAnswerOut } from "../core/ask.ts";
import { SourceCard } from "../components/SourceCard.tsx";
import { StaleBadge } from "../components/StaleBadge.tsx";
import { Html } from "../components/Html.tsx";
import LikeButton from "./LikeButton.tsx";
import { ExampleView } from "../components/ExampleView.tsx";
import type { ExampleResult } from "../core/example.ts";
import { getName, postEvent } from "./prefs.ts";

const MODE_KEY = "help_mode";
const CLIENT_TIMEOUT_MS = 130_000;
const EXAMPLE_TIMEOUT_MS = 960_000; // up to three model calls, each possibly a large model

type UiMode = Mode | "example";

interface Props {
  llmConfigured: boolean;
  model: string;
}

type Reply = { error?: { code?: string; message?: string } };
type Step = { label: string; at: number };

type State =
  | { kind: "idle" }
  | { kind: "loading"; mode: UiMode; steps: Step[] }
  | { kind: "example"; result: ExampleResult; request: string; seconds: number }
  | { kind: "done"; result: AskResult; question: string; seconds: number }
  | { kind: "error"; code: string; message: string };

type PinState =
  | { kind: "none" }
  | { kind: "pinning" }
  | { kind: "pinned"; existing: boolean }
  | { kind: "error"; message: string };

export default function AskBox({ llmConfigured, model }: Props) {
  const question = useSignal("");
  const mode = useSignal<UiMode>("search");
  const state = useSignal<State>({ kind: "idle" });
  const copied = useSignal(false);
  const pin = useSignal<PinState>({ kind: "none" });
  const used = useSignal<PastAnswerOut | null>(null);
  const abort = useRef<AbortController | null>(null);
  const showSteps = useSignal(false);
  // The answer card has two tabs: the answer and its sources.
  const side = useSignal<"answer" | "sources">("answer");
  const shown = side; // the tab that looks selected
  function flipTo(k: "answer" | "sources") {
    side.value = k;
  }
  const now = useSignal(0); // ticks while loading, so elapsed times update
  const loading = state.value.kind === "loading";
  useEffect(() => {
    if (!loading) return;
    now.value = performance.now();
    const t = setInterval(() => now.value = performance.now(), 500);
    return () => clearInterval(t);
  }, [loading]);

  useEffect(() => {
    try {
      const saved = localStorage.getItem(MODE_KEY);
      if (llmConfigured && (saved === "answer" || saved === "example")) {
        mode.value = saved;
      }
    } catch { /* storage blocked */ }
  }, []);

  function pick(m: UiMode) {
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
    const isExample = mode.value === "example";
    const timer = setTimeout(
      () => ctl.abort(),
      isExample ? EXAMPLE_TIMEOUT_MS : CLIENT_TIMEOUT_MS,
    );
    const started = performance.now();
    copied.value = false;
    side.value = "answer";
    pin.value = { kind: "none" };
    used.value = null;
    state.value = {
      kind: "loading",
      mode: mode.value,
      steps: [{
        label: isExample
          ? "Sending your request"
          : mode.value === "answer"
          ? "Searching the docs, then writing an answer"
          : "Searching the docs",
        at: started,
      }],
    };
    try {
      const res = await fetch(isExample ? "/api/example" : "/api/ask", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          ...(isExample ? { accept: "application/x-ndjson" } : {}),
        },
        body: JSON.stringify(
          isExample ? { request: text } : { question: text, mode: mode.value },
        ),
        signal: ctl.signal,
      });
      let body: Reply | null = null;
      if (isExample && res.ok && res.body) {
        // Progress lines arrive as they happen; the last line is the result or an error.
        const reader = res.body.pipeThrough(new TextDecoderStream())
          .getReader();
        let buf = "";
        for (;;) {
          const { value, done } = await reader.read();
          if (value) buf += value;
          const lines = buf.split("\n");
          buf = done ? "" : lines.pop() ?? "";
          for (const line of done ? lines.concat(buf) : lines) {
            if (!line.trim()) continue;
            let msg:
              & { stage?: string; result?: unknown }
              & Record<string, unknown>;
            try {
              msg = JSON.parse(line);
            } catch {
              continue;
            }
            if (typeof msg.stage === "string") {
              const cur: State = state.value;
              if (cur.kind === "loading") {
                state.value = {
                  ...cur,
                  steps: [...cur.steps, {
                    label: msg.stage,
                    at: performance.now(),
                  }],
                };
              }
            } else body = msg.result ?? msg;
          }
          if (done) break;
        }
      } else body = await res.json().catch(() => null);
      if (!res.ok || !body || body.error) {
        state.value = {
          kind: "error",
          code: body?.error?.code ?? "http",
          message: body?.error?.message ??
            `The server answered with an error (HTTP ${res.status}).`,
        };
        return;
      }
      if (isExample) {
        state.value = {
          kind: "example",
          result: body as unknown as ExampleResult,
          request: text,
          seconds: (performance.now() - started) / 1000,
        };
        return;
      }
      state.value = {
        kind: "done",
        result: body as unknown as AskResult,
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
  const placeholder = mode.value === "example"
    ? "Describe what you want, e.g. same as the SIC and EDGAR check, but for sic 7372"
    : mode.value === "answer"
    ? "Ask a question about Zetaris or this repository"
    : "Search the Zetaris docs";
  return (
    <div>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          submit();
        }}
        role="search"
      >
        <label for="q" class="sr-only">Your question</label>
        <div class="searchbox">
          <textarea
            id="q"
            name="question"
            data-testid="question"
            maxLength={500}
            rows={1}
            placeholder={placeholder}
            value={question.value}
            onInput={(e) => {
              const t = e.target as HTMLTextAreaElement;
              question.value = t.value;
              t.style.height = "auto";
              t.style.height = `${Math.min(t.scrollHeight, 160)}px`;
            }}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                submit();
              }
            }}
          />
          <button
            type="submit"
            class="btn"
            data-testid="submit"
            disabled={busy}
          >
            {busy ? "Working…" : "Search"}
          </button>
        </div>
        <div class="controls">
          <fieldset class="modes" aria-label="Mode">
            <label title="Ranked passages from the docs. No LLM needed.">
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
                ? "A written answer from the top passages"
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
            <label
              title={llmConfigured
                ? "A new SQL example, checked against Zetaris"
                : "Needs OLLAMA_URL and OLLAMA_MODEL in .env.local"}
            >
              <input
                type="radio"
                name="mode"
                value="example"
                disabled={!llmConfigured}
                checked={mode.value === "example"}
                onChange={() => pick("example")}
              />
              Example
            </label>
          </fieldset>
          <div
            class={`status${busy ? " busy" : ""}`}
            role="status"
            aria-live="polite"
            data-testid="status"
          >
            {s.kind === "loading" && (
              <div class="steps" data-testid="steps">
                {(() => {
                  const cur = s.steps[s.steps.length - 1];
                  const before = s.steps.slice(0, -1);
                  const secs = (t0: number, t1: number) => {
                    const v = Math.max(0, (t1 - t0) / 1000);
                    return `${v.toFixed(v < 10 ? 1 : 0)} s`;
                  };
                  return (
                    <>
                      <div class="step active">
                        <span class="spinner" aria-hidden="true" />
                        <span class="step-label">{cur.label}</span>
                        <span class="step-time">
                          {secs(s.steps[0].at, now.value)}
                        </span>
                        {before.length > 0 && (
                          <button
                            type="button"
                            class="chev"
                            aria-expanded={showSteps.value}
                            aria-controls="step-log"
                            onClick={() => showSteps.value = !showSteps.value}
                            data-testid="steps-toggle"
                          >
                            <span aria-hidden="true">
                              {showSteps.value ? "▾" : "▸"}
                            </span>{" "}
                            {before.length} done
                          </button>
                        )}
                      </div>
                      <ol
                        class="step-log"
                        id="step-log"
                        hidden={!showSteps.value}
                      >
                        {before.map((st, i) => (
                          <li
                            key={i}
                            class={/rejected|did not/i.test(st.label)
                              ? "failed"
                              : ""}
                          >
                            <span class="tick" aria-hidden="true">
                              {/rejected|did not/i.test(st.label) ? "✗" : "✓"}
                            </span>
                            <span class="step-label">{st.label}</span>
                            <span class="step-time">
                              {secs(st.at, s.steps[i + 1].at)}
                            </span>
                          </li>
                        ))}
                      </ol>
                    </>
                  );
                })()}
              </div>
            )}
            {s.kind === "error" && (
              <div
                class="status-err"
                role="alert"
                data-testid="error"
                data-code={s.code}
              >
                {s.message}
                {s.code === "not_found" && mode.value === "example" && (
                  <div class="actions">
                    <button
                      type="button"
                      class="btn ghost"
                      data-testid="try-answer"
                      onClick={() => {
                        pick("answer");
                        submit(question.value);
                      }}
                    >
                      Ask this in Answer mode
                    </button>
                  </div>
                )}
              </div>
            )}
            {s.kind === "example" &&
              `Done in ${s.seconds.toFixed(0)} s. ${s.result.attempts.length} ${
                s.result.attempts.length === 1 ? "attempt" : "attempts"
              }.`}
            {s.kind === "done" &&
              `Done in ${
                s.seconds.toFixed(1)
              } s. ${s.result.sources.length} sources${
                s.result.answer !== null ? " and an answer" : ""
              }.`}
          </div>
        </div>
        {!llmConfigured && (
          <p class="hint">
            Answer and Example modes are off: no LLM is configured.
          </p>
        )}
        {mode.value === "example" && (
          <p class="hint">
            Writes new SQL from this repo's scripts. For "how do I…" questions,
            Answer usually fits better.
          </p>
        )}
      </form>

      {s.kind === "example" && (
        <section aria-label="Generated example">
          <ExampleView
            result={s.result}
            request={s.request}
            onRegenerate={() => {
              pick("example");
              submit(s.request);
            }}
          />
        </section>
      )}

      {s.kind === "done" && (
        <section aria-label="Results">
          {s.result.pastAnswers.length > 0 && (
            <section aria-label="Past answers" data-testid="past">
              <div class="sectionhead">
                <h2>Past answers</h2>
                <span class="fine">
                  Pinned for a similar question. Using one makes no model call.
                </span>
              </div>
              <ul class="list">
                {s.result.pastAnswers.map((p) => (
                  <li class="item past" data-testid="past-answer">
                    <h3>
                      <span class="fine">Pinned for:</span> {p.question}
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
                  </li>
                ))}
              </ul>
              {used.value && (
                <div data-testid="used-answer">
                  <h2>Pinned answer</h2>
                  <Html html={used.value.answerHtml} class="md answer-md" />
                </div>
              )}
            </section>
          )}
          {(() => {
            const r = s.result;
            const hasAnswer = r.answer !== null;
            const sourcesFace = (
              <div
                data-testid="sources-face"
                hidden={hasAnswer && side.value !== "sources"}
              >
                {!hasAnswer && (
                  <div class="sectionhead">
                    <h2>Sources</h2>
                    <span class="fine">
                      Similarity plus a small keyword bonus, so not strictly
                      descending.
                    </span>
                  </div>
                )}
                {hasAnswer && (
                  <p class="fine">
                    Similarity plus a small keyword bonus, so not strictly
                    descending.
                  </p>
                )}
                {r.sources.length === 0
                  ? (
                    <p data-testid="no-sources">
                      Nothing matched. Try different words.
                    </p>
                  )
                  : (
                    <ul class="list">
                      {r.sources.map((src, i) => (
                        <SourceCard s={src} rank={i + 1} />
                      ))}
                    </ul>
                  )}
              </div>
            );
            if (!hasAnswer) return sourcesFace;
            return (
              <div
                class="flipcard"
                data-testid="flipcard"
                data-side={side.value}
              >
                <div
                  class="flipbar"
                  role="tablist"
                  aria-label="Answer or sources"
                >
                  {(["answer", "sources"] as const).map((k) => (
                    <button
                      type="button"
                      role="tab"
                      id={`tab-${k}`}
                      aria-selected={shown.value === k}
                      aria-controls={`face-${k}`}
                      class={shown.value === k ? "on" : ""}
                      data-testid={`tab-${k}`}
                      onClick={() => flipTo(k)}
                    >
                      {k === "answer"
                        ? "Answer"
                        : `Sources (${r.sources.length})`}
                    </button>
                  ))}
                </div>
                <div class="flipbody">
                  <div
                    id="face-answer"
                    role="tabpanel"
                    aria-labelledby="tab-answer"
                    hidden={side.value !== "answer"}
                  >
                    <Html
                      html={r.answerHtml ?? ""}
                      class="md answer-md"
                      testid="answer"
                    />
                    <div class="actions">
                      <button
                        type="button"
                        class="btn ghost"
                        onClick={() => copy(r.answer ?? "")}
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
                      <button
                        type="button"
                        class="btn ghost"
                        onClick={() => flipTo("sources")}
                      >
                        See the {r.sources.length} sources
                      </button>
                    </div>
                    {pin.value.kind === "pinned" && (
                      <p class="fine" role="status" data-testid="pinned">
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
                    <p class="fine">
                      Written by a language model from the sources in the
                      Sources tab. Check the cited files, and treat generated
                      SQL as unverified.
                    </p>
                  </div>
                  <div
                    id="face-sources"
                    role="tabpanel"
                    aria-labelledby="tab-sources"
                    hidden={side.value !== "sources"}
                  >
                    {sourcesFace}
                  </div>
                </div>
              </div>
            );
          })()}
        </section>
      )}
    </div>
  );
}
