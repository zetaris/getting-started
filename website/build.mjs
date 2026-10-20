import { Marked, Renderer } from 'marked';
import { readFileSync, writeFileSync, mkdirSync, cpSync, existsSync, statSync, rmSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'site');
const repository = process.env.GITHUB_REPOSITORY || 'zetaris/getting-started';
// Source links always point at main so Pages builds do not pin a publish branch or commit.
const revision = 'main';
const github = `https://github.com/${repository}`;
// This explicit list is the publication boundary. Never copy the checkout into site/.
const groups = [
  ['Your first project', [
    ['START-HERE.md', 'Start here'],
    ['docs/connections/README.md', 'Connect to Zetaris'],
    ['docs/connections/lightning-recipe-reference.md', 'Run your first SQL'],
    ['docs/guides/first-dataset.md', 'Connect PokéAPI'],
    ['docs/guides/project-paths.md', 'Choose your project'],
    ['docs/guides/demo-template.md', 'Prepare your demo'],
  ]],
  ['Cookbooks', [
    ['docs/guides/recipe-readiness.md', 'Choose a cookbook'],
    ['open_data/rest_apis/HOWTO.md', 'REST cookbook'],
    ['open_data/rest_apis/rest-api-sources.md', 'REST source catalog'],
    ['open_data/parquet_csv/HOWTO.md', 'File cookbook'],
    ['open_data/parquet_csv/parquet-csv-data-sources.md', 'File source catalog'],
    ['open_data/usl/HOWTO.md', 'USL cookbook'],
    ['open_data/usl/usl-sources.md', 'USL model catalog'],
    ['docs/guides/create-edgar-pudl-noaa-usl.md', 'EDGAR, PUDL and NOAA'],
  ]],
  ['Agents and scripts', [
    ['docs/connections/client-setup.md', 'Client setup'],
    ['scripts/HOWTO.md', 'Client scripts'],
    ['docs/connections/cursor-connection.md', 'Cursor connection'],
    ['docs/connections/codex-connection.md', 'Codex connection'],
    ['docs/connections/claude-code-connection.md', 'Claude Code connection'],
  ]],
  ['Help and reference', [
    ['docs/guides/troubleshooting.md', 'Troubleshooting'],
    ['docs/guides/zetaris-lightning-sql-commands.md', 'Lightning SQL commands'],
    ['docs/guides/zetaris-lightning-sql-companion.md', 'SQL gotchas and limits'],
  ]],
  ['Installation', [
    ['docs/install/updated_zetaris_installation_guide.md', 'Install locally'],
    ['docs/install/managed-aws-cluster-guide.md', 'Managed AWS cluster'],
  ]],
];
const pages = groups.flatMap(([, entries]) => entries);
const routes = new Map(pages.map(([source]) => [source, source === 'START-HERE.md' ? 'index.html' : source.replace(/\.md$/, '.html')]));
const contentLinks = new Map(pages.map(([source]) => [source, new Set()]));
const journey = ['START-HERE.md', 'docs/connections/README.md', 'docs/connections/lightning-recipe-reference.md', 'docs/guides/first-dataset.md', 'docs/guides/project-paths.md', 'docs/guides/demo-template.md'];
const escape = value => String(value).replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);
const relative = (from, to) => path.posix.relative(path.posix.dirname(from), to);
const encodePath = value => value.split('/').map(encodeURIComponent).join('/');
const connectionGuide = readFileSync(path.join(root, 'docs/connections/client-setup.md'), 'utf8');
const prompts = {};
for (const [protocol, section] of [['jdbc', '5. JDBC starter prompt'], ['rest', '6. REST starter prompt']]) {
  const text = connectionGuide.split(`## ${section}`)[1]?.match(/```text\n([\s\S]*?)\n```/)?.[1];
  if (!text || !text.startsWith('Read AGENTS.md')) throw new Error(`Missing ${protocol} starter prompt`);
  prompts[protocol] = `Use the getting-started repository at https://github.com/zetaris/getting-started as the workspace. If it is not checked out, help me clone and open it first. Read docs/connections/client-setup.md for setup. Keep credentials in .env.local, never in this prompt or a report.\n\n${text.replace(/Goal: <[\s\S]*?>/, 'Goal: verify SQL execution, inspect the supplied NY_TAXI and TPCDS_DB tables, then run a sample SELECT with LIMIT 5. Do not create objects.')}`;
}
const launchUrls = prompt => ({
  codex: `codex://threads/new?prompt=${encodeURIComponent(prompt)}`,
  cursor: `cursor://anysphere.cursor-deeplink/prompt?text=${encodeURIComponent(prompt)}`,
  claude: `claude://code/new?q=${encodeURIComponent(prompt)}`,
});
const launcherLinks = launchUrls(prompts.jdbc);
const launcher = `<section class="assistant-launcher" aria-labelledby="assistant-heading" data-prompts="${escape(JSON.stringify(prompts))}">
  <h2 id="assistant-heading">Start with your coding assistant</h2>
  <p>Open this repository in your assistant, choose a connection and review the prompt before sending it.</p>
  <div class="protocol-field"><label for="prompt-protocol">Connection</label><select id="prompt-protocol"><option value="jdbc">JDBC</option><option value="rest">REST</option></select></div>
  <pre class="starter-prompt"><code>${escape(prompts.jdbc)}</code></pre>
  <div class="launcher-actions"><a data-assistant="codex" href="${escape(launcherLinks.codex)}">Open in Codex</a><a data-assistant="cursor" href="${escape(launcherLinks.cursor)}">Open in Cursor</a><a data-assistant="claude" href="${escape(launcherLinks.claude)}">Open in Claude Code</a></div>
  <p class="launcher-note">Requires the desktop app. If it doesn't open, copy the prompt into your assistant. Configure .env.local first; JDBC also needs the matching driver JAR.</p>
</section>`;

rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });
cpSync(path.join(root, 'website/assets'), path.join(output, 'assets'), { recursive: true });
writeFileSync(path.join(output, '.nojekyll'), '');

for (const [source, label] of pages) {
  const route = routes.get(source);
  const headings = [];
  const slugs = new Map();
  let setupProtocol;
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
        const display = source === 'docs/connections/client-setup.md' ? text.replace(/^\d+\. /, '') : text;
        if (depth === 2 || depth === 3) headings.push({ depth, text: display, id, protocol: setupProtocol });
        return `<h${depth} id="${escape(id)}">${display}</h${depth}>\n`;
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
        if (token.type === 'link' && resolved !== source) contentLinks.get(source).add(resolved);
        token.href = `${relative(route, routes.get(resolved))}${suffix}`;
      } else {
        const type = statSync(fullPath).isDirectory() ? 'tree' : 'blob';
        token.href = `${github}/${type}/${encodeURIComponent(revision)}/${encodePath(resolved)}${suffix}`;
      }
    },
  });
  const markdown = readFileSync(path.join(root, source), 'utf8');
  let content;
  if (source === 'docs/connections/client-setup.md') {
    const [intro, jdbc, rest] = markdown.split(/<!-- protocol: (?:jdbc|rest) -->/);
    if (!jdbc || !rest) throw new Error('Missing client setup protocol content');
    content = parser.parse(intro);
    content += '<div class="setup-switch" role="group" aria-label="Connection instructions"><button type="button" data-setup-choice="jdbc" aria-pressed="true">JDBC</button><button type="button" data-setup-choice="rest" aria-pressed="false">REST</button></div>';
    for (const [protocol, guide] of [['jdbc', jdbc], ['rest', rest]]) {
      setupProtocol = protocol;
      content += `<section data-setup-protocol="${protocol}" aria-label="${protocol.toUpperCase()} instructions">${parser.parse(guide)}</section>`;
    }
  } else {
    content = parser.parse(markdown);
  }
  if (source === 'START-HERE.md' || source === 'docs/connections/README.md' || source === 'docs/install/updated_zetaris_installation_guide.md') content += launcher;
  if (content.includes('class="assistant-launcher"')) {
    const entry = { depth: 2, text: 'Start with your coding assistant', id: 'assistant-heading' };
    headings.push(entry);
  }
  const nav = groups.map(([title, entries]) => `<div class="nav-group"><p>${escape(title)}</p>${entries.map(([file, text]) => `<a href="${relative(route, routes.get(file))}"${file === source ? ' aria-current="page"' : ''}>${escape(text)}</a>`).join('')}</div>`).join('');
  const toc = headings.map(({ depth, text, id, protocol }) => `<a class="depth-${depth}" href="#${escape(id)}"${protocol ? ` data-setup-outline="${protocol}"` : ''}>${text}</a>`).join('');
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
      ${source === 'START-HERE.md' ? '<div class="intro"><p>YOUR FIRST ZETARIS PROJECT</p><h1>Connect your data.<br>Build something with it.</h1><div>Get set up, try a dataset, then choose what to build.</div></div>' : ''}
      <article>${source === 'START-HERE.md' ? content.replace('<h1 id="start-here">Start here</h1>', '<h2 id="start-here">Start here</h2>') : content}</article>${pager}
      <footer>Built from the repository documentation. Use your own Zetaris instance, installed locally or deployed through AWS.</footer>
    </main>
    <aside class="outline" aria-label="On this page"><p>On this page</p>${toc}</aside>
  </div>
