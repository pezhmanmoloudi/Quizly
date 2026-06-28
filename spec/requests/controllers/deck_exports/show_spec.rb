require "rails_helper"

RSpec.describe "DeckExports#show", type: :request do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:deck)  { create(:deck, user: owner, name: "Basic English") }

  describe "GET /decks/:id/export" do
    context "when authenticated as the owner" do
      before { sign_in(owner) }

      it "returns a plain text attachment" do
        get export_deck_path(deck)
        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.content_type).to include("text/plain")
      end

      it "returns a filename with .txt extension" do
        get export_deck_path(deck)
        expect(response.headers["Content-Disposition"]).to include(".txt")
      end

      it "includes active flashcards as tab-separated lines" do
        create(:flashcard, deck: deck, front_content: "Hello", back_content: "سلام", position: 1)
        create(:flashcard, deck: deck, front_content: "Book",  back_content: "کتاب", position: 2)
        get export_deck_path(deck)
        lines = response.body.split("\n")
        expect(lines[0]).to eq("Hello\tسلام")
        expect(lines[1]).to eq("Book\tکتاب")
      end

      it "excludes soft-deleted flashcards" do
        create(:flashcard, deck: deck, deleted_at: 1.day.ago)
        get export_deck_path(deck)
        expect(response.body.strip).to be_empty
      end

      it "does not include ids, timestamps, or metadata" do
        create(:flashcard, deck: deck, front_content: "Hi", back_content: "سلام")
        get export_deck_path(deck)
        expect(response.body).not_to match(/\d{4}-\d{2}-\d{2}/)
        expect(response.body).not_to include("id")
        expect(response.body).not_to include("user")
      end
    end

    context "when authenticated as a non-owner" do
      before { sign_in(other) }

      it "redirects away (Pundit not-authorized)" do
        get export_deck_path(deck)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when unauthenticated" do
      it "redirects to the login page" do
        get export_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when the deck does not exist" do
      before { sign_in(owner) }

      it "redirects away (record not found)" do
        get export_deck_path(id: 0)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(decks_path)
      end
    end
  end
end
