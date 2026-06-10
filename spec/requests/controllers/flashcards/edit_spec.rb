require "rails_helper"

RSpec.describe "Flashcards#edit", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck, front_language: "en", back_language: "fr") }

  describe "GET /flashcards/:id/edit" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get edit_flashcard_path(flashcard)
        expect(response).to have_http_status(:ok)
      end

      it "renders the custom language selector for front and back language" do
        get edit_flashcard_path(flashcard)
        expect(response.body).to include('data-controller="language"')
        expect(response.body.scan('data-controller="language"').size).to be >= 2
      end

      it "pre-selects the existing front_language in the hidden input" do
        get edit_flashcard_path(flashcard)
        expect(response.body).to include('name="flashcard[front_language]"')
        expect(response.body).to include('value="en"')
      end

      it "pre-selects the existing back_language in the hidden input" do
        get edit_flashcard_path(flashcard)
        expect(response.body).to include('name="flashcard[back_language]"')
        expect(response.body).to include('value="fr"')
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_flashcard_path(flashcard)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "returns 404" do
        get edit_flashcard_path(flashcard)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
