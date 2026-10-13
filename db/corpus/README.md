# Demo corpus: Aozora Bunko texts

The `*.txt` files in this directory are the documents indexed by the full-text
search demo. Each one is a short Japanese literary work from
[Aozora Bunko](https://www.aozora.gr.jp/), fetched from the
[aozorahack/aozorabunko_text](https://github.com/aozorahack/aozorabunko_text)
mirror on GitHub and reduced to plain prose by `Aozora::TextCleaner`
(`lib/aozora/text_cleaner.rb`).

All of the works are in the public domain in Japan: their authors died more
than 70 years ago. Aozora Bunko asks that the colophon of each file (the source
edition and the names of the volunteers who typed and proofread it) stays with
the text when it is redistributed, so it is kept verbatim in each file's front
matter instead of being stripped with the rest of the markup.

## File format

Every file is UTF-8 with LF line endings and starts with a YAML front matter
block (`title`, `author`, `card_id`, `card_url`, `source_url`, `colophon`)
between `---` lines. The body that follows holds exactly one paragraph per line.
Ruby readings (`《…》`), ruby start markers (`｜`), editorial notes (`［＃…］`)
are removed, gaiji placeholders (`※` plus a note with the JIS X 0213 code) are
replaced with the real character, lines shorter than eight
characters (chapter numerals, headings, one-word replies) and punctuation-only
section dividers are dropped, and only modern-script, modern-kana (新字新仮名)
editions are used.

## Regenerating

```sh
bin/rails corpus:fetch
```

The task reads `works.yml`, looks up each card's text directory in the mirror
through the GitHub contents API, downloads the `_ruby_` text, verifies the
title and author lines against `works.yml`, and rewrites `<card_id>.txt`. It is
idempotent: unchanged works are left alone and works removed from `works.yml`
are deleted. The anonymous GitHub API limit is ample for a single run; set
`GITHUB_TOKEN` if you run it repeatedly.

## Works

| Title | Author | Card | Paragraphs |
| --- | --- | --- | ---: |
| 注文の多い料理店 | 宮沢賢治 | [card43754](https://www.aozora.gr.jp/cards/000081/card43754.html) | 149 |
| セロ弾きのゴーシュ | 宮沢賢治 | [card470](https://www.aozora.gr.jp/cards/000081/card470.html) | 195 |
| よだかの星 | 宮沢賢治 | [card473](https://www.aozora.gr.jp/cards/000081/card473.html) | 66 |
| やまなし | 宮沢賢治 | [card46605](https://www.aozora.gr.jp/cards/000081/card46605.html) | 79 |
| 羅生門 | 芥川龍之介 | [card127](https://www.aozora.gr.jp/cards/000879/card127.html) | 37 |
| 鼻 | 芥川龍之介 | [card42](https://www.aozora.gr.jp/cards/000879/card42.html) | 44 |
| 蜘蛛の糸 | 芥川龍之介 | [card92](https://www.aozora.gr.jp/cards/000879/card92.html) | 15 |
| トロッコ | 芥川龍之介 | [card43016](https://www.aozora.gr.jp/cards/000879/card43016.html) | 41 |
| 走れメロス | 太宰治 | [card1567](https://www.aozora.gr.jp/cards/000035/card1567.html) | 74 |
| 山月記 | 中島敦 | [card624](https://www.aozora.gr.jp/cards/000119/card624.html) | 25 |
| 檸檬 | 梶井基次郎 | [card424](https://www.aozora.gr.jp/cards/000074/card424.html) | 30 |
| ごん狐 | 新美南吉 | [card628](https://www.aozora.gr.jp/cards/000121/card628.html) | 71 |
| 手袋を買いに | 新美南吉 | [card637](https://www.aozora.gr.jp/cards/000121/card637.html) | 49 |
| 夢十夜 | 夏目漱石 | [card799](https://www.aozora.gr.jp/cards/000148/card799.html) | 176 |
| 高瀬舟 | 森鴎外 | [card45245](https://www.aozora.gr.jp/cards/000129/card45245.html) | 36 |
| 赤い蝋燭と人魚 | 小川未明 | [card54372](https://www.aozora.gr.jp/cards/001475/card54372.html) | 77 |

16 works, 1,164 paragraphs in total.
