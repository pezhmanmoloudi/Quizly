require "rails_helper"

RSpec.describe "Decks#fork", type: :request do
  let(:owner)         { create(:user) }
  let(:forker)        { create(:user) }
  let(:everyone_deck) { create(:deck, user: owner, visibility: "everyone", name: "French Basics", subject_tags: "french, beginner") }
  let(:private_deck)  { create(:deck, user: owner, visibility: "private") }
  let(:unlisted_deck) { create(:deck, :unlisted, user: owner, name: "Unlisted Deck") }
  let(:pw_deck)       { create(:deck, :password_protected, user: owner, name: "Protected Deck") }

  describe "POST /decks/:id/fork" do
    context "when authenticated as another user" do
      before { sign_in(forker) }

      # ── public deck ──────────────────────────────────────────────────────────

      it "creates a copy of a public deck" do
        expect {
          post fork_deck_path(everyone_deck)
        }.to change { forker.decks.count }.by(1)
      end

      it "copies flashcards into the new deck" do
        create(:flashcard, deck: everyone_deck, front_content: "Bonjour", back_content: "Hello")
        post fork_deck_path(everyone_deck)
        copy = forker.decks.last
        expect(copy.flashcards.count).to eq(1)
        expect(copy.flashcards.first.front_content).to eq("Bonjour")
      end

      it "copies subject_tags" do
        post fork_deck_path(everyone_deck)
        expect(forker.decks.last.subject_tags).to eq(everyone_deck.subject_tags)
      end

      it "sets forked_from on the copy" do
        post fork_deck_path(everyone_deck)
        expect(forker.decks.last.forked_from).to eq(everyone_deck)
      end

      it "populates snapshot metadata" do
        post fork_deck_path(everyone_deck)
        copy = forker.decks.last
        expect(copy.forked_from_title_snapshot).to eq("French Basics")
        expect(copy.forked_from_owner_display_snapshot).to eq(owner.display_name)
        expect(copy.forked_at).to be_present
      end

      it "sets the copy as private regardless of source visibility" do
        post fork_deck_path(everyone_deck)
        expect(forker.decks.last.visibility).to eq("private")
      end

      it "increments forks_count on the source deck" do
        expect {
          post fork_deck_path(everyone_deck)
        }.to change { everyone_deck.reload.forks_count }.by(1)
      end

      it "redirects to the edit page of the new deck" do
        post fork_deck_path(everyone_deck)
        copy = forker.decks.last
        expect(response).to redirect_to(edit_deck_path(copy))
      end

      it "shows success notice after redirect" do
        post fork_deck_path(everyone_deck)
        follow_redirect!
        expect(response.body).to include("Deck added to your library")
      end

      it "accepts a custom name via params" do
        post fork_deck_path(everyone_deck), params: { deck: { name: "My French Copy", visibility: "private" } }
        expect(forker.decks.last.name).to eq("My French Copy")
      end

      it "accepts a custom visibility via params" do
        post fork_deck_path(everyone_deck), params: { deck: { name: "Test", visibility: "unlisted" } }
        expect(forker.decks.last.visibility).to eq("unlisted")
      end

      it "rejects password_protected as fork visibility and falls back to private" do
        post fork_deck_path(everyone_deck), params: { deck: { name: "Test", visibility: "password_protected" } }
        expect(forker.decks.last.visibility).to eq("private")
      end

      it "redirects back with alert when fork name is invalid" do
        post fork_deck_path(everyone_deck), params: { deck: { name: "x" * 101 } }
        expect(response).to redirect_to(deck_path(everyone_deck))
        follow_redirect!
        expect(response.body).to include("Name")
      end

      it "returns 404 for another user's private deck" do
        post fork_deck_path(private_deck)
        expect(response).to have_http_status(:not_found)
      end

      # ── unlisted deck ─────────────────────────────────────────────────────────

      context "with unlisted deck after visiting the share link" do
        before { get shared_deck_path(unlisted_deck.share_token) }

        it "creates a copy of the unlisted deck" do
          expect {
            post fork_deck_path(unlisted_deck)
          }.to change { forker.decks.count }.by(1)
        end

        it "sets the fork as private" do
          post fork_deck_path(unlisted_deck)
          expect(forker.decks.last.visibility).to eq("private")
        end

        it "sets forked_from on the unlisted copy" do
          post fork_deck_path(unlisted_deck)
          expect(forker.decks.last.forked_from).to eq(unlisted_deck)
        end
      end

      it "returns 404 for an unlisted deck without share link session" do
        post fork_deck_path(unlisted_deck)
        expect(response).to have_http_status(:not_found)
      end

      # ── password-protected deck ───────────────────────────────────────────────

      it "redirects to unlock when forking a password-protected deck without session auth" do
        post fork_deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      context "with password-protected deck after successful authentication" do
        before { post authenticate_deck_path(pw_deck), params: { access_password: "secret123" } }

        it "creates a copy" do
          expect {
            post fork_deck_path(pw_deck)
          }.to change { forker.decks.count }.by(1)
        end

        it "sets the fork as private" do
          post fork_deck_path(pw_deck)
          expect(forker.decks.last.visibility).to eq("private")
        end

        it "populates snapshot metadata for a password-protected fork" do
          post fork_deck_path(pw_deck)
          copy = forker.decks.last
          expect(copy.forked_from_title_snapshot).to eq("Protected Deck")
          expect(copy.forked_from_owner_display_snapshot).to eq(owner.display_name)
        end
      end

      # ── forks_count decrement ─────────────────────────────────────────────────

      it "decrements forks_count when a fork is deleted" do
        post fork_deck_path(everyone_deck)
        copy = forker.decks.last
        expect {
          copy.destroy
        }.to change { everyone_deck.reload.forks_count }.by(-1)
      end
    end

    # ── owner behavior ────────────────────────────────────────────────────────

    context "when authenticated as the deck owner" do
      before { sign_in(owner) }

      it "allows the owner to duplicate their own public deck" do
        everyone_deck
        expect {
          post fork_deck_path(everyone_deck)
        }.to change { owner.decks.count }.by(1)
      end

      it "allows the owner to duplicate their own private deck" do
        private_deck
        expect {
          post fork_deck_path(private_deck)
        }.to change { owner.decks.count }.by(1)
      end

      it "redirects to the edit page after duplicating" do
        post fork_deck_path(everyone_deck)
        copy = owner.decks.order(:created_at).last
        expect(response).to redirect_to(edit_deck_path(copy))
      end
    end

    # ── unauthenticated ───────────────────────────────────────────────────────

    context "when not authenticated" do
      it "redirects to login" do
        post fork_deck_path(everyone_deck)
        expect(response).to redirect_to(login_path)
      end

      it "redirects to login for unlisted deck even after visiting share link" do
        get shared_deck_path(unlisted_deck.share_token)
        post fork_deck_path(unlisted_deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
