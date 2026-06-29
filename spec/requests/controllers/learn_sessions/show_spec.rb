require "rails_helper"

RSpec.describe "LearnSessions#show", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/learn" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "creates a LearnSession on first visit" do
        create(:flashcard, deck: deck)
        expect { get learn_deck_path(deck) }.to change(LearnSession, :count).by(1)
      end

      it "creates LearnSessionItems for all deck cards" do
        3.times { create(:flashcard, deck: deck) }
        get learn_deck_path(deck)
        session_id = LearnSession.last.id
        expect(LearnSessionItem.where(learn_session_id: session_id).count).to eq 3
      end

      it "reuses the active learn session on revisit" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect { get learn_deck_path(deck) }.not_to change(LearnSession, :count)
      end

      it "shows empty state when deck has no cards" do
        get learn_deck_path(deck)
        expect(response.body).to include("No cards yet")
      end

      it "redirects for another user's private deck" do
        other = create(:deck, user: create(:user))
        get learn_deck_path(other)
        expect(response).to redirect_to(decks_path)
      end

      it "returns 200 for a non-owner on a public deck" do
        public_deck = create(:deck, :public, user: create(:user))
        get learn_deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password-protected public deck (non-owner, no session)" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        get learn_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "returns 200 for a password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: create(:user))
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get learn_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "renders the learn mode stats header" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect(response.body).to include("study-island__stats")
        expect(response.body).to include("learnNewCount")
        expect(response.body).to include("learnMasteryPct")
      end

      it "renders flashcard slides for the engine" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect(response.body).to include("flashcard-browse__slide")
        expect(response.body).to include("flashcard-browse#flip")
      end

      it "renders the feedback bar" do
        create(:flashcard, deck: deck)
        get learn_deck_path(deck)
        expect(response.body).to include("learn-feedback-bar")
        expect(response.body).to include("flashcard-browse#gotIt")
      end
    end

    context "session size is bounded by learn_new_cards_limit (backend-owned membership)" do
      before { sign_in(user) }

      it "creates exactly learn_new_cards_limit items when the deck has more cards" do
        8.times { create(:flashcard, deck: deck) }
        deck.update!(learn_new_cards_limit: 5)
        get learn_deck_path(deck)
        expect(LearnSession.last.learn_session_items.count).to eq 5
      end

      it "renders exactly that many flashcard slides (DB items == rendered slides)" do
        8.times { create(:flashcard, deck: deck) }
        deck.update!(learn_new_cards_limit: 5)
        get learn_deck_path(deck)
        expect(response.body.scan(/flashcard-browse__slide/).size).to eq 5
      end

      it "includes all cards when the limit is 0 (unlimited)" do
        6.times { create(:flashcard, deck: deck) }
        deck.update!(learn_new_cards_limit: 0)
        get learn_deck_path(deck)
        expect(LearnSession.last.learn_session_items.count).to eq 6
      end

      it "uses the updated limit for the next (fresh) session" do
        12.times { create(:flashcard, deck: deck) }
        deck.update!(learn_new_cards_limit: 5)
        get learn_deck_path(deck, restart: true)
        expect(LearnSession.last.learn_session_items.count).to eq 5

        deck.update!(learn_new_cards_limit: 10)
        get learn_deck_path(deck, restart: true)
        expect(LearnSession.last.learn_session_items.count).to eq 10
      end
    end

    context "with weak_only param" do
      before { sign_in(user) }

      let!(:flashcard1) { create(:flashcard, deck: deck) }
      let!(:flashcard2) { create(:flashcard, deck: deck) }
      let!(:prev_session) do
        s = create(:learn_session, user: user, deck: deck,
                   cards_total: 2, finished_at: 1.hour.ago)
        create(:learn_session_item, learn_session: s, flashcard: flashcard1,
               mastery_score: 20, position: 0)
        create(:learn_session_item, learn_session: s, flashcard: flashcard2,
               mastery_score: 90, position: 1)
        s
      end

      it "creates a new session containing only weak cards from the previous session" do
        expect {
          get learn_deck_path(deck, weak_only: true)
        }.to change(LearnSession, :count).by(1)
        new_session = LearnSession.last
        expect(new_session.learn_session_items.pluck(:flashcard_id)).to eq [flashcard1.id]
      end

      it "returns 200 when no previous session exists for the deck" do
        empty_deck = create(:deck, user: user)
        create(:flashcard, deck: empty_deck)
        get learn_deck_path(empty_deck, weak_only: true)
        expect(response).to have_http_status(:ok)
      end
    end

    context "stale session — all items mastered but not finished (blank-stage bug)" do
      before { sign_in(user) }

      let!(:flashcard) { create(:flashcard, deck: deck) }

      # Drive the session into the inconsistent state through the real flow:
      # first visit creates the session (+ cookie + unseen items), then we
      # mark every item mastered while leaving finished_at nil — the exact
      # condition that produced an empty learn queue and a blank card stage.
      def enter_all_mastered_state
        get learn_deck_path(deck)
        session_record = LearnSession.last
        session_record.update!(finished_at: nil)
        session_record.learn_session_items.update_all(status: "mastered", mastery_score: 90)
        session_record
      end

      it "marks an unfinished all-mastered session as finished on visit" do
        session_record = enter_all_mastered_state
        get learn_deck_path(deck)
        expect(session_record.reload.finished_at).to be_present
      end

      it "renders the completion branch, not an interactive card stage, when the queue is empty" do
        enter_all_mastered_state
        get learn_deck_path(deck)
        expect(response).to have_http_status(:ok)
        # finished branch renders the summary but NOT the flashcard-browse card stage
        expect(response.body).to include("session-summary__title")
        expect(response.body).not_to include('data-controller="flashcard-browse"')
        expect(response.body).not_to include("flashcard-browse__slide")
      end

      it "does not create a duplicate session for the all-mastered visit" do
        enter_all_mastered_state
        expect { get learn_deck_path(deck) }.not_to change(LearnSession, :count)
      end

      it "recovers on reload — a later visit starts a fresh session showing cards (no blank loop)" do
        enter_all_mastered_state

        # First visit finalizes the stale session and renders completion.
        get learn_deck_path(deck)
        expect(response.body).not_to include('data-controller="flashcard-browse"')

        # Reload: cookie was cleared, so a brand-new session is started and the
        # card stage renders again — the user is not trapped in a blank screen.
        expect { get learn_deck_path(deck) }.to change(LearnSession, :count).by(1)
        expect(response.body).to include('data-controller="flashcard-browse"')
        expect(response.body).to include("flashcard-browse__slide")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get learn_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end

      it "redirects to login even for a public deck (learn requires authentication)" do
        public_deck = create(:deck, :public, user: user)
        get learn_deck_path(public_deck)
        expect(response).to redirect_to(login_path)
      end
    end

    context "password-protected deck — owner bypass" do
      before { sign_in(user) }

      it "returns 200 for the owner without needing to unlock" do
        pw_deck = create(:deck, :password_protected, user: user)
        create(:flashcard, deck: pw_deck)
        get learn_deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
