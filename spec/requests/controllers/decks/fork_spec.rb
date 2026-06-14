require "rails_helper"

RSpec.describe "Decks#fork", type: :request do
  let(:owner)         { create(:user) }
  let(:saver)         { create(:user) }
  let(:everyone_deck) { create(:deck, user: owner, visibility: "public", name: "French Basics", subject_tags: "french, beginner") }
  let(:private_deck)  { create(:deck, user: owner, visibility: "private") }
  let(:unlisted_deck) { create(:deck, :unlisted, user: owner, name: "Unlisted Deck") }
  let(:pw_deck)       { create(:deck, :public, user: owner, name: "Protected Deck") }

  describe "POST /decks/:id/fork" do
    context "when authenticated as another user (Save to Library)" do
      before { sign_in(saver) }

      # ── basic save ────────────────────────────────────────────────────────────

      it "creates a LibraryItem linking the saver to the deck" do
        expect {
          post fork_deck_path(everyone_deck)
        }.to change { LibraryItem.count }.by(1)
      end

      it "does NOT create a new Deck row for the saver" do
        expect {
          post fork_deck_path(everyone_deck)
        }.not_to change { saver.decks.count }
      end

      it "sets the correct user and deck on the LibraryItem" do
        post fork_deck_path(everyone_deck)
        item = LibraryItem.last
        expect(item.user).to eq(saver)
        expect(item.deck).to eq(everyone_deck)
      end

      it "redirects to the original deck after saving" do
        post fork_deck_path(everyone_deck)
        expect(response).to redirect_to(deck_path(everyone_deck))
      end

      it "shows success notice after redirect" do
        post fork_deck_path(everyone_deck)
        follow_redirect!
        expect(response.body).to include("Deck added to your library")
      end

      # ── idempotency ───────────────────────────────────────────────────────────

      context "when the user has already saved the deck" do
        before { post fork_deck_path(everyone_deck) }

        it "does not create a second LibraryItem" do
          expect {
            post fork_deck_path(everyone_deck)
          }.not_to change { LibraryItem.count }
        end

        it "redirects to the deck with already-saved notice" do
          post fork_deck_path(everyone_deck)
          follow_redirect!
          expect(response.body).to include("already")
        end
      end

      # ── turbo_stream format ───────────────────────────────────────────────────

      context "with turbo_stream format" do
        let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

        it "returns a turbo_stream response" do
          post fork_deck_path(everyone_deck), headers: turbo_headers
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "still creates a LibraryItem" do
          expect {
            post fork_deck_path(everyone_deck), headers: turbo_headers
          }.to change { LibraryItem.count }.by(1)
        end

        it "does not redirect" do
          post fork_deck_path(everyone_deck), headers: turbo_headers
          expect(response).not_to be_redirect
        end

        it "includes the library-state DOM ID in the stream" do
          post fork_deck_path(everyone_deck), headers: turbo_headers
          expect(response.body).to include("library-state-#{everyone_deck.id}")
        end

        context "when already saved" do
          before { create(:library_item, user: saver, deck: everyone_deck) }

          it "returns a turbo_stream response (idempotent)" do
            post fork_deck_path(everyone_deck), headers: turbo_headers
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          end

          it "does not create a duplicate LibraryItem" do
            expect {
              post fork_deck_path(everyone_deck), headers: turbo_headers
            }.not_to change { LibraryItem.count }
          end
        end
      end

      # ── access restrictions ───────────────────────────────────────────────────

      it "redirects away for another user's private deck" do
        post fork_deck_path(private_deck)
        expect(response).to redirect_to(decks_path)
      end

      it "does not create a LibraryItem for a private deck" do
        expect {
          post fork_deck_path(private_deck)
        }.not_to change { LibraryItem.count }
      end

      # ── unlisted deck ─────────────────────────────────────────────────────────

      context "with unlisted deck (no password)" do
        it "creates a LibraryItem for the unlisted deck" do
          expect {
            post fork_deck_path(unlisted_deck)
          }.to change { LibraryItem.count }.by(1)
        end

        it "does not create a new Deck for the saver" do
          expect {
            post fork_deck_path(unlisted_deck)
          }.not_to change { saver.decks.count }
        end

        it "saves without needing a prior share link session (share tokens removed)" do
          post fork_deck_path(unlisted_deck)
          expect(response).to redirect_to(deck_path(unlisted_deck))
        end
      end

      # ── public deck with edit password ────────────────────────────────────────

      it "saves a public deck directly without needing unlock" do
        post fork_deck_path(pw_deck)
        expect(response).to redirect_to(deck_path(pw_deck))
      end

      it "creates a LibraryItem for a public deck" do
        expect {
          post fork_deck_path(pw_deck)
        }.to change { LibraryItem.count }.by(1)
      end
    end

    # ── owner behavior ───────────────────────────────────────────────────────

    context "when authenticated as the deck owner" do
      before { sign_in(owner) }

      it "redirects to the deck without saving or copying" do
        post fork_deck_path(everyone_deck)
        expect(response).to redirect_to(deck_path(everyone_deck))
      end

      it "does not create a LibraryItem" do
        expect { post fork_deck_path(everyone_deck) }.not_to change { LibraryItem.count }
      end

      it "does not create a new deck" do
        everyone_deck
        expect { post fork_deck_path(everyone_deck) }.not_to change { Deck.count }
      end
    end

    # ── unauthenticated ───────────────────────────────────────────────────────

    context "when not authenticated" do
      it "redirects to login" do
        post fork_deck_path(everyone_deck)
        expect(response).to redirect_to(login_path)
      end

      it "redirects to login for unlisted deck" do
        post fork_deck_path(unlisted_deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
