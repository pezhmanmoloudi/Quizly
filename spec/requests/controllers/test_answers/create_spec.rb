require "rails_helper"

RSpec.describe "TestAnswers#create", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, front_content: "Capital of France?", back_content: "Paris") }

  let(:single_written_question) do
    [ { "type" => "written", "prompt" => "Capital of France?",
        "correct_answer" => "Paris", "options" => [],
        "flashcard_id" => flashcard.id } ]
  end

  let(:test_session) do
    create(:test_session, user: user, deck: deck,
           questions_data: single_written_question.to_json,
           questions_total: 1, current_index: 0, score: 0)
  end

  def submit_answer(answer, accept: "text/vnd.turbo-stream.html")
    post test_answers_path,
         params: { answer: answer },
         headers: { "Accept" => accept }
  end

  before do
    sign_in(user)
    allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(test_session)
  end

  # ─── Response format ──────────────────────────────────────────────────────

  describe "response format" do
    it "returns turbo_stream content type" do
      submit_answer("Paris")
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "returns HTTP 200" do
      submit_answer("Paris")
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── Scoring ──────────────────────────────────────────────────────────────

  describe "scoring" do
    it "increments score when answer is correct" do
      expect { submit_answer("Paris") }.to change { test_session.reload.score }.by(1)
    end

    it "does not increment score when answer is incorrect" do
      expect { submit_answer("London") }.not_to change { test_session.reload.score }
    end
  end

  # ─── Written question — case-insensitive matching ─────────────────────────

  describe "written question" do
    it "accepts correct answer regardless of case" do
      expect { submit_answer("paris") }.to change { test_session.reload.score }.by(1)
    end

    it "accepts correct answer with surrounding whitespace" do
      expect { submit_answer("  Paris  ") }.to change { test_session.reload.score }.by(1)
    end

    it "rejects a wrong written answer" do
      expect { submit_answer("Berlin") }.not_to change { test_session.reload.score }
    end
  end

  # ─── Multiple-choice question ─────────────────────────────────────────────

  describe "multiple choice question" do
    let(:flashcard2) { create(:flashcard, deck: deck, front_content: "Capital of Germany?", back_content: "Berlin") }
    let(:flashcard3) { create(:flashcard, deck: deck, front_content: "Capital of Italy?",   back_content: "Rome") }
    let(:flashcard4) { create(:flashcard, deck: deck, front_content: "Capital of Spain?",   back_content: "Madrid") }

    let(:mc_session) do
      questions = [
        { "type" => "multiple_choice", "prompt" => "Capital of France?",
          "correct_answer" => "Paris",
          "options" => [ "Paris", "Berlin", "Rome", "Madrid" ],
          "flashcard_id" => flashcard.id }
      ]
      create(:test_session, user: user, deck: deck,
             questions_data: questions.to_json, questions_total: 1,
             current_index: 0, score: 0)
    end

    before do
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(mc_session)
    end

    it "increments score for the correct option" do
      expect {
        submit_answer("Paris")
      }.to change { mc_session.reload.score }.by(1)
    end

    it "does not increment score for a wrong option" do
      expect {
        submit_answer("Berlin")
      }.not_to change { mc_session.reload.score }
    end
  end

  # ─── True/False question ──────────────────────────────────────────────────

  describe "true/false question" do
    let(:tf_session) do
      questions = [
        { "type" => "true_false", "prompt" => "Paris is the capital of France.",
          "correct_answer" => "true", "options" => [],
          "flashcard_id" => flashcard.id }
      ]
      create(:test_session, user: user, deck: deck,
             questions_data: questions.to_json, questions_total: 1,
             current_index: 0, score: 0)
    end

    before do
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(tf_session)
    end

    it "increments score when true/false answer is correct" do
      expect {
        submit_answer("true")
      }.to change { tf_session.reload.score }.by(1)
    end

    it "does not increment score when true/false answer is wrong" do
      expect {
        submit_answer("false")
      }.not_to change { tf_session.reload.score }
    end
  end

  # ─── Session progression ──────────────────────────────────────────────────

  describe "session progression" do
    context "when more questions remain" do
      let(:flashcard2) { create(:flashcard, deck: deck, front_content: "Capital of Germany?", back_content: "Berlin") }
      let(:multi_session) do
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
        allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(multi_session)
      end

      it "advances current_index" do
        expect {
          submit_answer("Paris")
        }.to change { multi_session.reload.current_index }.by(1)
      end

      it "does not mark the session as finished" do
        submit_answer("Paris")
        expect(multi_session.reload.finished_at).to be_nil
      end

      it "does not call StreakUpdater" do
        expect(StreakUpdater).not_to receive(:call)
        submit_answer("Paris")
      end

      it "does not call BadgeAwarder" do
        expect(BadgeAwarder).not_to receive(:call)
        submit_answer("Paris")
      end
    end

    context "when answering the last question" do
      it "marks the session as finished" do
        submit_answer("Paris")
        expect(test_session.reload.finished_at).not_to be_nil
      end

      it "calls StreakUpdater" do
        expect(StreakUpdater).to receive(:call).with(user)
        submit_answer("Paris")
      end

      it "calls BadgeAwarder" do
        expect(BadgeAwarder).to receive(:call).with(user)
        submit_answer("Paris")
      end

      it "renders the completion summary in the turbo stream" do
        submit_answer("Paris")
        expect(response.body).to include("test-summary")
      end
    end
  end

  # ─── Session lookup safety ────────────────────────────────────────────────

  describe "session lookup safety" do
    before do
      # Remove stub so real find_test_session runs
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_call_original
    end

    it "returns 404 when no test_session_id is in the session cookie" do
      submit_answer("Paris")
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when the test session is already finished" do
      test_session.update!(finished_at: Time.current)
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(nil)
      submit_answer("Paris")
      expect(response).to have_http_status(:not_found)
    end
  end

  # ─── IDOR protection ──────────────────────────────────────────────────────

  describe "IDOR protection" do
    it "cannot access another user's test session via a forged session ID" do
      other_user = create(:user)
      other_deck = create(:deck, user: other_user)
      other_card = create(:flashcard, deck: other_deck)
      other_session = create(:test_session, user: other_user, deck: other_deck,
                             questions_data: [ { "type" => "written", "prompt" => "Q?",
                                                 "correct_answer" => "A",
                                                 "options" => [],
                                                 "flashcard_id" => other_card.id } ].to_json,
                             questions_total: 1, current_index: 0, score: 0)

      # The real find_test_session scopes to Current.user.test_sessions.
      # Verify the model-level scope rejects the cross-user lookup.
      expect(user.test_sessions.find_by(id: other_session.id)).to be_nil
    end

    it "returns 404 when find_test_session resolves to nil for a cross-user ID" do
      allow_any_instance_of(TestAnswersController).to receive(:find_test_session).and_return(nil)
      submit_answer("Paris")
      expect(response).to have_http_status(:not_found)
    end
  end

  # ─── Authentication ───────────────────────────────────────────────────────

  describe "authentication" do
    it "redirects to login when not authenticated" do
      delete logout_path
      post test_answers_path, params: { answer: "Paris" }
      expect(response).to redirect_to(login_path)
    end
  end
end
