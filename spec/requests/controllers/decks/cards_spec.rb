require "rails_helper"

RSpec.describe "Decks#cards", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  describe "GET /decks/:id/cards" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get cards_deck_path(deck)
        expect(response).to have_http_status(:ok)
      end

      it "shows the deck name" do
        get cards_deck_path(deck)
        expect(response.body).to include(deck.name)
      end

      it "returns 404 for another user's deck" do
        other_deck = create(:deck, user: create(:user))
        get cards_deck_path(other_deck)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get cards_deck_path(deck)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /decks/:id/cards" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates flashcards and redirects to deck" do
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { front_content: "Hello", back_content: "Hola" },
              "1" => { front_content: "Goodbye", back_content: "Adiós" }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.flashcards.reload.count).to eq(2)
      end

      it "ignores blank rows" do
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { front_content: "", back_content: "" }
            }
          }
        }
        expect(deck.flashcards.reload.count).to eq(0)
      end

      it "destroys cards marked with _destroy" do
        card = create(:flashcard, deck: deck)
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { id: card.id, front_content: card.front_content,
                       back_content: card.back_content, _destroy: "1" }
            }
          }
        }
        expect(deck.flashcards.reload).to be_empty
      end

      it "returns 404 for another user's deck" do
        other_deck = create(:deck, user: create(:user))
        patch update_cards_deck_path(other_deck), params: { deck: { flashcards_attributes: {} } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch update_cards_deck_path(deck), params: { deck: { flashcards_attributes: {} } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
