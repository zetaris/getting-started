// Snapshot the Zetaris Knowledge base (public pages) as Markdown under corpus/kbase/.
//   deno task help:fetch-kbase [--force] [--limit N]
// Reads the sitemap, fetches each page at most once a second with a generic User-Agent, keeps
// the raw HTML in .cache/ (git-ignored) so conversions can be re-run without fetching, and
// writes one Markdown file per page with a source header plus corpus/kbase/manifest.json.
// The kbase is the upstream authority; this is a dated snapshot.
import {
  convertPage,
  isTextless,
  kindOfPage,
  parseSitemap,
  redact,
  sha256,
  slugOf,
} from "../core/kbase.ts";

const SITEMAP = "https://kbase.zetaris.com/sitemap.xml";
const UA =
  "getting-started-help-app/0.1 (corpus snapshot, 1 request per second)";
const OUT = "corpus/kbase";
const CACHE = ".cache/kbase-html";
const force = Deno.args.includes("--force");
const limitArg = Deno.args.indexOf("--limit");
const limit = limitArg >= 0 ? Number(Deno.args[limitArg + 1]) : Infinity;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
let lastFetch = 0;
async function get(url: string): Promise<Response> {
  const wait = 1000 - (Date.now() - lastFetch);
  if (wait > 0) await sleep(wait);
  lastFetch = Date.now();
  return await fetch(url, {
    headers: { "User-Agent": UA },
    signal: AbortSignal.timeout(30_000),
  });
}

await Deno.mkdir(OUT, { recursive: true });
await Deno.mkdir(CACHE, { recursive: true });

const sm = await get(SITEMAP);
if (!sm.ok) throw new Error(`sitemap: HTTP ${sm.status}`);
const entries = parseSitemap(await sm.text()).slice(0, limit);
console.log(`sitemap: ${entries.length} pages`);

interface Row {
  url: string;
  slug: string;
  lastmod: string;
  status: "ok" | "skipped-textless" | "skipped-no-article" | "failed";
  title?: string;
  kind?: string;
  sha256?: string;
  chars?: number;
  redactions?: number;
  images?: number;
  note?: string;
}
const rows: Row[] = [];
const retrieved = new Date().toISOString().slice(0, 10);

for (const [i, e] of entries.entries()) {
  const slug = slugOf(e.url);
  const cachePath = `${CACHE}/${slug}.html`;
  let html: string | null = null;
  if (!force) {
    try {
      html = await Deno.readTextFile(cachePath);
    } catch { /* not cached */ }
  }
  if (html === null) {
    let res: Response | null = null;
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        res = await get(e.url);
        if (res.ok || res.status < 500) break;
      } catch { /* retry once */ }
    }
    if (!res || !res.ok) {
      rows.push({
        url: e.url,
        slug,
        lastmod: e.lastmod,
        status: "failed",
        note: `HTTP ${res?.status ?? "no response"}`,
      });
      console.log(`[${i + 1}/${entries.length}] FAILED ${slug}`);
      continue;
    }
    html = await res.text();
    await Deno.writeTextFile(cachePath, html);
  }
  const page = convertPage(html);
  if (!page) {
    rows.push({
      url: e.url,
      slug,
      lastmod: e.lastmod,
      status: "skipped-no-article",
    });
    continue;
  }
  if (isTextless(page)) {
    rows.push({
      url: e.url,
      slug,
      lastmod: e.lastmod,
      status: "skipped-textless",
      title: page.title,
      images: page.images,
      chars: page.textChars,
    });
    continue;
  }
  const red = redact(page.markdown);
  const redTitle = redact(page.title);
  const kind = kindOfPage(slug, page.title);
  const body = red.text;
  const hash = await sha256(body);
  const header = [
    "---",
    "source: kbase",
    `url: ${e.url}`,
    `title: ${JSON.stringify(redTitle.text)}`,
    `kind: ${kind}`,
    `lastmod: ${e.lastmod}`,
    `retrieved: ${retrieved}`,
    `sha256: ${hash}`,
    "---",
    "",
  ].join("\n");
  await Deno.writeTextFile(
    `${OUT}/${slug}.md`,
    `${header}# ${redTitle.text}\n\n${body}\n`,
  );
  rows.push({
    url: e.url,
    slug,
    lastmod: e.lastmod,
    status: "ok",
    title: redTitle.text,
    kind,
    sha256: hash,
    chars: body.length,
    redactions: red.count + redTitle.count,
    images: page.images,
  });
  if ((i + 1) % 25 === 0) console.log(`[${i + 1}/${entries.length}] ${slug}`);
}

const count = (s: Row["status"]) => rows.filter((r) => r.status === s).length;
const manifest = {
  retrieved,
  sitemap: SITEMAP,
  pages: rows.length,
  ok: count("ok"),
  skippedTextless: count("skipped-textless"),
  skippedNoArticle: count("skipped-no-article"),
  failed: count("failed"),
  rows,
};
await Deno.writeTextFile(
  `${OUT}/manifest.json`,
  JSON.stringify(manifest, null, 2) + "\n",
);
console.log(JSON.stringify({ ...manifest, rows: undefined }));
