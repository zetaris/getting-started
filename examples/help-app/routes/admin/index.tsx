import { page } from "fresh";
import { define } from "../../utils.ts";
import { TopBar } from "../../components/TopBar.tsx";
import { StatusBadge } from "../../components/StatusBadge.tsx";
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
  return (
    <>
      <TopBar path="/admin" />
      <main id="main">
        <h1>Status</h1>
        <p class="lead">
          Checked {report.checkedAt}. Reload the page to check again.
        </p>
        <ul class="checks" data-testid="checks">
          {report.checks.map((c) => (
            <li data-testid={`check-${c.name}`}>
              <span>
                <strong>{c.name}</strong> <StatusBadge ok={c.ok} />
              </span>
              <span class="detail">{c.detail}</span>
            </li>
          ))}
        </ul>
        {report.usl.length > 0 && (
          <>
            <h2>help_usl tables</h2>
            <table>
              <tbody>
                {report.usl.map((u) => (
                  <tr>
                    <th>{u.table}</th>
                    <td>{u.rows === null ? "no answer" : `${u.rows} rows`}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </>
        )}
        <h2>Last ingest</h2>
        <p>
          {report.lastIngest
            ? `${report.lastIngest.at}: ${report.lastIngest.segments} segments, model ${report.lastIngest.model}`
            : "No ingest manifest yet. Run the commands below."}
        </p>
        <h2>Re-ingest (run in a terminal)</h2>
        <p class="lead">
          Ingest takes several minutes, so it is a command, not a button.
        </p>
        <pre class="answer">{`cd examples/help-app
deno task help:ingest --dry-run   # show what would be sent
deno task help:ingest --yes       # drop and recreate the collection, ingest, verify
deno task help:usl --rebuild      # rebuild help_usl after the catalog changes`}</pre>
      </main>
    </>
  );
});
