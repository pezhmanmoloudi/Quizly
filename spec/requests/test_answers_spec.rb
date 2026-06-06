require "rails_helper"

RSpec.describe "TestAnswers#create", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, front_content: "Q1", back_content: "Paris") }
  let(:questions) do
    [ { "flashcard_id" => flashcard.id, "type" => "written",
        "prompt" => "Q1", "correct_answer" => "Paris", "options" => [] } ]
  end
  let(:test_session) do
    create(:test_session, user: user, deck: deck,
           questions_data: questions.to_json, questions_total: 1,
           current_index: 0, score: 0)
  end

  before do
    sign_in(user)
    # Set up the test session in the cookie-backed session
    get test_deck_path(deck)
  end

  describe "POST /test_answers with correct answer" do
    before do
      # Use the actual session created by the GET
      @ts = TestSession.where(user: user, deck: deck).last
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(@ts)
      post test_answers_path,
           params: { answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "returns turbo_stream format" do
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    end
  end

  describe "POST /test_answers unauthenticated" do
    it "redirects to login" do
      delete logout_path
      post test_answers_path, params: { answer: "Paris" }
      expect(response).to redirect_to(login_path)
    end
  end
end
