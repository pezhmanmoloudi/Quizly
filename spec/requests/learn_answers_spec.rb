require "rails_helper"

RSpec.describe "LearnAnswers#create", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, front_content: "Capital of France?", back_content: "Paris") }
  let(:learn_session) do
    ls = create(:learn_session, user: user, deck: deck, cards_total: 1)
    create(:learn_session_item, learn_session: ls, flashcard: flashcard, position: 0)
    ls
  end
  let(:item) { learn_session.learn_session_items.first }

  before do
    sign_in(user)
    # Simulate having the session in the cookie
    post learn_answers_path, params: { learn_session_item_id: item.id, answer: "Paris" }
  end

  describe "POST /learn_answers with correct answer" do
    it "marks item as mastered" do
      expect(item.reload.status).to eq "mastered"
    end

    it "increments cards_mastered on the session" do
      expect(learn_session.reload.cards_mastered).to eq 1
    end

    it "returns turbo_stream format" do
      post learn_answers_path,
           params: { learn_session_item_id: item.id, answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    end
  end

  describe "POST /learn_answers with incorrect answer" do
    before do
      @item2 = create(:learn_session_item,
                      learn_session: learn_session,
                      flashcard: create(:flashcard, deck: deck),
                      position: 1)
      post learn_answers_path,
           params: { learn_session_item_id: @item2.id, answer: "wrong" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "keeps item in learning state" do
      expect(@item2.reload.status).to eq "learning"
    end

    it "does not increment cards_mastered" do
      expect(learn_session.reload.cards_mastered).to eq 1
    end
  end

  describe "POST /learn_answers unauthenticated" do
    it "redirects to login" do
      delete logout_path
      post learn_answers_path, params: { learn_session_item_id: item.id, answer: "Paris" }
      expect(response).to redirect_to(login_path)
    end
  end
end
