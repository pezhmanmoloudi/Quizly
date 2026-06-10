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

      it "pre-fills existing flashcards" do
        card = create(:flashcard, deck: deck, front_content: "Hello", back_content: "Hola")
        get cards_deck_path(deck)
        expect(response.body).to include("Hello")
        expect(response.body).to include("Hola")
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

      it "rejects when no flashcards_attributes are submitted and deck has no cards" do
        patch update_cards_deck_path(deck), params: { deck: { flashcards_attributes: {} } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(deck.flashcards.reload.count).to eq(0)
      end

      it "re-renders with error when all rows are blank and deck has no cards" do
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { front_content: "", back_content: "" }
            }
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(deck.flashcards.reload.count).to eq(0)
      end

      it "allows saving with no new rows when deck already has cards" do
        create(:flashcard, deck: deck, front_content: "Existing", back_content: "Card")
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { front_content: "", back_content: "" }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.flashcards.reload.count).to eq(1)
      end

      it "updates an existing flashcard's content" do
        card = create(:flashcard, deck: deck, front_content: "Old front", back_content: "Old back")
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { id: card.id, front_content: "New front", back_content: "New back", _destroy: "0" }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(card.reload.front_content).to eq("New front")
        expect(card.reload.back_content).to eq("New back")
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

      # The specs below mirror the exact params the browser sends after the numeric-index fix.
      # All server-rendered rows now use sequential integer keys, so the same
      # ActionController::Parameters#permit path is exercised as in production.

      it "browser form: new deck submits two initial rows, saves only the filled one" do
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { front_content: "Hello", back_content: "Salam" },
              "1" => { front_content: "",      back_content: ""      }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.flashcards.reload.count).to eq(1)
        expect(deck.flashcards.first.front_content).to eq("Hello")
      end

      it "browser form: editing deck sends id + content + _destroy=0 for unchanged cards" do
        card = create(:flashcard, deck: deck, front_content: "Term", back_content: "Def")
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { id: card.id.to_s, front_content: "Term updated",
                       back_content: "Def updated", _destroy: "0" }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.flashcards.reload.count).to eq(1)
        expect(card.reload.front_content).to eq("Term updated")
        expect(card.reload.back_content).to eq("Def updated")
      end

      it "browser form: deleting a card sends id + content + _destroy=1 for that row" do
        kept  = create(:flashcard, deck: deck, front_content: "Keep", back_content: "This", position: 0)
        gone  = create(:flashcard, deck: deck, front_content: "Gone", back_content: "Bye",  position: 1)
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { id: kept.id.to_s, front_content: kept.front_content,
                       back_content: kept.back_content, _destroy: "0" },
              "1" => { id: gone.id.to_s, front_content: gone.front_content,
                       back_content: gone.back_content, _destroy: "1" }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.flashcards.reload.map(&:id)).to eq([kept.id])
      end

      it "rejects missing front_content when requires_language is false" do
        patch update_cards_deck_path(deck), params: {
          requires_language: "false",
          deck: { flashcards_attributes: { "0" => { front_content: "", back_content: "B" } } }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects missing language when requires_language is true" do
        patch update_cards_deck_path(deck), params: {
          requires_language: "true",
          deck: { flashcards_attributes: {
            "0" => { front_content: "A", back_content: "B",
                     front_language: "", back_language: "" }
          } }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "accepts valid rows with language when requires_language is true" do
        patch update_cards_deck_path(deck), params: {
          requires_language: "true",
          deck: { flashcards_attributes: {
            "0" => { front_content: "A", back_content: "B",
                     front_language: "en", back_language: "es" }
          } }
        }
        expect(response).to redirect_to(deck_path(deck))
      end

      it "saves an image attachment with the card" do
        image = fixture_file_upload("spec/fixtures/files/test_avatar.png", "image/png")
        patch update_cards_deck_path(deck), params: {
          deck: {
            flashcards_attributes: {
              "0" => { front_content: "Hello", back_content: "World", image: image }
            }
          }
        }
        expect(response).to redirect_to(deck_path(deck))
        expect(deck.flashcards.reload.last.image).to be_attached
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
