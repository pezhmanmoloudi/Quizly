require "rails_helper"

RSpec.describe SuggestionQuery, type: :service do
  before { allow(DictionaryAdapter).to receive(:fetch).and_return(["hello", "help"]) }

  describe ".call" do
    it "delegates to DictionaryAdapter and returns words" do
      result = described_class.call(q: "hel", lang: "en")
      expect(result).to eq(["hello", "help"])
      expect(DictionaryAdapter).to have_received(:fetch).with(q: "hel", lang: "en", limit: 8)
    end

    it "normalises query to lowercase" do
      described_class.call(q: "HEL", lang: "en")
      expect(DictionaryAdapter).to have_received(:fetch).with(q: "hel", lang: "en", limit: 8)
    end

    it "strips whitespace from query" do
      described_class.call(q: "  hel  ", lang: "en")
      expect(DictionaryAdapter).to have_received(:fetch).with(q: "hel", lang: "en", limit: 8)
    end

    it "falls back to English for unknown language codes" do
      described_class.call(q: "hel", lang: "xx")
      expect(DictionaryAdapter).to have_received(:fetch).with(q: "hel", lang: "en", limit: 8)
    end

    it "falls back to English when lang is blank" do
      described_class.call(q: "hel", lang: "")
      expect(DictionaryAdapter).to have_received(:fetch).with(q: "hel", lang: "en", limit: 8)
    end

    it "accepts valid ISO 639-1 language codes" do
      described_class.call(q: "hal", lang: "de")
      expect(DictionaryAdapter).to have_received(:fetch).with(q: "hal", lang: "de", limit: 8)
    end

    # Caching tests use a local MemoryStore because test env configures :null_store.
    context "caching" do
      let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }
      before { allow(Rails).to receive(:cache).and_return(memory_cache) }

      it "returns cached result on second call without hitting adapter again" do
        described_class.call(q: "hel", lang: "en")
        described_class.call(q: "hel", lang: "en")
        expect(DictionaryAdapter).to have_received(:fetch).once
      end

      it "shares cache across queries with the same 3-character prefix" do
        described_class.call(q: "hel",   lang: "en")
        described_class.call(q: "hell",  lang: "en")
        described_class.call(q: "hello", lang: "en")
        expect(DictionaryAdapter).to have_received(:fetch).once
      end

      it "uses separate cache entries for different languages" do
        described_class.call(q: "hel", lang: "en")
        described_class.call(q: "hel", lang: "fr")
        expect(DictionaryAdapter).to have_received(:fetch).twice
      end
    end
  end
end
