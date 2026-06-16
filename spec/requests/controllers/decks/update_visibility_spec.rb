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
              params: { deck: { visibility: "public", access_mode: "open" } },
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

      it "blocks any save when a public deck has no flashcards" do
        deck.flashcards.destroy_all
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(deck.reload.visibility).to eq("public")
      end

      it "updates access_mode to password with a password" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", access_mode: "password",
                                password: "secret123", password_confirmation: "secret123" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.access_mode).to eq("password")
        expect(response).to have_http_status(:ok)
      end

      it "saves password_digest when switching to password access_mode" do
        expect(deck.password_digest).to be_nil
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", access_mode: "password",
                                password: "secret123" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(deck.reload.password_digest).to be_present
        expect(deck.authenticate_password("secret123")).to be_truthy
      end

      it "does not save password when access_mode is open" do
        deck.update!(access_mode: "password", password: "oldpass1")
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "public", access_mode: "open",
                                password: "newpass1" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(deck.reload.access_mode).to eq("open")
      end

      it "ignores an invalid visibility value" do
        patch update_visibility_deck_path(deck),
              params: { deck: { visibility: "secret" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.visibility).to eq("public")
        expect(response).to have_http_status(:ok)
      end

      it "ignores an invalid access_mode value" do
        patch update_visibility_deck_path(deck),
              params: { deck: { access_mode: "everyone" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(deck.reload.access_mode).to eq("open")
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
