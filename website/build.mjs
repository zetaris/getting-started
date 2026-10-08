import { Marked, Renderer } from 'marked';
import { readFileSync, writeFileSync, mkdirSync, cpSync, existsSync, statSync, rmSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'site');
const repository = process.env.GITHUB_REPOSITORY || 'zetaris/getting-started';
const revision = process.env.GITHUB_SHA || execFileSync('git', ['rev-parse', '--abbrev-ref', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
const github = `https://github.com/${repository}`;
// This explicit list is the publication boundary. Never copy the checkout into site/.
const groups = [
  ['Your first project', [
    ['START-HERE.md', 'Start here'],
    ['docs/install/updated_zetaris_installation_guide.md', 'Install locally'],
    ['docs/connections/README.md', 'Connect to Zetaris'],
    ['docs/guides/first-dataset.md', 'Get your first rows'],
    ['docs/guides/project-paths.md', 'Choose your project'],
    ['docs/guides/demo-template.md', 'Prepare your demo'],
  ]],
  ['Help and reference', [
    ['docs/guides/troubleshooting.md', 'Troubleshooting'],
    ['docs/guides/recipe-readiness.md', 'Available recipes'],
    ['scripts/HOWTO.md', 'Client scripts'],
    ['docs/connections/cursor-connection.md', 'Cursor connection'],
    ['docs/connections/codex-connection.md', 'Codex connection'],
    ['docs/connections/claude-code-connection.md', 'Claude Code connection'],
    ['docs/connections/lightning-recipe-reference.md', 'Recipe SQL reference'],
    ['docs/guides/zetaris-lightning-sql-commands.md', 'Lightning SQL commands'],
    ['docs/guides/zetaris-lightning-sql-companion.md', 'SQL gotchas and limits'],
  ]],
  ['Explore more data', [
    ['open_data/rest_apis/HOWTO.md', 'REST sources'],
    ['open_data/rest_apis/rest-api-sources.md', 'REST source catalog'],
    ['open_data/parquet_csv/HOWTO.md', 'File sources'],
    ['open_data/parquet_csv/parquet-csv-data-sources.md', 'File source catalog'],
    ['open_data/usl/HOWTO.md', 'Unified Semantic Layer'],
    ['open_data/usl/usl-sources.md', 'USL model catalog'],
    ['docs/guides/create-edgar-pudl-noaa-usl.md', 'EDGAR, PUDL and NOAA'],
  ]],
];
const pages = groups.flatMap(([, entries]) => entries);
const routes = new Map(pages.map(([source]) => [source, source === 'START-HERE.md' ? 'index.html' : source.replace(/\.md$/, '.html')]));
const journey = ['START-HERE.md', 'docs/connections/README.md', 'docs/guides/first-dataset.md', 'docs/guides/project-paths.md', 'docs/guides/demo-template.md'];
const escape = value => String(value).replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);
const relative = (from, to) => path.posix.relative(path.posix.dirname(from), to);
const encodePath = value => value.split('/').map(encodeURIComponent).join('/');

rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });
cpSync(path.join(root, 'website/assets'), path.join(output, 'assets'), { recursive: true });
writeFileSync(path.join(output, '.nojekyll'), '');

