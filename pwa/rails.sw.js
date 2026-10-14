// The Service Worker that is the application server: every request to this origin, apart from
// the launcher and the static files it needs, is handed to Rails running on ruby.wasm.
// Based on the launcher wasmify-rails generates.
import { initRailsVM, Progress, registerSQLiteWasmInterface, RackHandler } from "wasmify-rails";

import { setupSQLiteDatabase } from "./database.js";

let db = null;

const initDB = async (progress) => {
  if (db) return db;

  progress?.updateStep("Loading the search database...");
  db = await setupSQLiteDatabase();
  progress?.updateStep("Search database loaded.");

  return db;
};

let vm = null;

const initVM = async (progress, opts = {}) => {
  if (vm) return vm;

  if (!db) {
    await initDB(progress);
  }

  registerSQLiteWasmInterface(self, db);

  let redirectConsole = true;

  vm = await initRailsVM("/app.wasm", {
    database: { adapter: "sqlite3_wasm" },
    progressCallback: (step) => {
      progress?.updateStep(step);
    },
    outputCallback: (output) => {
      if (!redirectConsole) return;
      progress?.notify(output);
    },
    ...opts,
  });

  // The shipped database already has the schema; this only confirms there is nothing to migrate.
  progress?.updateStep("Preparing the database...");
  vm.eval("ActiveRecord::Tasks::DatabaseTasks.prepare_all");

  redirectConsole = false;

  return vm;
};

const installApp = async () => {
  const progress = new Progress();
  await progress.attach(self);

  try {
    await initDB(progress);
    await initVM(progress);
  } catch (error) {
    // A failed install leaves the launcher waiting forever otherwise; say why on the page.
    progress.updateStep(`Installation failed: ${error?.message || error}`);
    throw error;
  }
};

self.addEventListener("install", (event) => {
  console.log("[rails-web] Install Service Worker");
  event.waitUntil(installApp().then(() => self.skipWaiting()));
});

self.addEventListener("activate", () => {
  console.log("[rails-web] Activate Service Worker");
});

const rackHandler = new RackHandler(initVM, { assumeSSL: true });

// What the network serves: the launcher, its bundled assets, the Wasm module and the database.
// Everything else is a Rails request.
const networkPaths = ["/boot.html", "/boot.js", "/rails.sw.js", "/app.wasm", "/demo.sqlite3"];
const networkPrefixes = ["/pwa-assets/", "/node_modules/", "/@vite", "/@fs/"];

self.addEventListener("fetch", (event) => {
  const { pathname } = new URL(event.request.url);

  if (networkPaths.includes(pathname) || networkPrefixes.some((prefix) => pathname.startsWith(prefix))) {
    event.respondWith(fetch(event.request));
    return;
  }

  event.respondWith(rackHandler.handle(event.request));
});
