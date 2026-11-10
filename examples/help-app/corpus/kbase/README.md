# Zetaris Knowledge base snapshot

A dated text snapshot of the public Zetaris Knowledge base (`kbase.zetaris.com/knowledge/…`), converted from HTML to Markdown by `deno task help:fetch-kbase`. **The live kbase is authoritative.** This copy can lag it, and some pages are marked "in revision".

- One file per page, named by the page's URL slug. Each has a header with the source URL, kind, the sitemap's `lastmod`, the retrieval date and a content hash.
- `manifest.json` lists every sitemap page with its status. Pages that are image-only or video-only are skipped (text only in this version) and appear in the manifest as `skipped-textless`.
- E-mail addresses and `password`/`token`/`api key` style pairs are replaced with `<REDACTED>`; the manifest records how many replacements each page needed.
- The fetch respects `robots.txt`, sends one request per second with a generic User-Agent, and keeps raw HTML only in a git-ignored cache.
- The content is Zetaris's. The repo owner confirmed they act as its owner, so copying it here needed no further sign-off; check that no page is internal or customer-specific before publishing the repo.
