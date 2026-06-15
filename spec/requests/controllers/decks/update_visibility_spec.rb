require "rails_helper"

RSpec.describe "Decks#update_visibility", type: :request do
  let(:user) { create(:user) }
  let(:deck) do
    d = create(:deck, user: user)
    create(:flashcard, deck: d)
    d.reload
    d.update!(visibility: "public")
    d
  end

  describe "PATCH /decks/:id/update_visibility" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "updates visibility to private and returns turbo stream" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "private" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(deck.reload.visibility).to eq("private")
      end

      it "updates visibility to unlisted" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "unlisted" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.visibility).to eq("unlisted")
      end

      it "updates visibility to public when the deck has flashcards" do
        create(:flashcard, deck: deck)
        deck.update!(visibility: "private")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", edit_permission: "only_me" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.visibility).to eq("public")
      end

      it "blocks setting to public when deck has no flashcards" do
        deck.flashcards.destroy_all
        deck.update!(visibility: "private")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(deck.reload.visibility).to eq("private")
      end

      it "blocks setting to unlisted when deck has no flashcards" do
        deck.flashcards.destroy_all
        deck.update!(visibility: "private")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "unlisted" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(deck.reload.visibility).to eq("private")
      end

      it "renders the modal with persisted visibility after a failed update" do
        deck.flashcards.destroy_all
        deck.update!(visibility: "private")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Just me")
        expect(response.body).not_to include("value=\"public\" selected")
      end

      it "blocks any save when a public deck has no flashcards (Rule 5)" do
        deck.flashcards.destroy_all
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(deck.reload.visibility).to eq("public")
      end

      it "updates edit_permission to people_with_password with a password" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", edit_permission: "people_with_password",
                                password: "secret123", password_confirmation: "secret123" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.edit_permission).to eq("people_with_password")
        expect(response).to have_http_status(:ok)
      end

      it "saves password_digest when switching to people_with_password" do
        expect(deck.password_digest).to be_nil
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", edit_permission: "people_with_password",
                                password: "secret123" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(deck.reload.password_digest).to be_present
        expect(deck.authenticate_password("secret123")).to be_truthy
      end

      it "does not save password when edit_permission is only_me" do
        deck.update!(edit_permission: "people_with_password", password: "oldpass1")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", edit_permission: "only_me",
                                password: "newpass1" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(deck.reload.edit_permission).to eq("only_me")
        expect(deck.authenticate_password("oldpass1")).to be_truthy
      end

      it "updates edit_permission to only_me" do
        deck.update!(edit_permission: "only_me")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", edit_permission: "only_me" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.edit_permission).to eq("only_me")
      end

      it "ignores an invalid visibility value" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "secret" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.visibility).to eq("public")
        expect(response).to have_http_status(:ok)
      end

      it "ignores an invalid edit_permission value" do
        patch update_visibility_deck_path(deck),
              params: { deck: { edit_permission: "everyone" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.edit_permission).to eq("only_me")
        expect(response).to have_http_status(:ok)
      end

      it "falls back to HTML redirect when no turbo stream header" do
        patch update_visibility_deck_path(deck), params: { deck: { visibility: "private" } }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.reload.visibility).to eq("private")
      end
    end

    context "when authenticated as another user" do
      let(:other) { create(:user) }
      before { sign_in(other) }

      it "redirects away without changing visibility" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "private" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(decks_path)
        expect(deck.reload.visibility).to eq("public")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch update_visibility_deck_path(deck), params: { deck: { visibility: "private" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
