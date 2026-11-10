import { define } from "../../utils.ts";
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
    return new Response(JSON.stringify(report), {
      headers: {
        "content-type": "application/json",
        "cache-control": "no-store",
      },
    });
  },
});
