// Opens the built site in headless Chromium, waits for the Service Worker to boot Rails, and
// checks that a search answers through it. Run after `vite build` with `npm run smoke`; the
// preview server is started here so the script is the whole check in CI.
import { spawn } from "node:child_process";
import { chromium } from "playwright";

const port = process.env.PORT || 4173;
const origin = `http://localhost:${port}`;
const bootTimeout = Number(process.env.BOOT_TIMEOUT_MS || 180_000);

// Vite is started as a direct child rather than through npx, so that killing it at the end kills
// the server and not just a wrapper that leaves it (and this process) alive.
const vite = new URL("node_modules/.bin/vite", import.meta.url).pathname;
const preview = spawn(vite, ["preview", "--port", String(port), "--strictPort"], { stdio: ["ignore", "pipe", "inherit"] });
preview.stdout.on("data", (chunk) => process.stdout.write(`[vite] ${chunk}`));

const waitFor = async (url, attempts = 50) => {
  for (let i = 0; i < attempts; i++) {
    try {
      const response = await fetch(url);
      if (response.ok) return;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`${url} did not come up`);
};

const fail = (message) => {
  console.error(`FAIL: ${message}`);
  process.exitCode = 1;
};

let browser;
try {
  await waitFor(`${origin}/boot.html`);
  browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  page.on("console", (message) => console.log(`[browser:${message.type()}] ${message.text()}`));

  console.log("Opening the launcher...");
  await page.goto(`${origin}/boot.html`);
  // The launcher navigates to / once the worker is active; that is the signal Rails is up.
  await page.waitForURL((url) => url.pathname === "/", { timeout: bootTimeout });
  await page.waitForSelector(".search-form", { timeout: 60_000 });
  console.log("Rails answered /.");

  await page.goto(`${origin}/?q=${encodeURIComponent("ごん")}`);
  await page.waitForSelector("#strategy-segmented .hit", { timeout: 60_000 });
  const counts = await page.$$eval(".column-count", (nodes) => nodes.map((node) => node.textContent.trim()));
  console.log(`Counts for ごん: ${JSON.stringify(counts)}`);
  if (counts.length !== 3) fail(`expected three columns, got ${counts.length}`);
  if (!counts[1].startsWith("0 hits")) fail(`trigram should have no hits for ごん, got "${counts[1]}"`);
  if (!counts[2].match(/^\d{2,} hits/)) fail(`segmented should have many hits for ごん, got "${counts[2]}"`);

  const marks = await page.$$eval("#strategy-segmented mark", (nodes) => nodes.map((node) => node.textContent));
  if (!marks.includes("ごん")) fail(`expected a highlighted ごん, got ${JSON.stringify(marks.slice(0, 5))}`);

  console.log(process.exitCode ? "Smoke test failed." : "Smoke test passed.");
} catch (error) {
  fail(error.stack || String(error));
} finally {
  await browser?.close();
  preview.kill();
  // Whatever is still open (the preview server's pipe, a worker Chromium left), the verdict is in.
  process.exit(process.exitCode || 0);
}
