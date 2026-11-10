// Screenshots of the running app against a live stack (not the mock), for docs/screenshots.
// Usage: start the app (deno task build && deno task start), then: npm run screenshots
// BASE_URL defaults to http://127.0.0.1:8000. Needs OLLAMA_URL set for the answer shots.
import { chromium, devices } from "@playwright/test";
import { mkdirSync } from "node:fs";

const base = process.env.BASE_URL ?? "http://127.0.0.1:8000";
const out = new URL("../../docs/screenshots/", import.meta.url).pathname;
mkdirSync(out, { recursive: true });
const question = "How do I clone a pipeline?";

const browser = await chromium.launch();
for (const [name, opts] of [["desktop", { viewport: { width: 1280, height: 900 } }], ["phone", { ...devices["Pixel 7"] }]]) {
  const ctx = await browser.newContext({ ...opts, colorScheme: "dark" });
  const page = await ctx.newPage();
  await page.goto(base);
  await page.getByTestId("question").fill(question);
  const answerOn = await page.getByLabel("Answer").isEnabled();
  if (answerOn) await page.getByLabel("Answer").check({ force: true });
  await page.getByTestId("submit").click();
  await page.getByTestId("source").first().waitFor({ timeout: 180_000 });
  if (answerOn) await page.getByTestId("answer").waitFor({ timeout: 180_000 });
  await page.screenshot({ path: `${out}ask-${name}.png`, fullPage: true });
  await page.goto(`${base}/admin`);
  await page.getByTestId("checks").waitFor();
  await page.screenshot({ path: `${out}status-${name}.png`, fullPage: true });
  await ctx.close();
}
await browser.close();
console.log(`wrote screenshots to ${out}`);
