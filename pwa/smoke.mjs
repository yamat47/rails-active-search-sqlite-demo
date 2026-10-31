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

  await page.goto(`${origin}/?q=callbacks`);
  await page.waitForSelector("#strategy-trigram .hit", { timeout: 60_000 });
  const counts = await page.$$eval(".column-count", (nodes) => nodes.map((node) => node.textContent.trim()));
  console.log(`Counts for callbacks: ${JSON.stringify(counts)}`);
  if (counts.length !== 3) fail(`expected three columns, got ${counts.length}`);
  const hits = counts.map((count) => Number.parseInt(count, 10));
  if (!hits.every((count) => count > 0)) fail(`expected hits in every column, got ${JSON.stringify(hits)}`);
  if (hits[1] < hits[0]) fail(`porter should find at least what unicode61 finds, got ${JSON.stringify(hits)}`);

  const marks = await page.$$eval("#strategy-porter mark", (nodes) => nodes.map((node) => node.textContent.toLowerCase()));
  if (!marks.some((mark) => mark.startsWith("callback"))) fail(`expected a highlighted callback, got ${JSON.stringify(marks.slice(0, 5))}`);

  // The form itself, through Turbo and the Stimulus controller: only the query reaches the URL.
  await page.fill(".search-input", "validate");
  await page.click(".search-submit");
  await page.waitForURL((url) => url.searchParams.get("q") === "validate", { timeout: 60_000 });
  const search = new URL(page.url()).search;
  console.log(`URL after submitting the form: ${search}`);
  if (search !== "?q=validate") fail(`expected ?q=validate, got ${search}`);

  // The explanation page, with its playground filled from the URL, through the same worker.
  await page.goto(`${origin}/tokenizers?text=you+need+to+register+callbacks&q=callba`);
  await page.waitForSelector("#outcome-trigram .verdict-hit", { timeout: 60_000 });
  const verdicts = await page.$$eval(".outcome .verdict", (nodes) => nodes.map((node) => node.textContent.trim()));
  console.log(`Playground verdicts for callba: ${JSON.stringify(verdicts)}`);
  if (verdicts.join() !== "no hit,no hit,a hit") fail(`expected only trigram to match callba, got ${JSON.stringify(verdicts)}`);
  const rows = (await page.$$(".comparison-row")).length;
  const bars = (await page.$$(".comparison-bar")).length;
  if (rows === 0 || bars !== rows * 3) fail(`expected three bars per sample query, got ${bars} bars for ${rows} queries`);

  console.log(process.exitCode ? "Smoke test failed." : "Smoke test passed.");
} catch (error) {
  fail(error.stack || String(error));
  // The worker's own console is not visible from the page, but the launcher mirrors its progress
  // and output into the DOM, which is the best account of a boot that did not finish.
  const page = browser && (await browser.contexts()[0]?.pages()[0]);
  if (page) {
    for (const id of ["boot-message", "boot-console-output"]) {
      const text = await page.$eval(`#${id}`, (node) => node.textContent).catch(() => null);
      if (text) console.log(`[launcher ${id}] ${text.trim().slice(-2000)}`);
    }
  }
} finally {
  await browser?.close();
  preview.kill();
  // Whatever is still open (the preview server's pipe, a worker Chromium left), the verdict is in.
  process.exit(process.exitCode || 0);
}
