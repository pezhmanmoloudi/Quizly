require "rails_helper"

RSpec.describe "CardProgresses#grade", type: :request do
  let(:user)          { create(:user) }
  let(:deck)          { create(:deck, user: user) }
  let(:flashcard)     { create(:flashcard, deck: deck) }
  let(:card_progress) { create(:card_progress, :due, user: user, flashcard: flashcard) }

  before { sign_in(user) }

  subject(:grade) { post grade_card_progress_path(card_progress), params: { quality: 4 }, as: :json }

  it "returns HTTP 200 with JSON" do
    grade
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/json")
  end

  it "updates SM-2 fields on the card_progress" do
    expect { grade }.to change { card_progress.reload.repetitions }.by(1)
      .and change { card_progress.reload.next_review_at }
  end

  it "returns the updated progress fields" do
    grade
    body = response.parsed_body
    expect(body).to include(
      "id"           => card_progress.id,
      "flashcard_id" => flashcard.id
    )
    expect(body.keys).to include("ease_factor", "interval", "repetitions",
                                  "next_review_at", "last_reviewed_at")
  end

  context "when quality is 1 (again)" do
    it "resets repetitions to 0" do
      card_progress.update!(repetitions: 3)
      post grade_card_progress_path(card_progress), params: { quality: 1 }, as: :json
      expect(card_progress.reload.repetitions).to eq(0)
    end
  end

  context "when accessing another user's card_progress" do
    let(:other_user)     { create(:user) }
    let(:other_progress) { create(:card_progress, :due, user: other_user, flashcard: flashcard) }

    it "does not update the other user's card_progress" do
      expect {
        post grade_card_progress_path(other_progress), params: { quality: 4 }, as: :json
      }.not_to change { other_progress.reload.repetitions }
    end
  end

  context "when not authenticated" do
    before { delete logout_path }

    it "redirects to login" do
      post grade_card_progress_path(card_progress), params: { quality: 4 }, as: :json
      expect(response).to have_http_status(:redirect)
    end
  end
end
