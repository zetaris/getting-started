// A short window of a passage, centred on the first question word, safe to drop into HTML.
import { escapeHtml } from "./markdown.ts";
import { questionWords } from "./rank.ts";

const WINDOW = 240;
const BEFORE = 80;

/** Markdown as one line of readable text: no heading marks, emphasis, images or link targets. */
export function plainText(md: string): string {
  return md
    .replace(/```[a-z]*\n?/gi, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, " ")
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/^#{1,6}\s*/gm, "")
    .replace(/[*_`>|]+/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function escapeReg(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function highlight(text: string, words: string[]): string {
  if (words.length === 0) return escapeHtml(text);
  const re = new RegExp(
    `(?<![A-Za-z0-9_])(${words.map(escapeReg).join("|")})(?![A-Za-z0-9_])`,
    "gi",
  );
  let out = "";
  let last = 0;
  for (const m of text.matchAll(re)) {
    const i = m.index ?? 0;
    out += escapeHtml(text.slice(last, i));
    out += `<mark>${escapeHtml(m[1])}</mark>`;
    last = i + m[1].length;
  }
  return out + escapeHtml(text.slice(last));
}

/** About 240 characters around the earliest question word. No match uses the start of the text. */
export function matchSnippet(
  question: string,
  md: string,
): { text: string; html: string } {
  const plain = plainText(md);
  const words = questionWords(question);
  const lower = plain.toLowerCase();
  let idx = -1;
  let hitLen = 0;
  for (const w of words) {
    const i = lower.indexOf(w.toLowerCase());
    if (i >= 0 && (idx < 0 || i < idx)) {
      idx = i;
      hitLen = w.length;
    }
  }
  let start = 0;
  let end = Math.min(plain.length, WINDOW);
  if (idx >= 0) {
    start = Math.max(0, idx - BEFORE);
    end = Math.min(plain.length, start + WINDOW);
    if (end - start < WINDOW) start = Math.max(0, end - WINDOW);
    if (start > idx) start = idx;
    if (end < idx + hitLen) end = Math.min(plain.length, idx + hitLen);
  }
  if (start > 0) {
    const sp = plain.indexOf(" ", start);
    if (sp > start && (idx < 0 || sp < idx)) start = sp + 1;
  }
  if (end < plain.length) {
    const sp = plain.lastIndexOf(" ", end);
    if (sp > start && (idx < 0 || sp >= idx + hitLen)) end = sp;
  }
  const cut = plain.slice(start, end).trim();
  const text = `${start > 0 ? "…" : ""}${cut}${end < plain.length ? "…" : ""}`;
  return { text, html: highlight(text, words) };
}
