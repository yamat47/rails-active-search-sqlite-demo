# Rails Active Search on SQLite FTS5, searching the Rails Guides in the browser

A demo of [Active Search](https://github.com/basecamp/rails-active_search), the search framework
37signals announced at Rails World 2026, on its SQLite FTS5 adapter. The sections of the Rails
Guides are indexed three times, each with a different FTS5 tokenizer, and one page shows the three
result lists side by side for the same query.

The page is published at [rails-active-search.yamat47.me](https://rails-active-search.yamat47.me/).
It is this Rails application compiled to WebAssembly with [wasmify-rails](https://github.com/palkan/wasmify-rails)
and served from GitHub Pages, so there is no application server: Rails, Active Search and SQLite
all run inside your browser.

## What it shows

The three indexes differ in one line of their migration, the FTS5 tokenizer, which is the one
knob the Active Search README points at for SQLite ("`company` does not find `companies`"):

| Column | Migration (db/migrate) | What a query matches |
| --- | --- | --- |
| unicode61, as generated | `create_virtual_table :section_documents_fts, :fts5, [ "title", "body" ]` | the word as written; `callback` is not `callbacks`, and `has_many` is the two words `has` and `many` |
| porter | `create_virtual_table :porter_section_documents_fts, :fts5, [ "title", "body", "tokenize='porter'" ]` | the stem; `validate`, `validation` and `validations` are one token, and so are a few words that only look alike |
| trigram | `create_virtual_table :trigram_section_documents_fts, :fts5, [ "title", "body", "tokenize='trigram'" ]` | any three or more characters, inside words too; `deprecat` and `find_b` match, `ca` matches nothing |

Over the 1,505 sections of the 48 guides, for example:

| Query | unicode61 | porter | trigram | Why |
| --- | ---: | ---: | ---: | --- |
| `callbacks` | 67 | 85 | 67 | porter also finds the sections that only say "callback" |
| `validate` | 36 | 131 | 57 | porter stems it to `valid`, as it does `validation`, `validations` and `valid` |
| `deprecat` | 0 | 0 | 34 | not a word, so only a substring match can find `deprecated` and `deprecation` |
| `has_many` | 35 | 35 | 29 | unicode61 and porter read it as the phrase `has many`, which prose contains too |
| `N+1` | 12 | 12 | 5 | the same, with `n` and `1` |

Each column also prints the FTS5 tokens of the query (through a temporary FTS5 table and
`fts5vocab`), which is usually where the explanation is, and every hit links to its section on
guides.rubyonrails.org.

[The page at /tokenizers](https://rails-active-search.yamat47.me/tokenizers) explains the
difference for a reader who knows Rails but not tokenizers: how a search matches tokens rather than
text, one sentence drawn as each tokenizer cuts it, the hit counts above as bars, and a playground
that takes any text and query and shows what each tokenizer makes of them and whether FTS5 calls it
a hit (through a temporary table built with that tokenizer, with the query passed as Active Search
passes it).

## How it is built

- `config/search.rb` declares the three indexes over `Section`; `app/models/section.rb` connects them with `has_search index:`, inline rather than through Active Job so a seed run or a test sees the index at once. `SearchStrategy` runs one query against all three.
- `rails generate active_search:document` wrote the three document classes and migrations; the only hand edit is the `tokenize=` option in two of them.
- `db/corpus/` holds the guides split into sections, one YAML file per guide, fetched from rails/rails at the tag the application runs on (see [its README](db/corpus/README.md) for the split and the licence); `db/seeds.rb` loads and indexes them in batches.
- In the browser, wasmify-rails runs the application in a Service Worker on ruby.wasm and talks to the official [sqlite-wasm](https://sqlite.org/wasm) build through its `sqlite3_wasm` Active Record adapter. The database is not seeded in the browser: CI builds it with the native `sqlite3` gem and ships the file, which `pwa/database.js` fetches into sqlite-wasm at start. `config/environments/wasm.rb` is the production configuration with Active Job inline, which is all Active Search needs.

## Development

Everything runs in Docker; only Docker itself needs to be installed. The image carries the
Wasm toolchain (wasi-sdk, binaryen, wasi-vfs, wasmtime) because `ruby_wasm` cannot download it
for Linux on Apple Silicon.

```sh
make serve          # prepare and seed the database, serve the app at http://localhost:3000/
make test           # bin/rails test
make lint           # rubocop and actionlint
make wasm           # compile the app to pwa/public/app.wasm, build the demo database and the static site into pwa/dist
make wasm-serve     # serve pwa/dist at http://localhost:3000/ to try the browser build
make wasm-verify    # boot the compiled Rails app under wasmtime
```

`make wasm` compiles CRuby to WebAssembly the first time, which takes a while; a Docker volume
keeps the `build/` directory for later runs. The compiled application is about 84 MB, 24 MB over
the wire, plus the database; `pwa/smoke.mjs` boots the built site in headless Chromium and runs a
search through it, which CI does before every deploy.

The page is built and released to GitHub Pages by GitHub Actions when `main` is updated. The
actions and the agent skills under `.claude/skills/` come from [yamat47/github-toolkit](https://github.com/yamat47/github-toolkit).

## Notes

- Active Search is alpha software (`rails-active_search` 0.1.0, `rails >= 8.1`); its API may change. This repository pins `~> 0.1` and lets Dependabot propose the bumps.
- Active Search has no query syntax of its own: it passes a plain word through, quotes anything else as a phrase, and hands the result to FTS5. So `has_many` reaches FTS5 as one bareword, which unicode61 then splits into the phrase `has many`, and `N+1` reaches it as the phrase `"N+1"`, which each tokenizer splits its own way.
- FTS5's bm25 rank is negative, and Active Search sorts SQLite results ascending (best first).
- The Rails Guides are © the Rails contributors, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
