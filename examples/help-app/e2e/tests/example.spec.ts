import { expect, test } from "@playwright/test";
import { APPS, MOCK } from "../support/env.ts";

const REQ = "Same as the SIC check but count the docs";
const SQL_FILE = "open_data/usl/sql/02_sic_edgar_usl_select.sql";

test.beforeEach(async ({ request }) => {
  await request.get(`${MOCK}/__control?reset=1`);
});

async function generate(
  page: import("@playwright/test").Page,
  mode = "pass",
  request?: import("@playwright/test").APIRequestContext,
) {
  if (request) await request.get(`${MOCK}/__control?exampleMode=${mode}`);
  await page.goto(APPS.full.url);
  await page.getByRole("radio", { name: "Answer" }).waitFor();
  await expect(page.getByRole("radio", { name: "Example" })).toBeEnabled();
  await page.getByRole("radio", { name: "Example" }).check({ force: true });
  await expect(page.getByRole("radio", { name: "Example" })).toBeChecked();
  await page.getByTestId("question").fill(REQ);
  await page.getByTestId("submit").click();
}

test("a generated example shows its sources, one badge and the SQL", async ({ page, request }) => {
  await generate(page, "pass", request);
  await expect(page.getByTestId("example-status")).toHaveText("Generated, dry-run passed");
  await expect(page.getByTestId("example-sql")).toContainText("SELECT count(*)");
  await expect(page.getByTestId("example-source").first().getByRole("link")).toHaveAttribute(
    "href",
    `/docs/${SQL_FILE}`,
  );
  await expect(page.getByTestId("example-status")).toHaveCount(1);
  await expect(page.getByTestId("attempts")).toContainText("Attempts (1)");
  // Nothing in the page claims the example is verified.
  await expect(page.locator("main")).not.toContainText(/Generated, verified|Verified/);
});

test("a rejected example is repaired once the checker's message is fed back", async ({ page, request }) => {
  await generate(page, "repair", request);
  await expect(page.getByTestId("example-status")).toHaveText("Generated, dry-run passed");
  await page.getByTestId("attempts").locator("summary").click();
  await expect(page.getByTestId("attempts")).toContainText("Attempts (2)");
  await expect(page.getByTestId("attempts")).toContainText("Rejected:");
  await expect(page.getByTestId("attempts")).toContainText("UNRESOLVED_COLUMN");
  const st = await (await request.get(`${MOCK}/__state`)).json();
  expect(st.llmPrompts).toEqual(["generate", "repair-with-error"]);
});

test("a command is unchecked: said plainly, SQL visible, no 'rejected' alarm", async ({ page, request }) => {
  await generate(page, "ddl", request);
  await expect(page.getByTestId("example-status")).toHaveText("Generated, unverified");
  await expect(page.getByTestId("example-unchecked")).toContainText("Nothing checked this");
  await expect(page.getByTestId("example-sql")).toBeVisible();
  await expect(page.getByTestId("example-unverified")).toHaveCount(0);
  await page.getByTestId("attempts").locator("summary").click();
  await expect(page.getByTestId("attempts")).toContainText("Not dry-run:");
  await expect(page.getByTestId("attempts")).not.toContainText("Rejected");
  expect((await (await request.get(`${MOCK}/__state`)).json()).explainRuns).toBe(0); // never EXPLAINed
});

test("a query the checker rejects three times is collapsed behind a warning", async ({ page, request }) => {
  await generate(page, "alwaysbad", request);
  await expect(page.getByTestId("example-status")).toHaveText("Generated, unverified");
  await expect(page.getByTestId("example-sql")).toBeHidden();
  await expect(page.getByTestId("example-unverified")).toContainText("rejected every attempt");
  await page.getByTestId("example-unverified").locator("summary").click();
  await expect(page.getByTestId("example-sql")).toBeVisible();
});

test("a model that returns no SQL gives a clear error", async ({ page, request }) => {
  await generate(page, "never", request);
  await expect(page.getByTestId("error")).toContainText("did not return an example");
  await expect(page.getByTestId("example")).toHaveCount(0);
});

test("when the files do not cover the request, it says so and offers Answer mode", async ({ page, request }) => {
  await generate(page, "notcovered", request);
  await expect(page.getByTestId("error")).toContainText("do not show how to do that");
  await expect(page.getByTestId("example")).toHaveCount(0);
  await page.getByTestId("try-answer").click();
  await expect(page.getByTestId("answer")).toBeVisible();
});

test("SQL from the model is shown as text, never run", async ({ page, request }) => {
  await generate(page, "xss", request);
  await expect(page.getByTestId("example-sql")).toContainText("<script>");
  expect(await page.locator("[data-testid=example] script").count()).toBe(0);
  expect(await page.evaluate(() => (window as unknown as { __pwned?: number }).__pwned)).toBeUndefined();
});

