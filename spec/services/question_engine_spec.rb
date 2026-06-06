require "rails_helper"

RSpec.describe QuestionEngine do
  let(:deck) { create(:deck) }
  let!(:cards) { 5.times.map { |i| create(:flashcard, deck: deck, front_content: "Q#{i}", back_content: "A#{i}") } }

  describe ".generate" do
    it "returns the requested count of questions" do
      questions = QuestionEngine.generate(flashcards: cards, count: 3)
      expect(questions.size).to eq 3
    end

    it "returns all cards when no count given" do
      questions = QuestionEngine.generate(flashcards: cards)
      expect(questions.size).to eq cards.size
    end

    it "generates questions with required keys" do
      questions = QuestionEngine.generate(flashcards: cards)
      questions.each do |q|
        expect(q).to include("flashcard_id", "type", "prompt", "correct_answer", "options")
      end
    end

    it "generates multiple choice when pool is big enough" do
      questions = QuestionEngine.generate(flashcards: cards, types: ["multiple_choice"], count: 3)
      questions.each do |q|
        expect(q["type"]).to eq "multiple_choice"
        expect(q["options"].size).to eq 4
        expect(q["options"]).to include(q["correct_answer"])
      end
    end

    it "falls back to written when pool is too small for MC" do
      small_cards = cards.first(2)
      questions = QuestionEngine.generate(flashcards: small_cards, types: ["multiple_choice"])
      questions.each { |q| expect(q["type"]).to eq "written" }
    end

    it "generates true_false questions" do
      questions = QuestionEngine.generate(flashcards: cards, types: ["true_false"])
      questions.each do |q|
        expect(q["type"]).to eq "true_false"
        expect(q["options"]).to eq [ "true", "false" ]
        expect(%w[true false]).to include(q["correct_answer"])
      end
    end

    it "generates written questions" do
      questions = QuestionEngine.generate(flashcards: cards, types: ["written"])
      questions.each do |q|
        expect(q["type"]).to eq "written"
        expect(q["options"]).to be_empty
      end
    end

    it "generates matching questions when pool is big enough" do
      questions = QuestionEngine.generate(flashcards: cards, types: ["matching"], count: 1)
      q = questions.first
      expect(q["type"]).to eq "matching"
      expect(q["options"]["terms"].size).to be >= 1
      expect(q["options"]["definitions"].size).to eq q["options"]["terms"].size
      correct = JSON.parse(q["correct_answer"])
      expect(correct).to be_a(Hash)
      expect(correct.size).to be >= 1
    end

    it "falls back to written when pool is too small for matching" do
      small_cards = cards.first(2)
      questions = QuestionEngine.generate(flashcards: small_cards, types: ["matching"])
      questions.each { |q| expect(q["type"]).to eq "written" }
    end

    it "falls back to written when pool has only one card and true_false requested" do
      questions = QuestionEngine.generate(flashcards: cards.first(1), types: ["true_false"])
      questions.each { |q| expect(q["type"]).to eq "written" }
    end
  end

  describe ".check_answer" do
    it "returns true for exact written match" do
      q = { "type" => "written", "correct_answer" => "Paris" }
      expect(QuestionEngine.check_answer(q, "Paris")).to be true
    end

    it "is case-insensitive for written answers" do
      q = { "type" => "written", "correct_answer" => "Paris" }
      expect(QuestionEngine.check_answer(q, "paris")).to be true
    end

    it "strips whitespace for written answers" do
      q = { "type" => "written", "correct_answer" => "Paris" }
      expect(QuestionEngine.check_answer(q, "  Paris  ")).to be true
    end

    it "returns true for correct MC answer" do
      q = { "type" => "multiple_choice", "correct_answer" => "Paris" }
      expect(QuestionEngine.check_answer(q, "Paris")).to be true
    end

    it "returns false for wrong answer" do
      q = { "type" => "written", "correct_answer" => "Paris" }
      expect(QuestionEngine.check_answer(q, "London")).to be false
    end

    it "returns true for correct matching answer" do
      correct = { "1" => "Paris", "2" => "Berlin" }.to_json
      q = { "type" => "matching", "correct_answer" => correct }
      expect(QuestionEngine.check_answer(q, correct)).to be true
    end

    it "returns false for wrong matching answer" do
      correct = { "1" => "Paris", "2" => "Berlin" }.to_json
      wrong   = { "1" => "Berlin", "2" => "Paris" }.to_json
      q = { "type" => "matching", "correct_answer" => correct }
      expect(QuestionEngine.check_answer(q, wrong)).to be false
    end

    it "returns false for invalid JSON in matching answer" do
      q = { "type" => "matching", "correct_answer" => { "1" => "Paris" }.to_json }
      expect(QuestionEngine.check_answer(q, "not-json")).to be false
    end
  end
end
