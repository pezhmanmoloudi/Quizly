require "rails_helper"

RSpec.describe "LearnFeedbacks#create", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck) }
  let(:learn_session) do
    create(:learn_session, user: user, deck: deck, cards_total: 1)
  end
  let!(:item) do
    create(:learn_session_item,
           learn_session: learn_session,
           flashcard: flashcard,
           position: 0,
           mastery_score: 0)
  end

  def post_feedback(feedback, item_id: item.id)
    post learn_feedbacks_path,
         params:  { learn_session_item_id: item_id, feedback: feedback },
         headers: { "Accept" => "application/json" }
  end

  context "when authenticated" do
    before { sign_in(user) }

    context "with valid feedback" do
      %w[got_it confused dont_know].each do |fb|
        it "returns 200 for #{fb}" do
          post_feedback(fb)
          expect(response).to have_http_status(:ok)
        end

        it "returns JSON with mastery_score, status, session_complete for #{fb}" do
          post_feedback(fb)
          json = response.parsed_body
          expect(json.keys).to match_array(%w[mastery_score status session_complete])
        end
      end

      it "updates mastery_score for got_it" do
        post_feedback("got_it")
        expect(item.reload.mastery_score).to eq 20
      end

      it "returns session_complete: false when items still unmastered" do
        post_feedback("got_it")
        expect(response.parsed_body["session_complete"]).to be false
      end
    end

    context "when the last item reaches mastery on got_it" do
      before { item.update!(mastery_score: 60) }  # 60 + 20 = 80 = deck default threshold

      it "marks the learn session as finished" do
        post_feedback("got_it")
        expect(learn_session.reload.finished_at).not_to be_nil
      end

      it "returns session_complete: true" do
        post_feedback("got_it")
        expect(response.parsed_body["session_complete"]).to be true
      end

      it "calls StreakUpdater" do
        expect(StreakUpdater).to receive(:call).with(user)
        post_feedback("got_it")
      end

      it "calls BadgeAwarder" do
        expect(BadgeAwarder).to receive(:call).with(user)
        post_feedback("got_it")
      end
    end

    context "uses deck's learn_mastery_threshold" do
      it "marks mastered when score reaches deck threshold (80)" do
        deck.update!(learn_mastery_threshold: 80)
        item.update!(mastery_score: 60)
        post_feedback("got_it")
        expect(item.reload.status).to eq "mastered"
        expect(item.reload.mastery_score).to eq 80
      end

      it "does not mark mastered at 80 when threshold is 90" do
        deck.update!(learn_mastery_threshold: 90)
        item.update!(mastery_score: 60)
        post_feedback("got_it")
        expect(item.reload.status).to eq "learning"
        expect(item.reload.mastery_score).to eq 80
      end
    end

    context "with an invalid feedback value" do
      it "returns 400" do
        post_feedback("hacked")
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "IDOR protection" do
      let(:other_user)    { create(:user) }
      let(:other_deck)    { create(:deck, user: other_user) }
      let(:other_session) { create(:learn_session, user: other_user, deck: other_deck, cards_total: 1) }
      let!(:other_item) do
        create(:learn_session_item,
               learn_session: other_session,
               flashcard: create(:flashcard, deck: other_deck),
               position: 0)
      end

      it "returns 404 for an item belonging to another user" do
        post_feedback("got_it", item_id: other_item.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when unauthenticated" do
    it "redirects to login" do
      post learn_feedbacks_path,
           params: { learn_session_item_id: item.id, feedback: "got_it" }
      expect(response).to redirect_to(login_path)
    end
  end
end
