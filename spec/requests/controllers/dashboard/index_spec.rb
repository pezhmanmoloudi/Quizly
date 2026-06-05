require "rails_helper"

RSpec.describe "Dashboard#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /dashboard" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "displays the user's display name in the hero" do
        get dashboard_path
        expect(response.body).to include(user.display_name)
      end

      it "shows total deck count" do
        create_list(:deck, 3, user: user)
        get dashboard_path
        expect(response.body).to include("3")
      end

      it "shows total card count across all user decks" do
        deck = create(:deck, user: user)
        create_list(:flashcard, 5, deck: deck)
        get dashboard_path
        expect(response.body).to include("5")
      end

      it "shows the My Library section header in the sidebar" do
        get dashboard_path
        expect(response.body).to include("My Library")
      end

      it "shows the global create deck button in the topbar" do
        get dashboard_path
        expect(response.body).to include("topbar__create-btn")
        expect(response.body).to include('aria-label="Create Deck"')
      end

      it "shows Cards Due stat" do
        deck = create(:deck, user: user)
        flashcard = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: flashcard)
        get dashboard_path
        expect(response.body).to include("Cards Due")
      end

      it "shows the user's own decks in the My Decks section" do
        create(:deck, user: user, name: "My Spanish Deck")
        get dashboard_path
        expect(response.body).to include("My Spanish Deck")
      end

      it "does not show decks from other users" do
        create(:deck, user: create(:user), name: "Stranger's Deck", visibility: "public")
        get dashboard_path
        expect(response.body).not_to include("Stranger&#39;s Deck")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get dashboard_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "Continue Studying banner" do
    before { sign_in(user) }

    context "when the user has no due cards" do
      it "does not render the banner" do
        get dashboard_path
        expect(response.body).not_to include("Continue Studying")
      end
    end

    context "when the user has due cards" do
      let!(:deck) { create(:deck, user: user, name: "Ruby Basics") }
      let!(:card) { create(:flashcard, deck: deck) }
      let!(:progress) do
        create(:card_progress, :due, user: user, flashcard: card,
               last_reviewed_at: 1.hour.ago)
      end

      it "renders the banner with the deck name" do
        get dashboard_path
        expect(response.body).to include("Continue Studying")
        expect(response.body).to include("Ruby Basics")
      end

      it "links to the study path for that deck" do
        get dashboard_path
        expect(response.body).to include(study_deck_path(deck))
      end
    end

    context "when multiple decks have due cards" do
      let!(:old_deck)    { create(:deck, user: user, name: "Old Deck") }
      let!(:recent_deck) { create(:deck, user: user, name: "Recent Deck") }

      before do
        old_card    = create(:flashcard, deck: old_deck)
        recent_card = create(:flashcard, deck: recent_deck)
        create(:card_progress, :due, user: user, flashcard: old_card,
               last_reviewed_at: 2.days.ago)
        create(:card_progress, :due, user: user, flashcard: recent_card,
               last_reviewed_at: 1.hour.ago)
      end

      it "shows the most recently studied deck in the banner" do
        get dashboard_path
        expect(response.body).to include("Continue Studying")
        expect(response.body).to include("Recent Deck")
      end
    end

    context "when due cards exist but none have been studied yet" do
      let!(:deck_a) { create(:deck, user: user, name: "Deck A") }
      let!(:deck_b) { create(:deck, user: user, name: "Deck B") }

      before do
        create(:flashcard, deck: deck_a).tap do |c|
          create(:card_progress, :due, user: user, flashcard: c)
        end
        2.times do
          create(:flashcard, deck: deck_b).tap do |c|
            create(:card_progress, :due, user: user, flashcard: c)
          end
        end
      end

      it "falls back to the deck with the most due cards" do
        get dashboard_path
        expect(response.body).to include("Continue Studying")
        expect(response.body).to include("Deck B")
      end
    end
  end
end
