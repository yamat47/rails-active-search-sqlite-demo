# Rails Active Search on SQLite FTS5, with Japanese text, in the browser

A demo of [Active Search](https://github.com/basecamp/rails-active_search), the search framework
37signals announced at Rails World 2026, on its SQLite FTS5 adapter. The same 1,164 paragraphs of
16 public-domain short stories are indexed three times, each with a different FTS5 tokenizer, and
one page shows the three result lists side by side for the same query.

The page is published at [rails-active-search.yamat47.me](https://rails-active-search.yamat47.me/).
It is this Rails application compiled to WebAssembly with [wasmify-rails](https://github.com/palkan/wasmify-rails)
and served from GitHub Pages, so there is no application server: Rails, Active Search and SQLite
all run inside your browser.

## What it shows

Japanese is written without spaces, so FTS5's default tokenizer, which splits on spaces and
punctuation, sees a whole clause as one token. The three indexes differ in one line of their
migration (and, for the third, in what is written to it):

| Column | Migration (db/migrate) | Query of 2 chars (ごん) | Word inside a sentence (ゴーシュ) | Word the splitter cuts differently (料理店) |
| --- | --- | ---: | ---: | ---: |
| unicode61, as generated | `create_virtual_table :paragraph_documents_fts, :fts5, [ "body" ]` | 1 | 0 | 0 |
| trigram | `create_virtual_table :trigram_paragraph_documents_fts, :fts5, [ "body", "tokenize='trigram'" ]` | 0 | 67 | 3 |
| words + unicode61 | the generated line, over text split by [TinySegmenter](lib/tiny_segmenter.rb) | 37 | 67 | 0 |

- **unicode61** finds `ごん` only where it stands alone (`「ごん、お前だったのか。」`) and `ゴーシュ` never, because the name is always glued to a particle.
- **trigram** matches any three or more characters anywhere, so it is the one-line fix for Japanese, but a two-character query such as `ごん`, `檸檬` or `手袋` matches nothing at all.
- **words + unicode61** finds short words and keeps bm25 ranking meaningful, at the price of agreeing with the splitter: TinySegmenter reads `西洋料理店` as one word, so the query `料理店` finds nothing, and `泣いた` becomes `泣い` + `た` and matches more than it should.

Each column also prints the FTS5 tokens of the query (through a temporary FTS5 table and
`fts5vocab`), which is usually where the explanation is.

## How it is built

- `config/search.rb` declares the three indexes over `Paragraph`; `app/models/paragraph.rb` connects them with `has_search index:`, inline rather than through Active Job so a seed run or a test sees the index at once. The third index gets its text from a serializer that runs the body through TinySegmenter, and `SearchStrategy` runs the query through the same split.
- `rails generate active_search:document` wrote the three document classes and migrations; the only hand edit is the `tokenize='trigram'` option. Active Search quotes non-ASCII terms as phrases, which is what makes the trigram index match a Japanese query as a substring.
- `lib/tiny_segmenter.rb` is a port of Taku Kudo's TinySegmenter (BSD), a character-level model with no dictionary and no native extension, so it runs under ruby.wasm. MeCab would segment better; it would not run in the browser.
- `db/corpus/` holds the texts, cleaned from [Aozora Bunko](https://www.aozora.gr.jp/) with their colophons kept (see [its README](db/corpus/README.md)); `db/seeds.rb` loads and indexes them in batches.
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
the wire, plus a 3 MB database; `pwa/smoke.mjs` boots the built site in headless Chromium and
runs a search through it, which CI does before every deploy.

The page is built and released to GitHub Pages by GitHub Actions when `main` is updated. The
actions and the agent skills under `.claude/skills/` come from [yamat47/github-toolkit](https://github.com/yamat47/github-toolkit).

## Notes

- Active Search is alpha software (`rails-active_search` 0.1.0, `rails >= 8.1`); its API may change. This repository pins `~> 0.1` and lets Dependabot propose the bumps.
- sqlite-wasm ships FTS5 with the unicode61, porter and trigram tokenizers and no ICU, so the three strategies here are what is available in the browser as well as on a server with the `sqlite3` gem.
- FTS5's bm25 rank is negative, and Active Search sorts SQLite results ascending (best first). On a corpus this small the IDF term rounds to zero for common words, so several hits can share a rank of 0.