</body>
</html>`;
  mkdirSync(path.dirname(path.join(output, route)), { recursive: true });
  writeFileSync(path.join(output, route), html);
}
// Preserve the original AWS guide URL for existing links and bookmarks.
writeFileSync(path.join(output, 'docs/install/aws-installation-guide.html'), `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="0; url=managed-aws-cluster-guide.html">
  <link rel="canonical" href="managed-aws-cluster-guide.html">
  <title>Managed AWS cluster · Zetaris getting started</title>
</head>
<body><p>The AWS guide has moved to <a href="managed-aws-cluster-guide.html">Managed AWS cluster</a>.</p></body>
</html>`);

// Keep the local navigation graph outside the published site artifact.
const graphDirectory = path.join(root, '.scratch');
const nodeIds = new Map(pages.map(([source], index) => [source, `p${index}`]));
const pageLabels = new Map(pages);
const graph = [
  '# Website navigation graph',
  '',
  'Generated from the current website sources by `npm run build --prefix website`. Do not edit this file by hand.',
  '',
  '## Page content links',
  '',
  'Arrows show links in page content, not a required reading order. Pages are grouped by sidebar section; repeated sidebar, header, footer and pager links are excluded here. Repeated links and links to different anchors on the same target page are combined. External URLs, unpublished repository files, images and same-page anchors are excluded.',
  '',
  `Pages: ${pages.length}. Directed content connections: ${[...contentLinks.values()].reduce((total, links) => total + links.size, 0)}.`,
  '',
  '```mermaid',
  'flowchart LR',
];
for (const [index, [title, entries]] of groups.entries()) {
  graph.push(`  subgraph g${index}[${JSON.stringify(title)}]`);
  for (const [source, label] of entries) graph.push(`    ${nodeIds.get(source)}[${JSON.stringify(label)}]`);
  graph.push('  end');
}
for (const [source, targets] of contentLinks) {
  for (const target of pages.map(([file]) => file).filter(file => targets.has(file))) graph.push(`  ${nodeIds.get(source)} --> ${nodeIds.get(target)}`);
}
graph.push('```', '', '## Recommended beginner journey', '', 'These arrows show the forward Next step links in the journey pager. Previous step links return to the preceding page.', '', '```mermaid', 'flowchart LR');
for (const source of journey) graph.push(`  ${nodeIds.get(source)}[${JSON.stringify(pageLabels.get(source))}]`);
for (let index = 1; index < journey.length; index++) graph.push(`  ${nodeIds.get(journey[index - 1])} --> ${nodeIds.get(journey[index])}`);
graph.push('```', '', '## Content links by page', '', 'Use this list to trace individual connections when the full graph is dense.', '', '| Page | Links to |', '|---|---|');
for (const [source, label] of pages) {
  const targets = pages.map(([file]) => file).filter(file => contentLinks.get(source).has(file));
  graph.push(`| [${label}](../${source}) | ${targets.map(target => `[${pageLabels.get(target)}](../${target})`).join(', ') || 'None'} |`);
}
graph.push('', '## Sidebar sections', '', 'Grouping only; there are no repeated sidebar arrows in the content graph.', '');
for (const [title, entries] of groups) graph.push(`- **${title}**: ${entries.map(([, label]) => label).join(', ')}.`);
mkdirSync(graphDirectory, { recursive: true });
writeFileSync(path.join(graphDirectory, 'website-navigation.md'), `${graph.join('\n')}\n`);
console.log(`Built ${pages.length} documentation pages in ${output}; updated .scratch/website-navigation.md`);
