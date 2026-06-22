require "rails_helper"

RSpec.describe "Users#show", type: :request do
  let(:user)        { create(:user) }
  let(:profile_user) { create(:user) }

  context "when authenticated" do
    before { sign_in(user) }

    it "renders the profile page" do
      get user_path(profile_user)
      expect(response).to have_http_status(:ok)
    end

    it "displays the user's username" do
      get user_path(profile_user)
      expect(response.body).to include(profile_user.username)
    end
  end

  context "when unauthenticated" do
    it "renders the profile page without requiring login" do
      get user_path(profile_user)
      expect(response).to have_http_status(:ok)
    end
  end

  context "with public and private decks" do
    let(:public_deck)  { create(:deck, user: profile_user, visibility: "public") }
    let(:private_deck) { create(:deck, user: profile_user, visibility: "private") }

    before do
      create(:flashcard, deck: public_deck)
      create(:flashcard, deck: private_deck)
      sign_in(user)
    end

    it "shows only discoverable (public + complete) decks" do
      get user_path(profile_user)
      expect(response.body).to include(public_deck.name)
      expect(response.body).not_to include(private_deck.name)
    end
  end

  it "redirects for an unknown username (not-found handler)" do
    get user_path("nonexistent_user_xyz")
    expect(response).to be_redirect
  end
end