for (const [source, label] of pages) {
  const route = routes.get(source);
  const headings = [];
  const slugs = new Map();
  const parser = new Marked({
    gfm: true,
    renderer: {
      heading({ tokens, depth }) {
        const text = this.parser.parseInline(tokens);
        const plain = tokens.map(token => token.text || token.raw).join('');
        const base = plain.toLowerCase().replace(/[^\p{L}\p{N}\p{M}\s_-]/gu, '').replace(/\s/g, '-');
        const count = slugs.get(base) || 0;
        slugs.set(base, count + 1);
        const id = count ? `${base}-${count}` : base;
        if (depth === 2 || depth === 3) headings.push({ depth, text, id });
        return `<h${depth} id="${escape(id)}">${text}</h${depth}>\n`;
      },
      table(token) {
        return `<div class="table-scroll" tabindex="0" role="region" aria-label="Scrollable table">${Renderer.prototype.table.call(this, token)}</div>`;
      },
    },
    walkTokens(token) {
      if (token.type !== 'link' && token.type !== 'image') return;
      if (/^(?:[a-z][a-z\d+.-]*:|\/\/|#)/i.test(token.href)) return;
      const [target, fragment = ''] = token.href.split('#');
      const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(source), decodeURI(target)));
      const fullPath = path.join(root, resolved);
      if (resolved.startsWith('../') || !existsSync(fullPath)) throw new Error(`${source}: missing link target ${token.href}`);
      const suffix = fragment ? `#${fragment}` : '';
      if (routes.has(resolved)) {
        token.href = `${relative(route, routes.get(resolved))}${suffix}`;
      } else {
        const type = statSync(fullPath).isDirectory() ? 'tree' : 'blob';
        token.href = `${github}/${type}/${encodeURIComponent(revision)}/${encodePath(resolved)}${suffix}`;
      }
    },
  });
  const content = parser.parse(readFileSync(path.join(root, source), 'utf8'));
  const nav = groups.map(([title, entries]) => `<div class="nav-group"><p>${escape(title)}</p>${entries.map(([file, text]) => `<a href="${relative(route, routes.get(file))}"${file === source ? ' aria-current="page"' : ''}>${escape(text)}</a>`).join('')}</div>`).join('');
  const toc = headings.map(({ depth, text, id }) => `<a class="depth-${depth}" href="#${escape(id)}">${text}</a>`).join('');
  const position = journey.indexOf(source);
  const pager = position < 0 ? '' : `<nav class="pager" aria-label="Journey steps">${[position - 1, position + 1].map((index, side) => {
    if (!journey[index]) return '<span></span>';
    const file = journey[index];
    return `<a href="${relative(route, routes.get(file))}"><small>${side ? 'Next step' : 'Previous step'}</small>${escape(pages.find(([candidate]) => candidate === file)[1])}<span aria-hidden="true">${side ? ' &rarr;' : ' &larr;'}</span></a>`;
  }).join('')}</nav>`;
  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="Zetaris onboarding: get access, connect, verify your first dataset, build a project and prepare a reproducible demo.">
  <title>${escape(label)} · Zetaris getting started</title>
  <script src="${relative(route, 'assets/theme.js')}"></script>
  <link rel="icon" href="${relative(route, 'assets/favicon.svg')}" type="image/svg+xml">
  <link rel="preload" href="${relative(route, 'assets/fonts/plus-jakarta-sans.ttf')}" as="font" type="font/ttf" crossorigin>
  <link rel="stylesheet" href="${relative(route, 'assets/style.css')}">
  <script src="${relative(route, 'assets/site.js')}" defer></script>
</head>
<body>
  <a class="skip-link" href="#main">Skip to content</a>
  <header class="header"><a class="brand" href="${relative(route, 'index.html')}"><span class="brand-images"><img class="brand-logo logo-light" src="${relative(route, 'assets/brand/zetaris-indigo.svg')}" alt="Zetaris" width="747" height="207"><img class="brand-logo logo-dark" src="${relative(route, 'assets/brand/zetaris-reversed.svg')}" alt="Zetaris" width="747" height="207"></span><span class="brand-label">Getting started</span></a><div class="header-actions"><button id="theme-toggle" class="theme-toggle" type="button" aria-label="Switch to dark mode" title="Switch to dark mode"><svg class="theme-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.5 13.2A8.7 8.7 0 0 1 10.8 3.5 8.7 8.7 0 1 0 20.5 13.2Z"/></svg><svg class="theme-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg></button><a class="github-link" href="${github}">View repository <span aria-hidden="true">&nearr;</span></a></div></header>
  <div class="shell">
    <aside class="sidebar"><nav class="desktop-nav" aria-label="Documentation">${nav}</nav><details class="mobile-nav"><summary>Browse the guide</summary><nav aria-label="Documentation">${nav}</nav></details></aside>
    <main id="main" tabindex="-1"><div class="document-meta"><span>Getting started / ${escape(label)}</span><a href="${github}/blob/${encodeURIComponent(revision)}/${encodePath(source)}">Read source &nearr;</a></div>
      ${source === 'START-HERE.md' ? '<div class="intro"><p>YOUR FIRST ZETARIS PROJECT</p><h1>Connect your data.<br>Build something with it.</h1><div>Get set up, try a dataset, then choose what to build.</div><a class="start-link" href="#1-check-your-prerequisites">Start with access &rarr;</a></div>' : ''}
      <article>${source === 'START-HERE.md' ? content.replace('<h1 id="start-here">Start here</h1>', '<h2 id="start-here">Start here</h2>') : content}</article>${pager}
      <footer>Built from the repository documentation. Use your own account and team names on the shared instance.</footer>
    </main>
    <aside class="outline" aria-label="On this page"><p>On this page</p>${toc}</aside>
  </div>
</body>
</html>`;
  mkdirSync(path.dirname(path.join(output, route)), { recursive: true });
  writeFileSync(path.join(output, route), html);
}
console.log(`Built ${pages.length} documentation pages in ${output}`);
