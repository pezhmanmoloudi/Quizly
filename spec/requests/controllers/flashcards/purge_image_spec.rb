require "rails_helper"

RSpec.describe "Flashcards#purge_image", type: :request do
  let(:user)      { create(:user) }
  let(:deck)      { create(:deck, user: user) }
  let(:flashcard) { create(:flashcard, deck: deck) }

  def attach_image(card)
    card.image.attach(
      io:           StringIO.new("fake image data"),
      filename:     "test.jpg",
      content_type: "image/jpeg"
    )
  end

  describe "DELETE /flashcards/:id/purge_image" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "purges the attached image and returns 200 JSON" do
        attach_image(flashcard)
        expect(flashcard.image).to be_attached

        delete purge_image_flashcard_path(flashcard), headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(flashcard.reload.image).not_to be_attached
      end

      it "returns 200 when no image is attached" do
        expect(flashcard.image).not_to be_attached

        delete purge_image_flashcard_path(flashcard), headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
      end

      it "returns JSON with the flashcard id" do
        attach_image(flashcard)

        delete purge_image_flashcard_path(flashcard), headers: { "Accept" => "application/json" }

        expect(JSON.parse(response.body)["id"]).to eq(flashcard.id)
      end
    end

    context "when authenticated as another user" do
      let(:other_user) { create(:user) }
      before { sign_in(other_user) }

      it "is rejected" do
        attach_image(flashcard)

        delete purge_image_flashcard_path(flashcard), headers: { "Accept" => "application/json" }

        expect(response).not_to have_http_status(:ok)
        expect(flashcard.reload.image).to be_attached
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete purge_image_flashcard_path(flashcard), headers: { "Accept" => "application/json" }

        expect(response).to redirect_to(login_path)
      end
    end
  end
end
