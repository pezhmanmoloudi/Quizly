require "rails_helper"

RSpec.describe "LearnAnswers#create — streak and badge triggering", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, back_content: "Paris") }

  before { sign_in(user) }

  context "when the last item is answered correctly" do
    let(:learn_session) do
      create(:learn_session, user: user, deck: deck, cards_total: 1)
    end
    let!(:item) { create(:learn_session_item, learn_session: learn_session, flashcard: flashcard, position: 0) }

    it "calls StreakUpdater" do
      expect(StreakUpdater).to receive(:call).with(user)
      post learn_answers_path,
           params: { learn_session_item_id: item.id, answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "calls BadgeAwarder" do
      expect(BadgeAwarder).to receive(:call).with(user)
      post learn_answers_path,
           params: { learn_session_item_id: item.id, answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end

  context "when items remain after an answer" do
    let(:flashcard2) { create(:flashcard, deck: deck, back_content: "Berlin") }
    let(:learn_session) do
      create(:learn_session, user: user, deck: deck, cards_total: 2)
    end
    let!(:item0) { create(:learn_session_item, learn_session: learn_session, flashcard: flashcard,  position: 0) }
    let!(:item1) { create(:learn_session_item, learn_session: learn_session, flashcard: flashcard2, position: 1) }

    it "does not call StreakUpdater" do
      expect(StreakUpdater).not_to receive(:call)
      post learn_answers_path,
           params: { learn_session_item_id: item0.id, answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "does not call BadgeAwarder" do
      expect(BadgeAwarder).not_to receive(:call)
      post learn_answers_path,
           params: { learn_session_item_id: item0.id, answer: "Paris" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end
end
