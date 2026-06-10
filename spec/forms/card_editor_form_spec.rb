require "rails_helper"

RSpec.describe CardEditorForm do
  def build_row(front: "Term", back: "Def", front_lang: nil, back_lang: nil)
    { front_content: front, back_content: back,
      front_language: front_lang, back_language: back_lang }
  end

  describe "without language requirement" do
    subject(:form) { described_class.new(rows: rows, requires_language: false) }

    context "with valid rows" do
      let(:rows) { [build_row, build_row(front: "A", back: "B")] }

      it { is_expected.to be_valid }
    end

    context "with blank front_content" do
      let(:rows) { [build_row(front: "")] }

      it "is invalid and reports the error" do
        expect(form).not_to be_valid
        expect(form.errors.full_messages.first).to match(/term/i)
      end
    end

    context "with blank back_content" do
      let(:rows) { [build_row(back: "")] }

      it "is invalid and reports the error" do
        expect(form).not_to be_valid
        expect(form.errors.full_messages.first).to match(/definition/i)
      end
    end

    context "with blank language fields" do
      let(:rows) { [build_row(front_lang: nil, back_lang: nil)] }

      it "is valid — language not required" do
        expect(form).to be_valid
      end
    end

    context "with empty rows array" do
      let(:rows) { [] }

      it { is_expected.to be_valid }
    end
  end

  describe "with language requirement" do
    subject(:form) { described_class.new(rows: rows, requires_language: true) }

    context "with complete rows including language" do
      let(:rows) { [build_row(front_lang: "en", back_lang: "es")] }

      it { is_expected.to be_valid }
    end

    context "with missing front_language" do
      let(:rows) { [build_row(front_lang: nil, back_lang: "es")] }

      it "is invalid" do
        expect(form).not_to be_valid
        expect(form.errors.full_messages.first).to match(/language/i)
      end
    end

    context "with missing back_language" do
      let(:rows) { [build_row(front_lang: "en", back_lang: nil)] }

      it "is invalid" do
        expect(form).not_to be_valid
        expect(form.errors.full_messages.first).to match(/language/i)
      end
    end

    context "with multiple errors" do
      let(:rows) { [build_row(front: "", back: "", front_lang: nil, back_lang: nil)] }

      it "accumulates all errors" do
        expect(form).not_to be_valid
        expect(form.errors.count).to eq(4)
      end
    end
  end
end
