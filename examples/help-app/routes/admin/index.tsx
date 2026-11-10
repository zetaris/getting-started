import { page } from "fresh";
import { define } from "../../utils.ts";
import { TopBar } from "../../components/TopBar.tsx";
import { gatherStatus } from "../../core/status.ts";
import {
  getConfig,
  getZetaris,
  readIngestManifest,
} from "../../core/server.ts";

export const handler = define.handlers({
  async GET() {
    const report = await gatherStatus(
      getConfig(),
      getZetaris(30_000),
      readIngestManifest,
    );
    return page({ report });
  },
});

export default define.page<typeof handler>(function Admin({ data }) {
  const { report } = data;
  const bad = report.checks.filter((c) => !c.ok).length;
  return (
    <>
      <TopBar path="/admin" />
      <main id="main">
        <p class="eyebrow">Status</p>
        <h1>
          {bad === 0
            ? "Everything is working"
            : `${bad} ${bad === 1 ? "check needs" : "checks need"} attention`}
        </h1>
        <p class="lead">
          Checked {report.checkedAt}. Reload to check again.
        </p>
        <ul class="checks" data-testid="checks">
          {report.checks.map((c) => (
            <li data-testid={`check-${c.name}`}>
              <span
                class={`dot${c.ok ? "" : " bad"}`}
                role="img"
                aria-label={c.ok ? "OK" : "Problem"}
              />
              <span class="name">{c.name}</span>
              <span class="detail">{c.detail}</span>
            </li>
          ))}
        </ul>
        {report.usl.length > 0 && (
          <>
            <div class="sectionhead">
              <h2>help_usl tables</h2>
            </div>
            <div class="kv">
              {report.usl.map((u) => (
                <div>
                  <b>{u.rows === null ? "n/a" : u.rows}</b>
                  <span>{u.table}</span>
                </div>
              ))}
            </div>
          </>
        )}
        <div class="sectionhead">
          <h2>Last ingest</h2>
        </div>
        <p class="lead">
          {report.lastIngest
            ? `${report.lastIngest.at}: ${report.lastIngest.segments} segments, model ${report.lastIngest.model}`
            : "No ingest manifest yet. Run the commands below."}
        </p>
        <details class="quiet">
          <summary>Re-ingest commands (run in a terminal)</summary>
          <p class="fine">
            An ingest takes several minutes, so it is a command, not a button.
          </p>
          <pre class="code">{`cd examples/help-app
deno task help:ingest --dry-run   # show what would be sent
deno task help:ingest --yes       # drop and recreate the collection, ingest, verify
deno task help:usl --rebuild      # rebuild help_usl after the catalog changes`}</pre>
        </details>
      </main>
    </>
  );
});
