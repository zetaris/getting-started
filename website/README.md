# GitHub Pages onboarding guide

The site renders the existing repository Markdown into a static documentation site. Edit the original guides to change their content. `build.mjs` defines the published pages and navigation; assets define the layout and copy buttons. SQL scripts, issue records and other unpublished references link to their source on GitHub at the build's commit.

Only the listed Markdown pages and `website/assets/` are included in the artifact. Client environment files, caches and platform credentials are not read by the build. The browser does not connect to Zetaris.

## Preview locally

Use Node.js 22 or later and Python 3:

```bash
npm ci --ignore-scripts --prefix website
npm run build --prefix website
python3 -m http.server 8080 --directory site
```

Open <http://localhost:8080>. The generated `site/` directory and `node_modules/` are gitignored. All site links are relative, so the same artifact works beneath the GitHub Pages repository path.

After editing a guide, run `npm run build --prefix website` again and refresh the browser. The preview server does not rebuild the HTML automatically; you can leave it running while rebuilding.

## Local navigation graph

Each build regenerates `.scratch/website-navigation.md` from links between published Markdown pages. It shows content connections, the beginner journey and a per-page link list. Sidebar sections group the nodes; repeated sidebar links are omitted.

The graph stays outside `site/` and the published page list. Keep `.scratch/` locally excluded through `.git/info/exclude`; do not commit or publish the graph. Rebuild after changing page content or navigation to keep it current.

## Assistant prompt launcher

Start here, the connection overview and the installation guide include a JDBC/REST prompt launcher. The build reads the prompts from `docs/connections/client-setup.md` and adds the repository and a read-only sample-query goal. Links use the displayed prompt; they contain no local settings or credentials.

- Cursor uses its [documented prompt link](https://prod.cursor.com/docs/reference/deeplinks).
- Claude Code uses its [documented desktop link](https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link).
- Codex uses `codex://threads/new?prompt=...`, confirmed in the installed app's URL handler. This is a desktop-app integration rather than a published web API contract.

The user reviews and sends the prompt in the destination app. Browser protocol permissions and an installed compatible app are required. Copying the prompt is the fallback; an opened chat must use this repository as its workspace.
