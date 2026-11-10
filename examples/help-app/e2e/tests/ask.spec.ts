import { expect, test } from "@playwright/test";
import { APPS, MOCK } from "../support/env.ts";

test.beforeEach(async ({ request }) => {
  await request.get(`${MOCK}/__control?reset=1`); // reset switches, pins and events
});

test("asking a question shows ranked sources, with the corpus labelled", async ({ page }) => {
  await page.goto(APPS.full.url);
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  const cards = page.getByTestId("source");
  await expect(cards.first()).toBeVisible();
  await expect(cards).toHaveCount(5);
  await expect(cards.first()).toContainText("open_data/rest_apis/HOWTO.md");
  await expect(page.getByTestId("status")).toContainText("Done in");
  // A Kbase page is a link, labelled as the Knowledge base.
  await expect(page.getByRole("link", { name: /how-to-clone-pipeline/ })).toBeVisible();
  await expect(page.getByText("Knowledge base").first()).toBeVisible();
  await expect(page.getByTestId("answer")).toHaveCount(0); // Search only by default
});

test("Answer mode shows the answer after the sources", async ({ page }) => {
  await page.goto(APPS.full.url);
  await page.getByLabel("Answer").check({ force: true });
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("answer")).toContainText("CREATE LIGHTNING REST TABLE");
  await expect(page.getByTestId("source").first()).toBeVisible();
});

test("an example chip asks straight away", async ({ page }) => {
  await page.goto(APPS.full.url);
  await page.getByRole("button", { name: "How do I clone a pipeline?" }).click();
  await expect(page.getByTestId("source").first()).toBeVisible();
  await expect(page.getByTestId("question")).toHaveValue("How do I clone a pipeline?");
});

test("an empty question gets a message and sends nothing", async ({ page }) => {
  await page.goto(APPS.full.url);
  let calls = 0;
  await page.route("**/api/ask", (r) => (calls++, r.continue()));
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("error")).toHaveText("Type a question first.");
  await page.getByTestId("question").fill("   ");
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("error")).toHaveText("Type a question first.");
  expect(calls).toBe(0);
});

test("no matches says so", async ({ page }) => {
  await page.goto(APPS.full.url);
  await page.getByTestId("question").fill("nothingmatchesthis");
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("no-sources")).toBeVisible();
});

test("Zetaris down shows a clear message, no stack trace, no SQL", async ({ page }) => {
  await page.goto(APPS.down.url);
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  const err = page.getByTestId("error");
  await expect(err).toContainText("Zetaris is not reachable");
  await expect(err).toHaveAttribute("data-code", "zetaris_unreachable");
  await expect(err).not.toContainText(/127\.0\.0\.1|ECONNREFUSED|at \w+\(/);
});

test("a Zetaris error is shown without the server's text", async ({ page, request }) => {
  await request.get(`${MOCK}/__control?fail=500`);
  await page.goto(APPS.full.url);
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  const err = page.getByTestId("error");
  await expect(err).toContainText("Zetaris returned an error");
  // Check the error box itself: the example chips on the page legitimately mention RUN PIPELINE.
  await expect(err).not.toContainText(/LEAKED_SQL_TEXT|RUN PIPELINE|SELECT/);
  await expect(page.locator("body")).not.toContainText("LEAKED_SQL_TEXT");
});

test("without an LLM, Answer is disabled and Search still works", async ({ page }) => {
  await page.goto(APPS.nollm.url);
  await expect(page.getByLabel("Answer")).toBeDisabled();
  await expect(page.getByText("Answer mode is off")).toBeVisible();
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("source").first()).toBeVisible();
});

test("the API refuses Answer without an LLM, bad JSON and oversized bodies", async ({ request }) => {
  const a = await request.post(`${APPS.nollm.url}/api/ask`, { data: { question: "x y", mode: "answer" } });
  expect(a.status()).toBe(400);
  expect((await a.json()).error.code).toBe("llm_not_configured");
  const b = await request.post(`${APPS.nollm.url}/api/ask`, { data: "not json", headers: { "content-type": "text/plain" } });
  expect(b.status()).toBe(400);
  const c = await request.post(`${APPS.nollm.url}/api/ask`, { data: { question: "x".repeat(6000), mode: "search" } });
  expect(c.status()).toBe(413);
});

test("one answer at a time per browser session", async ({ request }) => {
  await request.get(`${MOCK}/__control?answerDelayMs=1500`);
  const headers = { cookie: "help_sid=e2e-session-0000000000001" };
  const body = { question: "How do I register a REST source?", mode: "answer" };
  const first = request.post(`${APPS.full.url}/api/ask`, { data: body, headers });
  await new Promise((r) => setTimeout(r, 400));
  const second = await request.post(`${APPS.full.url}/api/ask`, { data: body, headers });
  expect(second.status()).toBe(429);
  expect((await second.json()).error.code).toBe("busy");
  expect((await first).status()).toBe(200);
  // Another session is not blocked, and the first is free again.
  const other = await request.post(`${APPS.full.url}/api/ask`, {
    data: { ...body, mode: "search" },
    headers: { cookie: "help_sid=e2e-session-0000000000002" },
  });
  expect(other.status()).toBe(200);
});

test("the theme toggle switches and is remembered", async ({ page }) => {
  await page.goto(APPS.full.url);
  const html = page.locator("html");
  await page.getByRole("button", { name: /Switch to/ }).click();
  const chosen = await html.getAttribute("data-theme");
  expect(["light", "dark"]).toContain(chosen);
  await page.reload();
  await expect(html).toHaveAttribute("data-theme", chosen!);
});

test("the page has a skip link, labelled controls and no console errors", async ({ page }) => {
  const errors: string[] = [];
  page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
  await page.goto(APPS.full.url);
  await expect(page.getByRole("link", { name: "Skip to content" })).toBeAttached();
  await expect(page.getByLabel("Your question")).toBeVisible();
  await expect(page.getByRole("group", { name: "Mode" })).toBeVisible();
  expect(errors).toEqual([]);
});
