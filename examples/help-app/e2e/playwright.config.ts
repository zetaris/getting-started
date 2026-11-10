import { defineConfig, devices } from "@playwright/test";
import { APPS, appEnv } from "./support/env.ts";

const app = (kind: keyof typeof APPS) => ({
  command: "deno task start",
  cwd: "..",
  url: APPS[kind].url,
  env: appEnv(kind),
  reuseExistingServer: false,
  timeout: 60_000,
});

export default defineConfig({
  testDir: "./tests",
  // The mock has shared switches (/__control), so tests run one at a time.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"], ["html", { open: "never", outputFolder: "playwright-report" }]],
  use: { trace: "retain-on-failure", screenshot: "only-on-failure" },
  webServer: [
    {
      command: "node support/mock-zetaris.mjs",
      url: "http://127.0.0.1:8899/api/tags",
      reuseExistingServer: false,
      timeout: 15_000,
    },
    app("full"),
    app("nollm"),
    app("down"),
  ],
  projects: [
    { name: "desktop", use: { ...devices["Desktop Chrome"] }, testIgnore: /phone\.spec\.ts/ },
    { name: "phone", use: { ...devices["Pixel 7"] }, testMatch: /phone\.spec\.ts/ },
  ],
});
