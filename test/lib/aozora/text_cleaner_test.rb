require "test_helper"

module Aozora
  class TextCleanerTest < ActiveSupport::TestCase
    RAW = <<~TEXT
      羅生門
      芥川龍之介

      -------------------------------------------------------
      【テキスト中に現れる記号について】

      《》：ルビ
      （例）下人《げにん》

      ［＃］：入力者注　主に外字の説明や、傍点の位置の指定
      （例）※［＃「てへん＋丑」、第4水準2-12-93］
      -------------------------------------------------------

      ［＃５字下げ］一［＃「一」は中見出し］

      　ある日の暮方の事である。一人の下人《げにん》が、羅生門《らしょうもん》の下で雨やみを待っていた。
      　所々｜丹塗《にぬり》の剥《は》げた円柱に、蟋蟀《きりぎりす》が一匹とまっている。
      　ゆく河の流れは絶えず［＃「絶えず」に傍点］して、しかももとの水にあらず。
      　下人は、聖柄《ひじりづか》の太刀を手に※［＃「てへん＋丑」、第4水準2-12-93］んで立ち上がった。
      　友の袁※［＃「にんべん＋參」、第4水準2-1-79］［＃「袁※［＃「にんべん＋參」、第4水準2-1-79］」に傍点］は大いに驚いた。
      　吉野家の※［＃「土」の下に「口」、U+20BB7］野氏は暖簾を潜った。
      　犬は※［＃「口＋歇」、第4水準2-4-60］々と吠えたてた。
      「はい。」
      　　　　　　　　――――――――――――――――
      ［＃地から１字上げ］（大正四年九月）

      底本：「芥川龍之介全集1」ちくま文庫、筑摩書房
      　　　1986（昭和61）年9月24日第1刷発行
      入力：平山誠、野口英司
      校正：もりみつじゅんじ
      1997年10月29日公開
    TEXT

    setup do
      @result = TextCleaner.call(RAW)
    end

    test "takes the title from the first line and the author from the second" do
      assert_equal "羅生門", @result[:title]
      assert_equal "芥川龍之介", @result[:author]
    end

    test "ignores a subtitle and a translator line when picking the author" do
      result = TextCleaner.call("変身\n或る男の話\nカフカ\n原田義人訳\n\n　本文です。本文です。\n")

      assert_equal "変身", result[:title]
      assert_equal "カフカ", result[:author]
    end

    test "drops the symbol legend fenced by hyphen lines" do
      assert_equal "ある日の暮方の事である。一人の下人が、羅生門の下で雨やみを待っていた。", @result[:paragraphs].first
      assert_empty @result[:paragraphs].grep(/ルビ|（例）/)
    end

    test "strips ruby and the marker that opens a ruby run" do
      assert_includes @result[:paragraphs], "所々丹塗の剥げた円柱に、蟋蟀が一匹とまっている。"
    end

    test "removes editorial notes" do
      assert_includes @result[:paragraphs], "ゆく河の流れは絶えずして、しかももとの水にあらず。"
    end

    test "replaces a gaiji placeholder and its note with the character for the JIS X 0213 code" do
      assert_includes @result[:paragraphs], "下人は、聖柄の太刀を手に扭んで立ち上がった。"
    end

    test "restores a gaiji inside a nested note and removes the outer note" do
      assert_includes @result[:paragraphs], "友の袁傪は大いに驚いた。"
    end

    test "replaces a gaiji placeholder with the character for a UCS code point" do
      assert_includes @result[:paragraphs], "吉野家の𠮷野氏は暖簾を潜った。"
    end

    test "drops a gaiji whose code is not mapped and reports the note" do
      assert_includes @result[:paragraphs], "犬は々と吠えたてた。"
      assert_equal [ "「口＋歇」、第4水準2-4-60" ], @result[:unmapped_gaiji]
    end

    test "maps every code to a single character" do
      TextCleaner::GAIJI.each do |code, character|
        assert_equal 1, character.length, "#{code} should map to one character"
      end
    end

    test "drops lines shorter than eight characters once cleaned" do
      assert_not_includes @result[:paragraphs], "「はい。」"
      assert_not_includes @result[:paragraphs], "一"
      assert_includes @result[:paragraphs], "（大正四年九月）"
    end

    test "drops lines made only of punctuation such as section dividers" do
      assert_not_includes @result[:paragraphs], "――――――――――――――――"
    end

    test "keeps the colophon verbatim from the 底本 line to the end" do
      expected = <<~COLOPHON.chomp
        底本：「芥川龍之介全集1」ちくま文庫、筑摩書房
        　　　1986（昭和61）年9月24日第1刷発行
        入力：平山誠、野口英司
        校正：もりみつじゅんじ
        1997年10月29日公開
      COLOPHON

      assert_equal expected, @result[:colophon]
      assert_empty @result[:paragraphs].grep(/\A(底本|入力|校正)/)
    end

    test "produces the same result for CRLF line endings" do
      assert_equal @result, TextCleaner.call(RAW.gsub("\n", "\r\n"))
    end
  end
end
