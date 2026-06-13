require "rails_helper"

RSpec.describe "Decks#test", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/test" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        create(:flashcard, deck: deck)
        get test_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "creates a TestSession on first visit" do
        create(:flashcard, deck: deck)
        expect { get test_deck_path(deck) }.to change(TestSession, :count).by(1)
      end

      it "generates questions up to 20" do
        25.times { create(:flashcard, deck: deck) }
        get test_deck_path(deck)
        expect(TestSession.last.questions_total).to eq 20
      end

      it "generates questions equal to deck size when fewer than 20" do
        3.times { create(:flashcard, deck: deck) }
        get test_deck_path(deck)
        expect(TestSession.last.questions_total).to eq 3
      end

      it "reuses the active test session on revisit" do
        create(:flashcard, deck: deck)
        get test_deck_path(deck)
        expect { get test_deck_path(deck) }.not_to change(TestSession, :count)
      end

      it "shows empty state when deck has no cards" do
        get test_deck_path(deck)
        expect(response.body).to include("No cards yet")
      end

      it "returns 404 for another user's private deck" do
        other = create(:deck, user: create(:user))
        get test_deck_path(other)
        expect(response).to have_http_status(:not_found)
      end

      it "renders the stats header with timer and score badges" do
        create(:flashcard, deck: deck)
        get test_deck_path(deck)
        expect(response.body).to include("study-island__stats")
        expect(response.body).to include("test_score")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get test_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
