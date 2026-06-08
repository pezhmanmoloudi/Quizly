require "rails_helper"

RSpec.describe "TestAnswers#create — streak and badge triggering", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, front_content: "Capital of France?", back_content: "Paris") }

  before { sign_in(user) }

  context "when the last question is answered" do
    let(:test_session) do
      questions = [ { "type" => "written", "prompt" => "Capital of France?",
                      "correct_answer" => "Paris", "options" => [],
                      "flashcard_id" => flashcard.id } ]
      create(:test_session, user: user, deck: deck,
             questions_data: questions.to_json, questions_total: 1,
             current_index: 0, score: 0)
    end

    before do
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(test_session)
    end

    it "calls StreakUpdater" do
      expect(StreakUpdater).to receive(:call).with(user)
      post test_answers_path,
           params: { answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "calls BadgeAwarder" do
      expect(BadgeAwarder).to receive(:call).with(user)
      post test_answers_path,
           params: { answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  context "when more questions remain" do
    let(:flashcard2) { create(:flashcard, deck: deck, front_content: "Capital of Germany?", back_content: "Berlin") }
    let(:test_session) do
      questions = [
        { "type" => "written", "prompt" => "Capital of France?",
          "correct_answer" => "Paris", "options" => [], "flashcard_id" => flashcard.id },
        { "type" => "written", "prompt" => "Capital of Germany?",
          "correct_answer" => "Berlin", "options" => [], "flashcard_id" => flashcard2.id }
      ]
      create(:test_session, user: user, deck: deck,
             questions_data: questions.to_json, questions_total: 2,
             current_index: 0, score: 0)
    end

    before do
      flashcard2
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(test_session)
    end

    it "does not call StreakUpdater" do
      expect(StreakUpdater).not_to receive(:call)
      post test_answers_path,
           params: { answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "does not call BadgeAwarder" do
      expect(BadgeAwarder).not_to receive(:call)
      post test_answers_path,
           params: { answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end
end
