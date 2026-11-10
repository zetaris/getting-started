// Markdown to HTML for pages that show untrusted text: the repo's own files, the Kbase snapshot
// (upstream web content) and language-model answers. Raw HTML in the source is escaped, not
// passed through, and only http(s), mailto and relative links and images are kept.
import { Marked } from "marked";

export function escapeHtml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/** The href to use, or null when its scheme could run script or load something unexpected. */
export function safeUrl(href: string | null | undefined): string | null {
  if (!href) return null;
  const h = href.trim();
  // Browsers ignore tabs, newlines and control characters inside a scheme.
  // deno-lint-ignore no-control-regex
  const compact = h.replace(/[\u0000- ]/g, "");
  const scheme = compact.match(/^([a-zA-Z][a-zA-Z0-9+.-]*):/)?.[1]
    ?.toLowerCase();
  if (scheme && !["http", "https", "mailto"].includes(scheme)) return null;
  if (compact.startsWith("//")) return null; // protocol-relative: would leave the site
  return h;
}

const md = new Marked({ gfm: true, breaks: false });
md.use({
  renderer: {
    html({ text }) {
      // Models put <br> inside table cells (Markdown has no other line break there). That one
      // tag, bare, is safe to keep; every other piece of raw HTML is still shown as text.
      if (/^<br\s*\/?>$/i.test(text.trim())) return "<br>";
      return escapeHtml(text);
    },
    link({ href, title, tokens }) {
      const inner = this.parser.parseInline(tokens);
      const url = safeUrl(href);
      if (!url) return inner;
      const t = title ? ` title="${escapeHtml(title)}"` : "";
      return `<a href="${
        escapeHtml(url)
      }"${t} rel="noopener noreferrer">${inner}</a>`;
    },
    image({ href, title, text }) {
      const url = safeUrl(href);
      if (!url) return escapeHtml(text);
      const t = title ? ` title="${escapeHtml(title)}"` : "";
      return `<img src="${escapeHtml(url)}" alt="${
        escapeHtml(text)
      }"${t} loading="lazy">`;
    },
  },
});

export function renderMarkdown(source: string): string {
  return md.parse(source, { async: false }) as string;
}
