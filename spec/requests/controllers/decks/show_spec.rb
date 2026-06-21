require "rails_helper"

RSpec.describe "Decks#show", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user, name: "Spanish Vocab", language_code: "es") }

  describe "GET /decks/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "displays the deck name" do
        get deck_path(deck)
        expect(response.body).to include("Spanish Vocab")
      end

      it "displays the language code" do
        get deck_path(deck)
        expect(response.body).to include("ES")
      end

      it "shows card count as zero when deck has no flashcards" do
        get deck_path(deck)
        expect(response.body).to match(/cards-island__count[^>]*>0<\/span>/)
      end

      it "shows flashcards when they exist" do
        create(:flashcard, deck: deck, front_content: "Hola", back_content: "Hello")
        get deck_path(deck)
        expect(response.body).to include("Hola")
      end

      it "renders the cards island container" do
        get deck_path(deck)
        expect(response.body).to include("cards-island")
      end

      it "renders the items-per-page selector" do
        get deck_path(deck)
        expect(response.body).to include("items-per-page-select")
      end

      it "defaults to 10 items per page" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck)
        expect(response.body).to include("cards-grid")
      end

      it "respects a valid items param" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck), params: { items: 5 }
        expect(response).to have_http_status(:ok)
      end

      it "ignores an invalid items param and defaults to 10" do
        get deck_path(deck), params: { items: 999 }
        expect(response).to have_http_status(:ok)
      end

      it "shows pagination when cards exceed the page size" do
        create_list(:flashcard, 12, deck: deck)
        get deck_path(deck), params: { items: 5 }
        expect(response.body).to include("pagination__btn")
      end


      it "renders an Edit Deck button for the owner" do
        get deck_path(deck)
        expect(response.body).to include("Edit Deck")
        expect(response.body).to include(edit_deck_path(deck))
      end
    end

    context "when authenticated as owner of a password-protected deck" do
      let(:pw_deck) { create(:deck, :password_protected, user: user) }

      before { sign_in(user) }

      it "returns 200 (owner bypasses the password gate)" do
        get deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "shows full deck content, not a locked preview" do
        card = pw_deck.flashcards.first
        get deck_path(pw_deck)
        expect(response.body).to include(card.front_content)
      end
    end

    context "when authenticated as owner of an unlisted password-protected deck" do
      before { sign_in(user) }

      it "returns 200 (owner bypasses the password gate)" do
        ul_pw_deck = create(:deck, :unlisted_password_protected, user: user)
        get deck_path(ul_pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "redirects to library for a private deck (inaccessible)" do
        get deck_path(deck)
        expect(response).to redirect_to(decks_path)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "does not render Delete Deck button for a non-owner viewing a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response.body).not_to include("Delete Deck")
      end

      it "returns 200 for an unlisted deck without a password" do
        unlisted_deck = create(:deck, :unlisted, user: user)
        get deck_path(unlisted_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password-protected deck (non-owner, no session)" do
        pw_deck = create(:deck, :password_protected, user: user)
        get deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "allows access to a password-protected deck after unlocking" do
        pw_deck = create(:deck, :password_protected, user: user)
        post unlock_deck_path(pw_deck), params: { password: "secret123" }
        get deck_path(pw_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for an unlisted password-protected deck (non-owner, no session)" do
        ul_pw_deck = create(:deck, :unlisted_password_protected, user: user)
        get deck_path(ul_pw_deck)
        expect(response).to redirect_to(unlock_deck_path(ul_pw_deck))
      end

      it "returns 200 for an unlisted password-protected deck after unlocking" do
        ul_pw_deck = create(:deck, :unlisted_password_protected, user: user)
        post unlock_deck_path(ul_pw_deck), params: { password: "secret123" }
        get deck_path(ul_pw_deck)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to explore for a private deck (inaccessible)" do
        get deck_path(deck)
        expect(response).to redirect_to(explore_path)
      end

      it "returns 200 for a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response).to have_http_status(:ok)
      end

      it "returns 200 for an unlisted deck without a password" do
        unlisted_deck = create(:deck, :unlisted, user: user)
        get deck_path(unlisted_deck)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to unlock for a password-protected deck (guest)" do
        pw_deck = create(:deck, :password_protected, user: user)
        get deck_path(pw_deck)
        expect(response).to redirect_to(unlock_deck_path(pw_deck))
      end

      it "does not show Fork button on a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response.body).not_to include("Fork")
      end
    end

    context "learn and test button visibility" do
      let(:public_deck) { create(:deck, :public, user: user) }

      context "when authenticated as non-owner" do
        let(:other_user) { create(:user) }
        before { sign_in(other_user) }

        it "shows the Learn button" do
          get deck_path(public_deck)
          expect(response.body).to include(learn_deck_path(public_deck))
        end

        it "shows the Test button" do
          get deck_path(public_deck)
          expect(response.body).to include(test_deck_path(public_deck))
        end
      end

      context "when not authenticated (guest)" do
        it "does not show the Learn button" do
          get deck_path(public_deck)
          expect(response.body).not_to include(learn_deck_path(public_deck))
        end

        it "does not show the Test button" do
          get deck_path(public_deck)
          expect(response.body).not_to include(test_deck_path(public_deck))
        end
      end
    end

    context "save button visibility" do
      let(:public_deck) { create(:deck, :public, user: user) }
      let(:other_user)  { create(:user) }

      context "when authenticated as non-owner" do
        before { sign_in(other_user) }

        it "shows the Save button" do
          get deck_path(public_deck)
          expect(response.body).to include(I18n.t("folders.save_button"))
        end

        it "shows Saved when the deck is already saved" do
          folder = create(:folder, user: other_user)
          create(:deck_folder, deck: public_deck, folder: folder)
          get deck_path(public_deck)
          expect(response.body).to include(I18n.t("folders.saved_button"))
        end

        it "links to the save modal" do
          get deck_path(public_deck)
          expect(response.body).to include(new_folder_deck_assignment_path(deck_id: public_deck.id))
        end
      end

      context "when authenticated as owner" do
        before { sign_in(user) }

        it "does not show the save modal link" do
          get deck_path(public_deck)
          expect(response.body).not_to include(new_folder_deck_assignment_path(deck_id: public_deck.id))
        end
      end

      context "when not authenticated" do
        it "does not show the save modal link" do
          get deck_path(public_deck)
          expect(response.body).not_to include(new_folder_deck_assignment_path(deck_id: public_deck.id))
        end
      end
    end

    context "unlisted deck noindex" do
      let(:unlisted_deck) { create(:deck, :unlisted, user: user) }

      before { sign_in(user) }

      it "sets X-Robots-Tag: noindex for an unlisted deck" do
        get deck_path(unlisted_deck)
        expect(response.headers["X-Robots-Tag"]).to eq("noindex")
      end

      it "does not set X-Robots-Tag for a public deck" do
        public_deck = create(:deck, :public, user: user)
        get deck_path(public_deck)
        expect(response.headers["X-Robots-Tag"]).to be_nil
      end
    end

    context "when deck does not exist" do
      it "redirects unauthenticated users to explore" do
        get deck_path(id: 999_999)
        expect(response).to redirect_to(explore_path)
      end

      it "redirects authenticated users to their library" do
        sign_in(user)
        get deck_path(id: 999_999)
        expect(response).to redirect_to(decks_path)
      end

      it "sets a flash alert" do
        get deck_path(id: 999_999)
        follow_redirect!
        expect(response.body).to include(I18n.t("errors.not_found.flash"))
      end
    end
  end
end
