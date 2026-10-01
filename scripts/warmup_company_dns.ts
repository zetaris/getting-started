#!/usr/bin/env -S deno run --allow-net --allow-env
//
// Warms up the company_dns service before running
// open_data/rest_apis/sql/non_rate_limited/10_company_dns_sic_create.sql.
//
// Why: during planning (docs/plans/archive/edgar-sic-enrichment-plan.md §4,
// §7), the hosted instance (https://company-dns.mediumroast.io) was observed
// to return an empty response on a cold first request, resolving on retry
// ~10s later -- consistent with a scale-to-zero host. Running CREATE
// LIGHTNING REST TABLE straight into a cold instance risks Zetaris seeing
// that same empty/slow response and either failing outright or registering
// a table with no rows. This script polls /health until the service is
// warm, then pre-hits the one bulk SIC endpoint (plan §4.4, §8.2) that SQL
// file is about to register as a REST table, so Zetaris's own request lands
// on an already-warm backend. (Earlier versions of this script and that SQL
// file warmed/fetched 4 endpoints -- confirmed 2026-09-21 that the other 3
// are fully redundant with this one for this use case, see the SQL file's
// caveat 1a -- trimmed to match.)
//
// Usage (from the repository root):
//   deno run --allow-net --allow-env scripts/warmup_company_dns.ts
//   COMPANY_DNS_BASE_URL=http://localhost:8000 deno run --allow-net --allow-env scripts/warmup_company_dns.ts   (self-hosted)
//
// Exit code 0 means the service is warm and the bulk endpoint responded
// (regardless of whether its row count matched expectations -- that's
// logged as a warning, not a failure, since the SIC list could legitimately
// grow over time). Exit code 1 means the service never became healthy, or
// the endpoint request itself failed outright.

const BASE_URL = Deno.env.get("COMPANY_DNS_BASE_URL") ?? "https://company-dns.mediumroast.io";
const HEALTH_TIMEOUT_MS = 30_000;
const HEALTH_POLL_INTERVAL_MS = 2_000;
const REQUEST_TIMEOUT_MS = 15_000;

// Expected row count confirmed live 2026-09-21 against the hosted instance
// (see docs/plans/archive/edgar-sic-enrichment-plan.md §4.4). Not a hard requirement
// -- the SIC list could grow -- but a big shortfall is worth a loud warning
// rather than a silent pass, since it's also how the EDGAR truncation bug
// (sql/01_edgar_company_facts.sql, caveat 4) was originally noticed.
const SIC_CODES_PATH = "/V3.0/na/sic/code/%25";
const SIC_CODES_COUNT_PATH = ["data", "total"];
const SIC_CODES_EXPECTED_MIN = 1000;

function withTimeout(ms: number): { signal: AbortSignal; cancel: () => void } {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), ms);
  return { signal: controller.signal, cancel: () => clearTimeout(id) };
}

async function pollHealth(): Promise<void> {
  const deadline = Date.now() + HEALTH_TIMEOUT_MS;
  let attempt = 0;
  while (Date.now() < deadline) {
    attempt++;
    const { signal, cancel } = withTimeout(REQUEST_TIMEOUT_MS);
    try {
      const res = await fetch(`${BASE_URL}/health`, { signal });
      cancel();
      if (res.ok) {
        const body = await res.json();
        if (body?.status === "healthy") {
          console.log(`[warmup] /health OK after ${attempt} attempt(s): ${JSON.stringify(body)}`);
          return;
        }
        console.log(`[warmup] attempt ${attempt}: /health returned 200 but not "healthy": ${JSON.stringify(body)}`);
      } else {
        console.log(`[warmup] attempt ${attempt}: /health responded HTTP ${res.status}`);
      }
    } catch (err) {
      cancel();
      console.log(`[warmup] attempt ${attempt}: /health unreachable (${(err as Error).message})`);
    }
    await new Promise((r) => setTimeout(r, HEALTH_POLL_INTERVAL_MS));
  }
  throw new Error(`company_dns did not become healthy within ${HEALTH_TIMEOUT_MS}ms`);
}

function getPath(obj: unknown, path: string[]): unknown {
  return path.reduce((acc: unknown, key) => (acc == null ? undefined : (acc as Record<string, unknown>)[key]), obj);
}

async function warmSicCodesEndpoint(): Promise<boolean> {
  const url = `${BASE_URL}${SIC_CODES_PATH}`;
  const started = performance.now();
  const { signal, cancel } = withTimeout(REQUEST_TIMEOUT_MS);
  try {
    const res = await fetch(url, { signal });
    cancel();
    const elapsedMs = Math.round(performance.now() - started);
    if (!res.ok) {
      console.warn(`[warmup] sic_codes: HTTP ${res.status} after ${elapsedMs}ms -- ${url}`);
      return false;
    }
    const body = await res.json();
    const total = getPath(body, SIC_CODES_COUNT_PATH);
    const ok = typeof total === "number" && total >= SIC_CODES_EXPECTED_MIN;
    console.log(
      `[warmup] sic_codes: ${elapsedMs}ms, total=${total} ${ok ? "(ok)" : `(WARNING: expected >= ${SIC_CODES_EXPECTED_MIN})`}`,
    );
    return true;
  } catch (err) {
    cancel();
    console.warn(`[warmup] sic_codes: request failed -- ${(err as Error).message}`);
    return false;
  }
}

async function main() {
  console.log(`[warmup] target: ${BASE_URL}`);
  await pollHealth();

  const ok = await warmSicCodesEndpoint();
  if (!ok) {
    throw new Error("the sic_codes bulk endpoint failed outright -- see warning above");
  }
  console.log("[warmup] done -- company_dns should now be warm for 10_company_dns_sic_create.sql.");
}

main().catch((err) => {
  console.error(`[warmup] FAILED: ${(err as Error).message}`);
  Deno.exit(1);
});
