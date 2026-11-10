import { expect, test } from "@playwright/test";
import { APPS } from "../support/env.ts";

test("at phone width nothing scrolls sideways and a question can be asked", async ({ page }) => {
  await page.goto(APPS.full.url);
  await page.getByTestId("question").fill("How do I register a REST source?");
  await page.getByTestId("submit").click();
  await expect(page.getByTestId("source").first()).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(0);
  const box = await page.getByTestId("submit").boundingBox();
  expect(box!.height).toBeGreaterThanOrEqual(40);
});

test("the status page also fits a phone", async ({ page }) => {
  await page.goto(`${APPS.full.url}/admin`);
  await expect(page.getByTestId("check-Zetaris")).toBeVisible();
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  expect(overflow).toBeLessThanOrEqual(0);
});
