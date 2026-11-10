// Minimal Zetaris REST client: run one SQL statement through /sql-editor/sqls/run, the same
// route scripts/zetaris_sql.py uses. Never logs the key.
import type { Config } from "./config.ts";

export class ZetarisError extends Error {}

export interface SqlResult {
  rows: string[][];
  headers: string[];
}

export function zetarisClient(cfg: Config, timeoutMs = 120_000) {
  if (!cfg.apiKey) {
    throw new ZetarisError("Set ZETARIS_API_KEY in .env.local.");
  }
  return {
    async run(sql: string, limit = 100): Promise<SqlResult> {
      let res: Response;
      try {
        res = await fetch(`${cfg.zetarisUrl}/sql-editor/sqls/run`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${cfg.apiKey}`,
            "X-Org-ID": cfg.orgId,
            "X-Request-ID": crypto.randomUUID(),
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            queryId: crypto.randomUUID(),
            sql,
            source: "SqlEditor",
            limit,
          }),
          signal: AbortSignal.timeout(timeoutMs),
        });
      } catch (e) {
        throw new ZetarisError(
          `Cannot reach ${cfg.zetarisUrl}: ${
            e instanceof Error ? e.message : e
          }`,
        );
      }
      const text = await res.text();
      if (!res.ok) {
        let msg = text;
        try {
          msg = JSON.parse(text).msg ?? text;
        } catch { /* keep the raw text */ }
        throw new ZetarisError(`HTTP ${res.status}: ${msg.slice(0, 400)}`);
      }
      const out = JSON.parse(text || "null");
      return { rows: out?.data ?? [], headers: out?.headers ?? [] };
    },
  };
}

export type Zetaris = ReturnType<typeof zetarisClient>;
