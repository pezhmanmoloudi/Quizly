require "rails_helper"

RSpec.describe "Security — Cross-User Data Isolation", type: :system do
  let(:owner)      { create(:user) }
  let(:attacker)   { create(:user) }
  let(:private_deck) { create(:deck, user: owner) }

  # ─── Study mode ───────────────────────────────────────────────────────────

  describe "Study mode" do
    context "when attacker tries to study another user's private deck" do
      it "redirects away without exposing card content" do
        create(:flashcard, deck: private_deck, front_content: "Secret term")
        sign_in_as(attacker)
        visit study_deck_path(private_deck)
        expect(page).not_to have_content("Secret term")
        expect(page.current_path).not_to eq(study_deck_path(private_deck))
      end
    end
  end

  # ─── Test mode ────────────────────────────────────────────────────────────

  describe "Test mode" do
    context "when attacker tries to access another user's private deck test" do
      it "redirects away without showing questions" do
        create(:flashcard, deck: private_deck, front_content: "Secret question")
        sign_in_as(attacker)
        visit test_deck_path(private_deck)
        expect(page).not_to have_content("Secret question")
        expect(page.current_path).not_to eq(test_deck_path(private_deck))
      end
    end
  end

  # ─── Learn mode ───────────────────────────────────────────────────────────

  describe "Learn mode" do
    context "when attacker tries to access another user's private deck learn" do
      it "redirects away without showing card content" do
        create(:flashcard, deck: private_deck, front_content: "Confidential card")
        sign_in_as(attacker)
        visit learn_deck_path(private_deck)
        expect(page).not_to have_content("Confidential card")
        expect(page.current_path).not_to eq(learn_deck_path(private_deck))
      end
    end
  end

  # ─── Match mode ──────────────────────────────────────────────────────────

  describe "Match mode" do
    context "when attacker tries to access another user's private deck match" do
      it "redirects away without showing tiles" do
        create(:flashcard, deck: private_deck, front_content: "Hidden front")
        sign_in_as(attacker)
        visit match_deck_path(private_deck)
        expect(page).not_to have_content("Hidden front")
        expect(page.current_path).not_to eq(match_deck_path(private_deck))
      end
    end
  end

  # ─── Unauthenticated access ───────────────────────────────────────────────

  describe "Unauthenticated access" do
    it "redirects to login when visiting study mode without authentication" do
      visit study_deck_path(private_deck)
      expect(page).to have_current_path(login_path)
    end

    it "redirects to login when visiting test mode without authentication" do
      visit test_deck_path(private_deck)
      expect(page).to have_current_path(login_path)
    end

    it "redirects to login when visiting learn mode without authentication" do
      visit learn_deck_path(private_deck)
      expect(page).to have_current_path(login_path)
    end
  end

  # ─── Public deck — data isolation ────────────────────────────────────────

  describe "Public deck owned by attacker" do
    let(:attacker_public_deck) { create(:deck, :public, user: attacker) }

    before do
      # Add a distinct card to owner's deck
      create(:flashcard, deck: private_deck, front_content: "Owner-only data")
      sign_in_as(owner)
    end

    it "does not expose owner's private deck data on attacker's public deck page" do
      visit match_deck_path(attacker_public_deck)
      expect(page).not_to have_content("Owner-only data")
    end
  end
end
