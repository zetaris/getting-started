import { expect, test } from "@playwright/test";
import { APPS, MOCK } from "../support/env.ts";

const Q = "How do I register a REST source?";
const PARAPHRASE = "What are the steps to register a REST API source?";

test.beforeEach(async ({ request }) => {
  await request.get(`${MOCK}/__control?reset=1`);
});

async function askAnswer(page: import("@playwright/test").Page, q = Q) {
  await page.goto(APPS.full.url);
  await page.getByLabel("Answer").check({ force: true });
  await page.getByTestId("question").fill(q);
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("answer")).toBeVisible();
}

test("an answer can be pinned once; pinning it again says so", async ({ page, request }) => {
  await askAnswer(page);
  await page.getByTestId("name").fill("Ann");
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toContainText("Pinned.");
  expect((await (await request.get(`${MOCK}/__state`)).json()).pins).toBe(1);
  // Ask again, pin again: the same question and answer is one pin.
  await askAnswer(page);
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toContainText("already pinned");
  expect((await (await request.get(`${MOCK}/__state`)).json()).pins).toBe(1);
});

test("the Pinned page lists the pin; a like is counted and survives a reload", async ({ page }) => {
  await askAnswer(page);
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toBeVisible();
  await page.goto(`${APPS.full.url}/pins`);
  const card = page.getByTestId("pin-card");
  await expect(card).toHaveCount(1);
  await expect(card).toContainText(Q);
  await expect(page.getByTestId("pin-likes")).toHaveText("0 likes");
  await card.getByTestId("like").click();
  await expect(card.getByTestId("likes")).toHaveText("1");
  await page.reload();
  await expect(page.getByTestId("pin-likes")).toHaveText("1 like");
  await expect(page.getByTestId("like")).toContainText("Liked"); // this browser remembers its like
});

test("pin, like twice, ask a paraphrase: the pin is shown first with its likes, and using it calls no model", async ({ page, request }) => {
  await askAnswer(page);
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toBeVisible();
  const list = await (await request.get(`${APPS.full.url}/pins`)).text();
  const pinId = list.match(/[0-9a-f]{64}/)![0];
  for (const who of ["Ann", "Bob"]) {
    const r = await request.post(`${APPS.full.url}/api/pin-event`, { data: { pinId, kind: "like", who } });
    expect(r.status()).toBe(200);
  }
  const runsBefore = (await (await request.get(`${MOCK}/__state`)).json()).answerRuns;
  await page.goto(APPS.full.url);
  await expect(page.getByLabel("Answer")).toBeChecked(); // the remembered mode, restored once the page is live
  await page.getByLabel("Search only").check({ force: true });
  await expect(page.getByLabel("Search only")).toBeChecked();
  await page.getByTestId("question").fill(PARAPHRASE);
  await page.getByTestId("submit").click();
  const past = page.getByTestId("past-answer");
  await expect(past).toHaveCount(1);
  await expect(past).toContainText(Q);
  await expect(past.getByTestId("likes")).toHaveText("2");
  await expect(page.getByTestId("stale")).toHaveCount(0);
  await past.getByTestId("use").click();
  await expect(page.getByTestId("used-answer")).toContainText("CREATE LIGHTNING REST TABLE");
  expect((await (await request.get(`${MOCK}/__state`)).json()).answerRuns).toBe(runsBefore);
  // Using it is logged as an event (a 'use'), so the Pinned page shows it.
  await expect.poll(async () => (await (await request.get(`${MOCK}/__state`)).json()).events).toBe(3);
});

test("an unrelated question shows no past answers", async ({ page }) => {
  await askAnswer(page);
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toBeVisible();
  await page.getByTestId("question").fill("What is the capital of France?");
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("source").first()).toBeVisible();
  await expect(page.getByTestId("past")).toHaveCount(0);
});

test("a pin is flagged when a file it cites has changed", async ({ page, request }) => {
  await askAnswer(page);
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toBeVisible();
  await page.goto(`${APPS.full.url}/pins`);
  await expect(page.getByTestId("stale")).toHaveCount(0);
  await request.get(`${MOCK}/__control?bumpSha=1`); // the catalog now has newer hashes
  await page.reload();
  await expect(page.getByTestId("stale")).toContainText("has changed");
});

test("writes from another site are refused", async ({ request }) => {
  const evil = { origin: "https://evil.example" };
  for (const [path, data] of [
    ["/api/pins", { question: "q", answer: "a", sources: [] }],
    ["/api/pin-event", { pinId: "0".repeat(64), kind: "like" }],
    ["/api/ask", { question: Q, mode: "search" }],
  ] as const) {
    const r = await request.post(`${APPS.full.url}${path}`, { data, headers: evil });
    expect(r.status(), path).toBe(403);
  }
  expect((await (await request.get(`${MOCK}/__state`)).json()).pins).toBe(0);
});

test("bad pin input is refused with a clear message", async ({ request }) => {
  const r = await request.post(`${APPS.full.url}/api/pins`, { data: { question: "", answer: "" } });
  expect(r.status()).toBe(400);
  const e = await request.post(`${APPS.full.url}/api/pin-event`, { data: { pinId: "0".repeat(64), kind: "like" } });
  expect(e.status()).toBe(404);
});

test("model output cannot run script: raw HTML is shown as text, unsafe links are dropped", async ({ page, request }) => {
  await request.get(`${MOCK}/__control?xss=1`);
  const dialogs: string[] = [];
  page.on("dialog", (d) => (dialogs.push(d.message()), d.dismiss()));
  await askAnswer(page);
  const answer = page.getByTestId("answer");
  await expect(answer).toContainText("bold ok");
  await expect(answer).toContainText("<script>"); // visible as text
  expect(await answer.locator("script, img").count()).toBe(0);
  expect(await answer.locator("a[href^='javascript']").count()).toBe(0);
  expect(await page.evaluate(() => (window as unknown as { __pwned?: number }).__pwned)).toBeUndefined();
  expect(dialogs).toEqual([]);
  // The same answer, pinned and shown on the Pinned page, is just as inert.
  await page.getByTestId("pin").click();
  await expect(page.getByTestId("pinned")).toBeVisible();
  await page.goto(`${APPS.full.url}/pins`);
  await page.getByText("Answer", { exact: true }).click();
  expect(await page.locator("article script, article img").count()).toBe(0);
  expect(await page.evaluate(() => (window as unknown as { __pwned?: number }).__pwned)).toBeUndefined();
});

test("the Pinned page fits a phone", async ({ page }) => {
  // Not in the phone project file, so set the size here.
  await page.setViewportSize({ width: 412, height: 915 });
  await page.goto(`${APPS.full.url}/pins`);
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(0);
});
