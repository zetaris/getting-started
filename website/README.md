# GitHub Pages onboarding guide

The site renders the existing repository Markdown into a static documentation site. Edit the original guides to change their content. `build.mjs` defines the published pages and navigation; assets define the layout and copy buttons. Plans, SQL scripts, issue records and other unpublished references link to their source on GitHub at the build's commit.

Only the listed Markdown pages and `website/assets/` are included in the artifact. Client environment files, caches and platform credentials are not read by the build. The browser does not connect to Zetaris.

## Preview locally

Use Node.js 22 or later and Python 3:

```bash
npm ci --ignore-scripts --prefix website
npm run build --prefix website
python3 -m http.server 8080 --directory site
```

Open <http://localhost:8080>. The generated `site/` directory and `node_modules/` are gitignored. All site links are relative, so the same artifact works beneath the GitHub Pages repository path.

## Assistant prompt launcher

Start here, the connection overview and the installation guide include a JDBC/REST prompt launcher. The build reads the starter prompts from `docs/connections/codex-connection.md`, adds the repository reference and a read-only starter goal, and builds links from that exact displayed text. No local settings or credentials are read into the links.

- Cursor uses its [documented prompt link](https://prod.cursor.com/docs/reference/deeplinks).
- Claude Code uses its [documented desktop link](https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link).
- Codex uses `codex://threads/new?prompt=...`, confirmed in the installed app's URL handler. This is a desktop-app integration rather than a published web API contract.

The user reviews and sends the prompt in the destination app. Browser protocol permissions and an installed compatible app are required. Copying the prompt is the fallback; an opened chat must use this repository as its workspace.

## Publish this branch

The workflow in `.github/workflows/pages.yml` builds and deploys pushes to `codex/hackathon-user-journey`. It can also be dispatched manually once GitHub exposes the workflow. If this guide moves to another publishing branch, update the push branch filter.

1. In the repository's **Settings → Pages**, choose **GitHub Actions** as the build and deployment source.
2. In **Settings → Environments → github-pages**, allow deployments from `codex/hackathon-user-journey` if branch restrictions are configured.
3. Commit and push the site files on that branch.
4. Check **Actions → Publish onboarding guide**. A successful deployment reports its actual site URL.

The expected URL without a custom domain is <https://zetaris.github.io/getting-started/>. Repository plan, organization policy, existing Pages configuration and environment approvals can affect deployment. Creating the files locally does not enable Pages or publish the site.

GitHub's [Pages deployment guide](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages) explains the artifact and deployment workflow.
