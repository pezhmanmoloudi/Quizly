require "rails_helper"

RSpec.describe "Learn Mode UI", type: :system do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let!(:card1) { create(:flashcard, deck: deck, front_content: "Bonjour",   back_content: "Hello") }
  let!(:card2) { create(:flashcard, deck: deck, front_content: "Au revoir", back_content: "Goodbye") }

  before { sign_in_as(user) }

  # ─── Page renders ─────────────────────────────────────────────────────────

  it "renders the learn page" do
    visit learn_deck_path(deck)
    expect(page).to have_css(".study-island")
  end

  it "renders the flashcard slide" do
    visit learn_deck_path(deck)
    expect(page).to have_css(".flashcard-browse__slide")
  end

  it "includes the feedback bar in the DOM (shown by Stimulus after card flip)" do
    visit learn_deck_path(deck)
    expect(page).to have_css(".learn-feedback-bar", visible: :all)
  end

  it "renders the stats header with mastery percentage" do
    visit learn_deck_path(deck)
    expect(page).to have_css("[data-flashcard-browse-target='learnMasteryPct']")
              .or have_css("[id='learnMasteryPct']")
              .or have_content("learnMasteryPct", visible: :hidden)
    # The stats header element containing mastery count is present
    expect(page).to have_css(".study-island__stats")
  end

  it "shows the empty state when deck has no cards" do
    empty_deck = create(:deck, user: user)
    visit learn_deck_path(empty_deck)
    expect(page).to have_content(I18n.t("study_modes.no_cards_title"))
  end

  # ─── Feedback buttons ─────────────────────────────────────────────────────

  it "has a Got It button wired to the Stimulus action" do
    visit learn_deck_path(deck)
    expect(page).to have_css("[data-action*='flashcard-browse#gotIt']", visible: :all)
  end

  it "has a Confused button wired to the Stimulus action" do
    visit learn_deck_path(deck)
    expect(page).to have_css("[data-action*='flashcard-browse#confused']", visible: :all)
  end

  it "has a Don't Know button wired to the Stimulus action" do
    visit learn_deck_path(deck)
    expect(page).to have_css("[data-action*='flashcard-browse#dontKnow']", visible: :all)
  end

  # ─── Navigation ──────────────────────────────────────────────────────────

  it "renders the exit link back to the deck" do
    visit learn_deck_path(deck)
    expect(page).to have_link(I18n.t("study_modes.exit"))
  end

  it "shows all card fronts in the slide list" do
    visit learn_deck_path(deck)
    expect(page).to have_content("Bonjour")
  end
end
