require "rails_helper"

RSpec.describe CsvImporter, type: :service do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user, term_language: "en", definition_language: "fa") }

  def upload(csv_content, filename: "cards.csv")
    file = Tempfile.new([filename, ".csv"])
    file.write(csv_content)
    file.rewind
    ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: filename, type: "text/csv")
  end

  describe ".parse" do
    it "parses a CSV with front/back headers" do
      file = upload("front,back\nhello,سلام\ncat,گربه\n")
      rows = described_class.parse(file: file)
      expect(rows).to eq([
        { front_content: "hello", back_content: "سلام" },
        { front_content: "cat",   back_content: "گربه" }
      ])
    end

    it "parses a CSV with term/definition headers" do
      file = upload("term,definition\nhello,world\n")
      rows = described_class.parse(file: file)
      expect(rows).to eq([{ front_content: "hello", back_content: "world" }])
    end

    it "returns [] for blank file" do
      expect(described_class.parse(file: nil)).to eq([])
    end

    it "returns [] when file has fewer than 2 columns" do
      file = upload("front\nhello\n")
      expect(described_class.parse(file: file)).to eq([])
    end

    it "skips rows where front or back is blank" do
      file = upload("front,back\nhello,world\n,empty_front\ngoodbye,\n")
      rows = described_class.parse(file: file)
      expect(rows).to eq([{ front_content: "hello", back_content: "world" }])
    end
  end

  describe ".call" do
    context "language inheritance from deck" do
      it "assigns front_language from deck.term_language" do
        csv = "front,back\nhello,سلام\n"
        described_class.call(deck: deck, file: upload(csv))
        card = deck.flashcards.last
        expect(card.front_language).to eq("en")
      end

      it "assigns back_language from deck.definition_language" do
        csv = "front,back\nhello,سلام\n"
        described_class.call(deck: deck, file: upload(csv))
        card = deck.flashcards.last
        expect(card.back_language).to eq("fa")
      end

      it "assigns nil languages when deck has no term_language" do
        null_lang_deck = create(:deck, user: user, term_language: nil, definition_language: nil)
        csv = "front,back\nhello,world\n"
        described_class.call(deck: null_lang_deck, file: upload(csv))
        card = null_lang_deck.flashcards.last
        expect(card.front_language).to be_nil
        expect(card.back_language).to be_nil
      end
    end

    context "result" do
      it "returns imported count and empty errors on success" do
        csv = "front,back\nhello,world\ncat,فیل\n"
        result = described_class.call(deck: deck, file: upload(csv))
        expect(result.imported).to eq(2)
        expect(result.errors).to be_empty
      end

      it "returns errors when file has no valid rows" do
        csv = "front,back\n,empty\n"
        result = described_class.call(deck: deck, file: upload(csv))
        expect(result.errors).not_to be_empty
      end
    end
  end
end
