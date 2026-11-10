import { expect, test } from "@playwright/test";
import { APPS } from "../support/env.ts";

test("the Docs index lists the catalog by corpus and kind, and filters", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs`);
  await expect(page.getByTestId("doc-count")).toHaveText("5 files");
  await expect(page.getByRole("heading", { name: "Knowledge base" })).toBeVisible();
  await page.getByLabel("Filter by title or path").fill("scripts");
  await page.getByRole("button", { name: "Filter" }).click();
  await expect(page.getByTestId("doc-count")).toHaveText("1 of 5 files");
  await expect(page.getByTestId("doc-item")).toHaveCount(1);
  await page.goto(`${APPS.full.url}/docs?corpus=kbase`);
  await expect(page.getByTestId("doc-item")).toHaveCount(1);
});

test("a repo file opens rendered, with its chunks listed", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs`);
  await page.locator("details").evaluateAll((d) => d.forEach((x) => ((x as HTMLDetailsElement).open = true)));
  await page.getByRole("link", { name: "Agent instructions" }).click();
  await expect(page).toHaveURL(/\/docs\/AGENTS\.md$/);
  await expect(page.getByTestId("doc-body").getByRole("heading", { name: "Agent instructions" })).toBeVisible();
  await page.getByText(/chunks in the index/).click();
  await expect(page.getByTestId("chunks").getByRole("row")).toHaveCount(3); // header + 2 mock chunks
});

test("a Kbase page opens from the snapshot", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs/kbase/how-to-clone-pipeline`);
  await expect(page.getByTestId("doc-body").getByRole("heading", { level: 1 })).toHaveText("How to clone Pipeline");
  await expect(page.getByRole("link", { name: "Original page" })).toHaveAttribute("href", /kbase\.zetaris\.com/);
  await expect(page.getByTestId("doc-body")).toContainText(/clone/i);
});

test("only catalog files can be opened: traversal and uncatalogued files are 404", async ({ request }) => {
  const paths = [
    "/docs/README.md", // exists on disk, but is not in the (mock) catalog
    "/docs/../../.env.local",
    "/docs/..%2F..%2F.env.local",
    "/docs/%2e%2e/%2e%2e/.env.local",
    "/docs/.env.local",
    "/docs/kbase/README",
    "/docs/kbase/..%2FREADME",
    "/docs//etc/passwd",
  ];
  for (const p of paths) {
    const r = await request.get(`${APPS.full.url}${p}`, { maxRedirects: 0 });
    expect(r.status(), p).toBe(404);
  }
});

test("with Zetaris down the Docs index explains instead of failing", async ({ page }) => {
  await page.goto(`${APPS.down.url}/docs`);
  await expect(page.getByTestId("error")).toContainText("Zetaris is not reachable");
});

test("a source card links into the Docs browser", async ({ page }) => {
  await page.goto(APPS.full.url);
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  const first = page.getByTestId("source").first();
  await expect(first.getByRole("link", { name: "open_data/rest_apis/HOWTO.md" })).toHaveAttribute("href", "/docs/open_data/rest_apis/HOWTO.md");
});

test("the Docs page fits a phone", async ({ page }) => {
  await page.setViewportSize({ width: 412, height: 915 });
  await page.goto(`${APPS.full.url}/docs`);
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(0);
});
