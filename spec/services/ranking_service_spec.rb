require "rails_helper"

RSpec.describe RankingService, type: :service do
  def call(candidates:, q:, lang: "")
    described_class.call(q:, lang:, candidates:)
  end

  describe ".call" do
    context "empty input" do
      it "returns [] when candidates is empty" do
        expect(call(candidates: [], q: "ele")).to eq([])
      end
    end

    context "exact match bonus" do
      it "places the exact-matching candidate first regardless of position in input" do
        results = call(candidates: %w[elaborate elephant ele], q: "ele")
        expect(results.first).to eq("ele")
      end

      it "is case-insensitive for exact matching" do
        results = call(candidates: %w[ELEPHANT Ele elaborate], q: "ele")
        expect(results.first).to eq("Ele")
      end
    end

    context "prefix match bonus" do
      it "ranks a prefix-matching candidate above a non-prefix candidate of equal script" do
        results = call(candidates: %w[selection elephant], q: "ele", lang: "en")
        expect(results.first).to eq("elephant")
      end
    end

    context "script match bonus — lang=fa (Persian)" do
      it "ranks an Arabic-script candidate above a Latin-script candidate when both lack prefix match" do
        # Neither "world" nor "جهان" starts with "زز" — no prefix bonus; script bonus decides
        results = call(candidates: %w[world جهان], q: "زز", lang: "fa")
        expect(results.first).to eq("جهان")
      end

      it "still includes the non-matching-script candidate in results" do
        results = call(candidates: %w[world جهان], q: "زز", lang: "fa")
        expect(results).to include("world")
      end

      it "lets prefix match override script bonus when the query is Latin" do
        # User typed "fi" (Latin) — "fil" prefix-matches (+50) vs "فیل" script-matches (+30)
        # The prefix signal is stronger, so "fil" ranks first
        results = call(candidates: %w[fil فیل], q: "fi", lang: "fa")
        expect(results.first).to eq("fil")
      end
    end

    context "script match bonus — lang=en (English)" do
      it "ranks a Latin-script candidate above an Arabic-script candidate when neither prefix-matches" do
        results = call(candidates: %w[فیل elephant], q: "zzz", lang: "en")
        expect(results.first).to eq("elephant")
      end

      it "ranks a Latin-script candidate above an Arabic-script candidate with prefix match" do
        results = call(candidates: %w[فیل elephant], q: "el", lang: "en")
        expect(results.first).to eq("elephant")
      end
    end

    context "script match bonus — lang=ckb (Kurdish Sorani)" do
      it "gives script bonus to an Arabic-script candidate" do
        latin    = call(candidates: %w[ئێمە hello], q: "h",   lang: "ckb")
        arabic   = call(candidates: %w[ئێمە hello], q: "ئێ",  lang: "ckb")
        expect(arabic.first).to eq("ئێمە")
      end
    end

    context "script match bonus — lang=ru (Russian)" do
      it "gives script bonus to a Cyrillic candidate" do
        results = call(candidates: %w[привет hello], q: "п", lang: "ru")
        expect(results.first).to eq("привет")
      end
    end

    context "blank lang — no script bias" do
      it "does not apply script bonus when lang is blank" do
        # Both should get prefix bonus; order is by length tiebreaker
        results = call(candidates: %w[فیل fil], q: "fi", lang: "")
        # Neither should outrank the other on script grounds — both have lang="" → script_matches? == true
        expect(results).to contain_exactly("فیل", "fil")
      end
    end

    context "tiebreaker" do
      it "ranks shorter string before longer string when scores are equal" do
        results = call(candidates: %w[elaborate elephant elbow], q: "el", lang: "en")
        # All are Latin + prefix match → same score; tiebreak by length
        expect(results.first).to eq("elbow")
      end

      it "ranks alphabetically when length is also equal" do
        results = call(candidates: %w[elbow elbow1 elbow0], q: "el", lang: "")
        # elbow1 and elbow0 same length — alphabetical: elbow0 < elbow1
        expect(results.last).to eq("elbow1")
      end
    end

    context "return type" do
      it "returns an Array<String>, not structs" do
        results = call(candidates: %w[elephant elaborate], q: "ele")
        expect(results).to all(be_a(String))
      end
    end

    context "no regex inside RankingService" do
      it "does not contain Unicode property regex in RankingService source" do
        source = File.read(Rails.root.join("app/services/ranking_service.rb"))
        expect(source).not_to match(/\\p\{/)
      end
    end
  end
end
