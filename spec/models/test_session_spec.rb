require "rails_helper"

RSpec.describe TestSession, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      ts = build(:test_session)
      expect(ts).to be_valid
    end

    it "is invalid without started_at" do
      ts = build(:test_session, started_at: nil)
      expect(ts).not_to be_valid
    end

    it "is invalid when score is negative" do
      ts = build(:test_session, score: -1)
      expect(ts).not_to be_valid
    end
  end

  describe "#questions" do
    it "deserialises questions_data as an array of hashes" do
      q = [ { "flashcard_id" => 1, "type" => "written",
              "prompt" => "Q", "correct_answer" => "A", "options" => [] } ]
      ts = build(:test_session, questions_data: q.to_json)
      expect(ts.questions).to eq q
    end
  end

  describe "#accuracy" do
    it "returns 0 when no questions" do
      ts = build(:test_session, questions_total: 0, score: 0)
      expect(ts.accuracy).to eq 0
    end

    it "calculates rounded percentage" do
      ts = build(:test_session, questions_total: 4, score: 3)
      expect(ts.accuracy).to eq 75
    end
  end

  describe "#last_question?" do
    it "is true when current_index is the final question" do
      ts = build(:test_session, questions_total: 3, current_index: 2)
      expect(ts.last_question?).to be true
    end

    it "is false when not on the last question" do
      ts = build(:test_session, questions_total: 3, current_index: 1)
      expect(ts.last_question?).to be false
    end
  end

  describe "#current_question" do
    it "returns the question at current_index" do
      q0 = { "type" => "written", "prompt" => "First",  "correct_answer" => "A", "options" => [] }
      q1 = { "type" => "written", "prompt" => "Second", "correct_answer" => "B", "options" => [] }
      ts = build(:test_session, questions_data: [ q0, q1 ].to_json,
                 questions_total: 2, current_index: 1)
      expect(ts.current_question["prompt"]).to eq "Second"
    end
  end
end
