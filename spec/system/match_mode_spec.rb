require "rails_helper"

RSpec.describe "Match Mode UI", type: :system do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let!(:card1) { create(:flashcard, deck: deck, front_content: "Bonjour",    back_content: "Hello") }
  let!(:card2) { create(:flashcard, deck: deck, front_content: "Au revoir",  back_content: "Goodbye") }
  let!(:card3) { create(:flashcard, deck: deck, front_content: "Merci",      back_content: "Thank you") }

  before { sign_in_as(user) }

  # ─── Page renders ─────────────────────────────────────────────────────────

  it "renders the match island container" do
    visit match_deck_path(deck)
    expect(page).to have_css(".match-island")
  end

  it "renders two tiles per flashcard (front + back)" do
    visit match_deck_path(deck)
    expect(page).to have_css(".match-tile", count: card1.deck.flashcards.count * 2)
  end

  it "renders the timer badge" do
    visit match_deck_path(deck)
    expect(page).to have_css("[data-match-target='timer']")
  end

  it "renders the pairs-left counter" do
    visit match_deck_path(deck)
    expect(page).to have_css("[data-match-target='pairsLeft']")
  end

  it "renders the progress bar container" do
    visit match_deck_path(deck)
    expect(page).to have_css(".match-island__progress-wrap")
  end

  it "renders the empty state when deck has no cards" do
    empty_deck = create(:deck, user: user)
    visit match_deck_path(empty_deck)
    expect(page).to have_content(I18n.t("study_modes.no_cards_title"))
  end

  # ─── Tile selection ───────────────────────────────────────────────────────

  it "marks a tile as selected when clicked" do
    visit match_deck_path(deck)
    first(".match-tile").click
    expect(page).to have_css(".match-tile.is-selected", count: 1)
  end

  it "deselects a tile when it is clicked a second time" do
    visit match_deck_path(deck)
    tile = first(".match-tile")
    tile.click
    tile.click
    expect(page).not_to have_css(".match-tile.is-selected")
  end

  # ─── Correct match ────────────────────────────────────────────────────────

  it "marks both tiles as matched when the correct pair is selected" do
    visit match_deck_path(deck)

    # Select front tile and matching back tile for the same flashcard
    front_tile = find(".match-tile", text: "Bonjour")
    back_tile  = find(".match-tile", text: "Hello")

    front_tile.click
    back_tile.click

    expect(page).to have_css(".match-tile.is-matched", count: 2)
  end

  it "clears is-selected after a correct match" do
    visit match_deck_path(deck)
    find(".match-tile", text: "Bonjour").click
    find(".match-tile", text: "Hello").click
    expect(page).not_to have_css(".match-tile.is-selected")
  end

  it "decrements the pairs-left counter after a correct match" do
    visit match_deck_path(deck)
    initial_pairs = find("[data-match-target='pairsLeft']").text.to_i

    find(".match-tile", text: "Bonjour").click
    find(".match-tile", text: "Hello").click

    expect(find("[data-match-target='pairsLeft']").text.to_i).to eq(initial_pairs - 1)
  end

  # ─── Wrong match ─────────────────────────────────────────────────────────

  it "marks both tiles as wrong when a mismatched pair is selected" do
    visit match_deck_path(deck)

    # Select tiles from different flashcards
    find(".match-tile", text: "Bonjour").click
    find(".match-tile", text: "Goodbye").click

    expect(page).to have_css(".match-tile.is-wrong", count: 2)
  end

  it "removes is-wrong from tiles after the error animation delay" do
    visit match_deck_path(deck)

    find(".match-tile", text: "Bonjour").click
    find(".match-tile", text: "Goodbye").click

    # Wait for the 700ms CSS transition + buffer
    sleep 1.2
    expect(page).not_to have_css(".match-tile.is-wrong")
  end

  # ─── Completion ───────────────────────────────────────────────────────────

  it "reveals the completion overlay when all pairs are matched" do
    visit match_deck_path(deck)

    # Match all pairs
    [
      [ "Bonjour",   "Hello"     ],
      [ "Au revoir", "Goodbye"   ],
      [ "Merci",     "Thank you" ]
    ].each do |front, back|
      find(".match-tile", text: front).click
      find(".match-tile", text: back).click
    end

    expect(page).to have_css(".match-game__complete:not([hidden])")
  end

  it "shows the Play Again link on completion" do
    visit match_deck_path(deck)

    [
      [ "Bonjour",   "Hello"     ],
      [ "Au revoir", "Goodbye"   ],
      [ "Merci",     "Thank you" ]
    ].each do |front, back|
      find(".match-tile", text: front).click
      find(".match-tile", text: back).click
    end

    expect(page).to have_link(I18n.t("study_modes.match.play_again"))
  end
end

# ─── Guest CTA banner (separate describe — no sign-in before block) ──────────

RSpec.describe "Match Mode — Guest experience", type: :system do
  let(:owner)       { create(:user) }
  let(:public_deck) { create(:deck, :public, user: owner) }
  let!(:card)       { create(:flashcard, deck: public_deck, front_content: "Bonjour", back_content: "Hello") }

  it "shows the guest sign-in CTA banner on a public deck when not signed in" do
    visit match_deck_path(public_deck)
    expect(page).to have_css(".guest-cta-banner")
    expect(page).to have_link(I18n.t("shared.sign_in"))
  end
end
