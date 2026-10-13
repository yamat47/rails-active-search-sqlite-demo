import sqlite3InitModule from "@sqlite.org/sqlite-wasm";

// The database is built by `bin/rails demo:database` and served next to the page as /demo.sqlite3.
// It is copied into sqlite-wasm's in-memory file system, so it starts over whenever the Service
// Worker is restarted; the demo only reads it.
export const setupSQLiteDatabase = async () => {
  const sqlite3 = await sqlite3InitModule();

  const response = await fetch("/demo.sqlite3");
  if (!response.ok) {
    throw new Error(`Could not load /demo.sqlite3 (${response.status})`);
  }
  const bytes = new Uint8Array(await response.arrayBuffer());
  sqlite3.capi.sqlite3_js_posix_create_file("/demo.sqlite3", bytes);

  const db = new sqlite3.oo1.DB("/demo.sqlite3", "c");
  console.log(
    `SQLite ${sqlite3.version.libVersion}: ${db.selectValue("SELECT count(*) FROM paragraphs")} paragraphs loaded`,
  );
  return db;
};
