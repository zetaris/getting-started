import { useSignal } from "@preact/signals";
import { useEffect, useRef } from "preact/hooks";
import type { AskResult, Mode, PastAnswerOut } from "../core/ask.ts";
import { SourceCard } from "../components/SourceCard.tsx";
import { StaleBadge } from "../components/StaleBadge.tsx";
import { Html } from "../components/Html.tsx";
import LikeButton from "./LikeButton.tsx";
import { ExampleView } from "../components/ExampleView.tsx";
import type { ExampleResult } from "../core/example.ts";
import { actorLabel } from "../core/actor.ts";
import { postEvent } from "./prefs.ts";
import { pageWindow } from "../core/page.ts";
import WorkStatus from "./WorkStatus.tsx";

const MODE_KEY = "help_mode";
const CLIENT_TIMEOUT_MS = 130_000;
const EXAMPLE_TIMEOUT_MS = 960_000; // up to three model calls, each possibly a large model

type UiMode = Mode | "example";

interface Props {
  llmConfigured: boolean;
  model: string;
  candidatesEnabled: boolean;
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

export default function AskBox(
  { llmConfigured, model, candidatesEnabled }: Props,
) {
  const question = useSignal("");
  const mode = useSignal<UiMode>("search");
  const state = useSignal<State>({ kind: "idle" });
  const copied = useSignal(false);
  const pin = useSignal<PinState>({ kind: "none" });
  const used = useSignal<PastAnswerOut | null>(null);
  const abort = useRef<AbortController | null>(null);
  // The answer card has two tabs: the answer and its sources.
  const side = useSignal<"answer" | "sources">("answer");
  const shown = side; // the tab that looks selected
  const page = useSignal(1);
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

  async function submit(q = question.value, opts?: { fresh?: boolean }) {
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
    page.value = 1;
    pin.value = { kind: "none" };
    used.value = null;
    state.value = {
      kind: "loading",
      mode: mode.value,
      steps: [{ label: "Sending your request", at: started }],
    };
    try {
      const res = await fetch(isExample ? "/api/example" : "/api/ask", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          accept: "application/x-ndjson",
        },
        body: JSON.stringify(
          isExample
            ? { request: text }
            : { question: text, mode: mode.value, fresh: opts?.fresh === true },
        ),
        signal: ctl.signal,
      });
      let body: Reply | null = null;
      if (res.ok && res.body) {
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
        <div class="ask-top">
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
        {s.kind === "loading" && (
          <WorkStatus steps={s.steps} now={now.value} />
        )}
        </div>
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
        {s.kind !== "loading" && s.kind !== "idle" && (
        <div class="controls">
          <div
            class="status"
            role="status"
            aria-live="polite"
            data-testid="status"
          >
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
              (s.result.mode === "answer" && s.result.answer === null &&
                  s.result.pastAnswers.length > 0
                ? s.result.pastAnswers.length === 1
                  ? `A pinned answer matches this question (similarity ${
                    s.result.pastAnswers[0].similarity.toFixed(2)
                  }).`
                  : `${s.result.pastAnswers.length} pinned answers match. The closest is similarity ${
                    s.result.pastAnswers[0].similarity.toFixed(2)
                  }.`
                : `Done in ${
                  s.seconds.toFixed(1)
                } s. ${s.result.sources.length} sources${
                  s.result.answer !== null ? " and an answer" : ""
                }.`)}
          </div>
        </div>
        )}
        {!llmConfigured && (
          <p class="hint">
            Answer and Example modes are off: no LLM is configured.
          </p>
        )}
      </form>

      {s.kind === "example" && (
        <section aria-label="Generated example">
          <ExampleView
            result={s.result}
            request={s.request}
            candidatesEnabled={candidatesEnabled}
            onRegenerate={() => {
              pick("example");
              submit(s.request);
            }}
          />
        </section>
      )}

      {s.kind === "done" && s.result.mode === "answer" &&
        s.result.answer === null && s.result.pastAnswers.length > 0 && (
        <section aria-label="Pinned answers" data-testid="pin-offer">
          {(() => {
            const chosen = used.value;
            const pins = chosen
              ? s.result.pastAnswers.filter((p) =>
                p.pinId === chosen.pinId
              )
              : s.result.pastAnswers;
            return (
              <div class="flipcard">
                <div class="flipbar">
                  <span class="offer-label">
                    {pins.length === 1
                      ? "Pinned answer"
                      : `Pinned answers (${pins.length})`}
                  </span>
                </div>
                <div class="flipbody">
                  <ul class="list">
                    {pins.map((p, i) => (
                      <li class="item past" data-testid="past-answer">
                        <p>
                          {pins.length > 1 && <span class="fine">{i + 1}.
                          </span>}
                          <span class="fine">Pinned for:</span> {p.question}
                        </p>
                        <div class="meta">
                          <span
                            class="pill"
                            title="Cosine similarity to your question"
                          >
                            similarity {p.similarity.toFixed(2)}
                          </span>
                          <span>pinned by {actorLabel(p.pinnedBy)}</span>
                          <span>used {p.uses}×</span>
                          {p.model && <span>{p.model}</span>}
                          <StaleBadge stale={p.stale} />
                        </div>
                        <Html html={p.answerHtml} class="md answer-md" />
                        <div class="actions">
                          <button
                            type="button"
                            class="btn"
                            data-testid="use"
                            disabled={used.value?.pinId === p.pinId}
                            onClick={() =>
                              useAnswer(p)}
                          >
                            {used.value?.pinId === p.pinId
                              ? "Using this answer"
                              : "Use this answer"}
                          </button>
                          <LikeButton pinId={p.pinId} likes={p.likes} />
                        </div>
                        {used.value?.pinId === p.pinId && (
                          <p class="fine" data-testid="used-answer">
                            Using this pinned answer. No new answer was written.
                          </p>
                        )}
                      </li>
                    ))}
                  </ul>
                  <div class="actions">
                    <button
                      type="button"
                      class="btn ghost"
                      data-testid="fresh"
                      onClick={() => submit(s.question, { fresh: true })}
                    >
                      Write a new answer
                    </button>
                  </div>
                </div>
              </div>
            );
          })()}
        </section>
      )}

      {s.kind === "done" &&
        !(s.result.mode === "answer" && s.result.answer === null &&
          s.result.pastAnswers.length > 0) &&
        (
          <section aria-label="Results">
            {s.result.pastAnswers.length > 0 && (
              <section aria-label="Past answers" data-testid="past">
                <div class="sectionhead">
                  <h2>Past answers</h2>
                  <span class="fine">
                    Pinned for a similar question. Using one makes no model
                    call.
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
                        <span>pinned by {actorLabel(p.pinnedBy)}</span>
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
                    </div>
                  )}
                  {r.sources.length === 0
                    ? (
                      <p data-testid="no-sources">
                        Nothing matched. Try different words.
                      </p>
                    )
                    : (() => {
                      const win = pageWindow(r.sources, page.value);
                      const top = r.sources[0].score;
                      return (
                        <>
                          <ul class="list">
                            {win.items.map((src, i) => (
                              <SourceCard
                                s={src}
                                rank={win.start + i + 1}
                                top={top}
                              />
                            ))}
                          </ul>
                          {win.pages > 1 && (
                            <nav
                              class="pager"
                              aria-label="Search results pages"
                            >
                              <button
                                type="button"
                                class="btn ghost"
                                disabled={win.current <= 1}
                                onClick={() => page.value = win.current - 1}
                              >
                                Previous
                              </button>
                              <span>
                                {win.start + 1}–{win.end} of {r.sources.length}
                              </span>
                              <button
                                type="button"
                                class="btn ghost"
                                disabled={win.current >= win.pages}
                                onClick={() => page.value = win.current + 1}
                              >
                                Next
                              </button>
                            </nav>
                          )}
                        </>
                      );
                    })()}
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
