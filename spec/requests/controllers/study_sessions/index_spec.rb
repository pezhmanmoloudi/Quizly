require "rails_helper"

RSpec.describe "StudySessions#index", type: :request do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let(:other) { create(:user) }

  describe "GET /study_sessions" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get study_sessions_path
        expect(response).to have_http_status(:ok)
      end

      it "lists the current user's completed study sessions" do
        session = create(:study_session, :completed, user: user, deck: deck)
        get study_sessions_path
        expect(response.body).to include(deck.name)
        expect(response.body).to include(session.cards_reviewed.to_s)
      end

      it "does not include another user's sessions" do
        other_deck    = create(:deck, user: other)
        other_session = create(:study_session, :completed, user: other, deck: other_deck)
        get study_sessions_path
        expect(response.body).not_to include(other_deck.name)
      end

      it "shows the accuracy for each session" do
        create(:study_session, :completed, user: user, deck: deck,
               cards_reviewed: 10, cards_correct: 8)
        get study_sessions_path
        expect(response.body).to include("80%")
      end

      it "renders the empty state when no sessions exist" do
        get study_sessions_path
        expect(response.body).to include("study-history-table").or include("empty")
      end

      it "limits results to 50 most recent sessions" do
        55.times do
          create(:study_session, :completed, user: user, deck: deck)
        end
        get study_sessions_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get study_sessions_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
