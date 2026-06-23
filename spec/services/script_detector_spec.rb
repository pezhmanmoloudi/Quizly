require "rails_helper"

RSpec.describe ScriptDetector, type: :service do
  describe ".call" do
    context "Latin / default" do
      it "returns :latin for an English string" do
        expect(described_class.call("elephant")).to eq(:latin)
      end

      it "returns :latin for an empty string" do
        expect(described_class.call("")).to eq(:latin)
      end

      it "returns :latin for whitespace only" do
        expect(described_class.call("   ")).to eq(:latin)
      end

      it "returns :latin for digits and punctuation only" do
        expect(described_class.call("123!@#")).to eq(:latin)
      end

      it "returns :latin for German (Latin-extended) string" do
        expect(described_class.call("Schönheit")).to eq(:latin)
      end
    end

    context "RTL scripts" do
      it "returns :rtl for an Arabic string" do
        expect(described_class.call("مرحبا")).to eq(:rtl)
      end

      it "returns :rtl for a Persian (Farsi) string" do
        expect(described_class.call("فیل")).to eq(:rtl)
      end

      it "returns :rtl for a Hebrew string" do
        expect(described_class.call("שלום")).to eq(:rtl)
      end

      it "returns :rtl for Kurdish Sorani (uses Arabic script)" do
        expect(described_class.call("ئێمە")).to eq(:rtl)
      end
    end

    context "Cyrillic" do
      it "returns :cyrillic for a Russian string" do
        expect(described_class.call("привет")).to eq(:cyrillic)
      end

      it "returns :cyrillic for a Ukrainian string" do
        expect(described_class.call("привіт")).to eq(:cyrillic)
      end
    end

    context "CJK" do
      it "returns :cjk for Chinese characters" do
        expect(described_class.call("你好")).to eq(:cjk)
      end

      it "returns :cjk for Japanese hiragana" do
        expect(described_class.call("こんにちは")).to eq(:cjk)
      end

      it "returns :cjk for Japanese katakana" do
        expect(described_class.call("コンピュータ")).to eq(:cjk)
      end
    end

    context "Devanagari" do
      it "returns :devanagari for a Hindi string" do
        expect(described_class.call("नमस्ते")).to eq(:devanagari)
      end
    end

    context "Greek" do
      it "returns :greek for a Greek string" do
        expect(described_class.call("γεια")).to eq(:greek)
      end
    end

    context "Thai" do
      it "returns :thai for a Thai string" do
        expect(described_class.call("สวัสดี")).to eq(:thai)
      end
    end
  end

  describe ".for_lang" do
    it "returns :rtl for 'fa' (Persian)" do
      expect(described_class.for_lang("fa")).to eq(:rtl)
    end

    it "returns :rtl for 'ar' (Arabic)" do
      expect(described_class.for_lang("ar")).to eq(:rtl)
    end

    it "returns :rtl for 'ckb' (Kurdish Sorani)" do
      expect(described_class.for_lang("ckb")).to eq(:rtl)
    end

    it "returns :rtl for 'he' (Hebrew)" do
      expect(described_class.for_lang("he")).to eq(:rtl)
    end

    it "returns :cyrillic for 'ru' (Russian)" do
      expect(described_class.for_lang("ru")).to eq(:cyrillic)
    end

    it "returns :cjk for 'zh' (Chinese)" do
      expect(described_class.for_lang("zh")).to eq(:cjk)
    end

    it "returns :devanagari for 'hi' (Hindi)" do
      expect(described_class.for_lang("hi")).to eq(:devanagari)
    end

    it "returns :greek for 'el' (Greek)" do
      expect(described_class.for_lang("el")).to eq(:greek)
    end

    it "returns :latin for 'en' (English)" do
      expect(described_class.for_lang("en")).to eq(:latin)
    end

    it "returns :latin for 'de' (German)" do
      expect(described_class.for_lang("de")).to eq(:latin)
    end

    it "returns :latin for blank string" do
      expect(described_class.for_lang("")).to eq(:latin)
    end

    it "returns :latin for an unknown code" do
      expect(described_class.for_lang("xx")).to eq(:latin)
    end
  end
end
