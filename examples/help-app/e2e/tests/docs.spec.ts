import { expect, test } from "@playwright/test";
import { APPS } from "../support/env.ts";

const side = (page: import("@playwright/test").Page) => page.getByRole("complementary", { name: "Documentation index" });

test("the Docs page is a docs site: index on the left, search at the top", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs`);
  await expect(side(page)).toBeVisible();
  await expect(page.getByTestId("docs-search")).toBeVisible();
  await expect(page.getByTestId("doc-count")).toHaveText("5 files");
  await expect(side(page).getByText("Knowledge base", { exact: true })).toBeVisible();
  await expect(side(page).getByText("Repo docs", { exact: true })).toBeVisible();
});

test("search is a meaning search: results link into the docs", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs`);
  await page.getByTestId("docs-search").fill("How do I register a REST source?");
  await page.getByTestId("docs-search").press("Enter");
  await expect(page).toHaveURL(/\/docs\/search\?q=/);
  const hits = page.getByTestId("hit");
  await expect(hits.first()).toBeVisible();
  await expect(hits.first().getByRole("link")).toHaveAttribute("href", /\/docs\//);
  await expect(page.getByTestId("hit-count")).toContainText("ranked by meaning");
  await hits.first().getByRole("link").click();
  await expect(page.getByTestId("doc-body")).toBeVisible();
});

test("a repo file opens rendered, marked in the index, with its chunks listed", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs`);
  await side(page).locator("details").evaluateAll((d) => d.forEach((x) => ((x as HTMLDetailsElement).open = true)));
  await side(page).getByRole("link", { name: "Agent instructions" }).click();
  await expect(page).toHaveURL(/\/docs\/AGENTS\.md$/);
  await expect(page.getByTestId("doc-body").getByRole("heading", { name: "Agent instructions" })).toBeVisible();
  await expect(side(page).getByRole("link", { name: "Agent instructions" })).toHaveAttribute("aria-current", "page");
  await page.getByText(/chunks in the index/).click();
  await expect(page.getByTestId("chunks").getByRole("row")).toHaveCount(3); // header + 2 mock chunks
});

test("a Kbase page opens from the snapshot", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs/kbase/how-to-clone-pipeline`);
  await expect(page.getByTestId("doc-body").getByRole("heading", { level: 1 })).toHaveText("How to clone Pipeline");
  await expect(page.getByRole("link", { name: "Original page" })).toHaveAttribute("href", /kbase\.zetaris\.com/);
  await expect(page.getByTestId("doc-body")).toContainText(/clone/i);
});

test("only catalog files can be opened: traversal and uncatalogued paths are 404", async ({ request }) => {
  const paths = [
    "/docs/README.md",
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

test("search text is shown as text, never as HTML", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs/search?q=${encodeURIComponent("<img src=x onerror=window.__pwned=1>")}`);
  expect(await page.locator("main img").count()).toBe(0);
  expect(await page.evaluate(() => (window as unknown as { __pwned?: number }).__pwned)).toBeUndefined();
});

test("with Zetaris down the Docs page explains instead of failing", async ({ page }) => {
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

test("the Docs page fits a phone, with the index behind Browse", async ({ page }) => {
  await page.setViewportSize({ width: 412, height: 915 });
  await page.goto(`${APPS.full.url}/docs`);
  await expect(side(page)).toBeHidden();
  await expect(page.getByText("Browse all docs")).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(0);
});