test("save as candidate: saved once, listed, with its status and sources", async ({ page, request }) => {
  await generate(page, "pass", request);
  await page.getByTestId("name").fill("Ann");
  await page.getByTestId("save-candidate").click();
  await expect(page.getByTestId("saved")).toContainText("Saved.");
  expect((await (await request.get(`${MOCK}/__state`)).json()).candidates).toBe(1);
  // The same example again is not a second row.
  await page.getByTestId("regenerate").click();
  await expect(page.getByTestId("save-candidate")).toBeEnabled();
  await page.getByTestId("save-candidate").click();
  await expect(page.getByTestId("saved")).toContainText("Already saved");
  await page.goto(`${APPS.full.url}/candidates`);
  const card = page.getByTestId("candidate");
  await expect(card).toHaveCount(1);
  await expect(card).toContainText(REQ);
  await expect(page.getByTestId("candidate-status")).toHaveText("Generated, dry-run passed");
  await expect(card.getByRole("link", { name: SQL_FILE })).toHaveAttribute("href", `/docs/${SQL_FILE}`);
  await expect(card).toContainText("saved by Ann");
  // Filter by cited file.
  await page.goto(`${APPS.full.url}/candidates?file=${encodeURIComponent(SQL_FILE)}`);
  await expect(page.getByTestId("candidate")).toHaveCount(1);
  await page.goto(`${APPS.full.url}/candidates?file=${encodeURIComponent("AGENTS.md")}`);
  await expect(page.getByTestId("candidate")).toHaveCount(0);
});

test("a doc links to the examples generated from it", async ({ page }) => {
  await page.goto(`${APPS.full.url}/docs/AGENTS.md`);
  await page.getByTestId("candidates-link").click();
  await expect(page).toHaveURL(/\/candidates\?file=AGENTS\.md$/);
  await expect(page.getByTestId("file-filter")).toContainText("AGENTS.md");
});

test("the server decides the status and requires sources", async ({ request }) => {
  const url = `${APPS.full.url}/api/candidates`;
  // The client claims 'dry-run passed' for a statement that cannot be checked.
  const ok = await request.post(url, {
    data: { request: "r", sql: "DROP TABLE x", attempts: 1, status: "dry-run passed", sources: [SQL_FILE] },
  });
  expect(ok.status()).toBe(201);
  const list = await (await request.get(`${APPS.full.url}/candidates`)).text();
  expect(list).toContain("Generated, unverified");
  expect(list).not.toContain("Generated, dry-run passed");
  // No sources, and sources that are not in the catalog, are refused.
  for (const sources of [[], ["README.md"], ["../../etc/passwd"]]) {
    const r = await request.post(url, { data: { request: "r2", sql: "SELECT 1", attempts: 1, sources } });
    expect(r.status(), JSON.stringify(sources)).toBe(400);
  }
  const bad = await request.post(url, { data: { request: "r3", sql: "SELECT 1", attempts: 9, sources: [SQL_FILE] } });
  expect(bad.status()).toBe(400);
});

test("writes from another site are refused", async ({ request }) => {
  const evil = { origin: "https://evil.example" };
  for (const [path, data] of [
    ["/api/example", { request: "x" }],
    ["/api/candidates", { request: "x", sql: "SELECT 1", attempts: 1, sources: [SQL_FILE] }],
  ] as const) {
    const r = await request.post(`${APPS.full.url}${path}`, { data, headers: evil });
    expect(r.status(), path).toBe(403);
  }
  expect((await (await request.get(`${MOCK}/__state`)).json()).candidates).toBe(0);
});

test("Example mode needs an LLM, and an empty request sends nothing", async ({ page, request }) => {
  await page.goto(APPS.nollm.url);
  await expect(page.getByRole("radio", { name: "Example" })).toBeDisabled();
  const r = await request.post(`${APPS.nollm.url}/api/example`, { data: { request: "x" } });
  expect(r.status()).toBe(400);
  await generate(page, "pass");
  const e = await request.post(`${APPS.full.url}/api/example`, { data: { request: "  " } });
  expect(e.status()).toBe(400);
});

test("Candidates and an example result fit a phone", async ({ page, request }) => {
  await page.setViewportSize({ width: 412, height: 915 });
  await generate(page, "pass", request);
  await expect(page.getByTestId("example-status")).toBeVisible();
  const over = () => page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(await over()).toBeLessThanOrEqual(0);
  await page.goto(`${APPS.full.url}/candidates`);
  expect(await over()).toBeLessThanOrEqual(0);
});

test("while it works, the page lists each step with a spinner on the current one", async ({ page, request }) => {
  await request.get(`${MOCK}/__control?answerDelayMs=1500&exampleMode=repair`);
  await generate(page);
  const steps = page.getByTestId("steps");
  await expect(steps).toBeVisible();
  await expect(steps).toContainText("Searching the docs for the closest examples");
  await expect(steps.locator(".spinner")).toHaveCount(1);
  await expect(steps.locator(".step")).toHaveCount(1); // only the running step is shown
  await expect(steps.locator("#step-log")).toBeHidden();
  await expect(steps).toContainText("Writing the SQL with");
  await expect(steps).toContainText("Checking the SQL against Zetaris");
  await expect(steps).toContainText("Zetaris rejected attempt 1");
  await steps.getByTestId("steps-toggle").click();
  await expect(steps.locator("#step-log")).toBeVisible();
  await expect(steps.locator("#step-log .failed")).toHaveCount(1);
  await expect(steps).toContainText("Fixing the SQL with");
  await expect(page.getByTestId("example-status")).toHaveText("Generated, dry-run passed");
  await expect(page.getByTestId("steps")).toHaveCount(0);
});
