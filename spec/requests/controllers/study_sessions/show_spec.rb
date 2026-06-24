require "rails_helper"

RSpec.describe "StudySessions#show", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/study" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get study_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "initializes CardProgress records for new flashcards" do
        create(:flashcard, deck: deck)
        expect {
          get study_deck_path(deck)
        }.to change(CardProgress, :count).by(1)
      end

      it "shows the oldest due card first" do
        newer_card = create(:flashcard, deck: deck)
        older_card = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: newer_card, next_review_at: 1.hour.ago)
        create(:card_progress, :due, user: user, flashcard: older_card, next_review_at: 2.days.ago)
        get study_deck_path(deck)
        expect(response.body).to include(older_card.front_content)
      end

      it "renders the image when the due card has one attached" do
        card = create(:flashcard, deck: deck)
        card.image.attach(
          io: Rails.root.join("spec/fixtures/files/test_avatar.png").open,
          filename: "test_avatar.png",
          content_type: "image/png"
        )
        create(:card_progress, :due, user: user, flashcard: card)
        get study_deck_path(deck)
        expect(response.body).to include("study-card__img")
      end

      it "shows 'All caught up' when no cards are due" do
        flashcard = create(:flashcard, deck: deck)
        create(:card_progress, :future, user: user, flashcard: flashcard)
        get study_deck_path(deck)
        expect(response.body).to include("All caught up")
      end

      it "sets session start time on first card" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects for a private deck belonging to another user" do
        other_deck = create(:deck, user: create(:user))
        get study_deck_path(other_deck)
        expect(response).to redirect_to(decks_path)
      end

      it "returns 200 for a non-owner on a public deck (study? = show?)" do
        public_deck = create(:deck, :public, user: create(:user))
        get study_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password-protected public deck (non-owner, no session)" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        get study_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get study_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "renders the streak chip in the header" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response.body).to include("study-hdr__chip--streak")
      end

      it "shows remaining cards count when cards are due" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response.body).to include("study-hdr__chip--remaining")
      end

      it "does not render a timer" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response.body).not_to include("study-mode-target=\"timer\"")
      end

      it "renders the settings drawer and gear button" do
        create(:card_progress, :due, user: user, flashcard: create(:flashcard, deck: deck))
        get study_deck_path(deck)
        expect(response.body).to include("study-hdr__btn")
        expect(response.body).to include("study-options")
      end
    end

    context "with new_limit param" do
      before { sign_in(user) }

      it "shows only new cards up to the specified limit" do
        create_list(:flashcard, 5, deck: deck).each do |card|
          create(:card_progress, :due, user: user, flashcard: card, repetitions: 0)
        end
        get study_deck_path(deck, new_limit: 2)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("study-card")
      end

      it "shows review cards before new cards by default" do
        review_card = create(:flashcard, deck: deck)
        new_card    = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: review_card, repetitions: 3)
        create(:card_progress, :due, user: user, flashcard: new_card, repetitions: 0)
        get study_deck_path(deck)
        expect(response.body).to include(review_card.front_content)
      end

      it "applies hardest priority by ordering review cards by ease_factor ascending" do
        easy_card = create(:flashcard, deck: deck)
        hard_card = create(:flashcard, deck: deck)
        create(:card_progress, :due, user: user, flashcard: easy_card, repetitions: 2, ease_factor: 2.5)
        create(:card_progress, :due, user: user, flashcard: hard_card, repetitions: 2, ease_factor: 1.4)
        get study_deck_path(deck, priority: "hardest")
        expect(response.body).to include(hard_card.front_content)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get study_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end

      it "redirects to login even for a public deck (study requires authentication)" do
        public_deck = create(:deck, :public, user: user)
        get study_deck_path(public_deck)
        expect(response).to redirect_to(login_path)
      end
    end

    context "password-protected deck — owner bypass" do
      before { sign_in(user) }

      it "returns 200 for the owner without needing to unlock" do
        pw_deck = create(:deck, :password_protected, user: user)
        get study_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "session progress tracking" do
    before { sign_in(user) }

    it "shows progress bar when cards are due" do
      card = create(:flashcard, deck: deck)
      create(:card_progress, :due, user: user, flashcard: card)
      get study_deck_path(deck)
      expect(response.body).to include("study-island__progress")
    end

    it "does not show progress bar on all-caught-up screen" do
      card = create(:flashcard, deck: deck)
      create(:card_progress, :future, user: user, flashcard: card)
      get study_deck_path(deck)
      expect(response.body).not_to include("study-island__progress")
    end
  end

  describe "session summary after completing all cards" do
    before { sign_in(user) }

    it "shows session summary after reviewing the last due card" do
      card = create(:flashcard, deck: deck)
      progress = create(:card_progress, :due, user: user, flashcard: card)
      post card_reviews_path, params: { card_progress_id: progress.id, rating: "easy" }
      follow_redirect!
      expect(response.body).to include("Session complete")
    end
  end
end
