import { expect, test } from "@playwright/test";
import { APPS } from "../support/env.ts";

test("the status page lists each check, the USL tables and the re-ingest commands", async ({ page }) => {
  await page.goto(`${APPS.full.url}/admin`);
  await expect(page.getByTestId("check-Zetaris")).toContainText("reachable");
  await expect(page.getByTestId("check-Relations")).toContainText("help_search");
  await expect(page.getByTestId("check-Vector index")).toContainText("42 rows");
  await expect(page.getByTestId("check-LLM")).toContainText("mock-model is available");
  await expect(page.getByText("help_usl tables")).toBeVisible();
  await page.getByText("Re-ingest commands").click();
  await expect(page.getByText("deno task help:ingest --dry-run")).toBeVisible();
});

test("with Zetaris down the status page says so, and still renders", async ({ page }) => {
  await page.goto(`${APPS.down.url}/admin`);
  await expect(page.getByTestId("check-Zetaris")).toContainText("not reachable");
  await expect(page.getByTestId("check-LLM")).toContainText("not configured");
  await expect(page.locator("body")).not.toContainText("127.0.0.1");
});

test("/api/status returns the same report as JSON", async ({ request }) => {
  const r = await request.get(`${APPS.full.url}/api/status`);
  expect(r.status()).toBe(200);
  const j = await r.json();
  expect(j.checks.map((c: { name: string }) => c.name)).toContain("Zetaris");
});
