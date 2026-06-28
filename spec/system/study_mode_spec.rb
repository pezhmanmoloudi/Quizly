require "rails_helper"

RSpec.describe "Study Mode UI", type: :system do
  let(:user)     { create(:user) }
  let(:deck)     { create(:deck, user: user) }
  let(:card)     { create(:flashcard, deck: deck, front_content: "Bonjour", back_content: "Hello") }
  let!(:progress) { create(:card_progress, :due, user: user, flashcard: card) }

  before { sign_in_as(user) }

  # ─── Page renders ─────────────────────────────────────────────────────────

  it "shows the card front on load" do
    visit study_deck_path(deck)
    expect(page).to have_content("Bonjour")
  end

  it "does not show the card back before reveal" do
    visit study_deck_path(deck)
    expect(page).not_to have_css(".study-card__back:not([hidden])")
  end

  it "shows the Show Answer button" do
    visit study_deck_path(deck)
    expect(page).to have_button(I18n.t("study_modes.study.show_answer"))
  end

  it "shows the remaining cards chip" do
    visit study_deck_path(deck)
    expect(page).to have_css(".study-hdr__chip--remaining")
  end

  it "shows the settings gear button" do
    visit study_deck_path(deck)
    expect(page).to have_css(".study-hdr__btn")
  end

  # ─── Reveal interaction ───────────────────────────────────────────────────

  it "reveals the card back when Show Answer is clicked" do
    visit study_deck_path(deck)
    click_button I18n.t("study_modes.study.show_answer")
    expect(page).to have_css(".study-card__back:not([hidden])")
    expect(page).to have_content("Hello")
  end

  it "shows the rating buttons after revealing the answer" do
    visit study_deck_path(deck)
    click_button I18n.t("study_modes.study.show_answer")
    expect(page).to have_css(".rating-btn--again")
    expect(page).to have_css(".rating-btn--hard")
    expect(page).to have_css(".rating-btn--good")
    expect(page).to have_css(".rating-btn--easy")
  end

  # ─── Rating submission (Turbo Frame) ─────────────────────────────────────

  context "with a second due card" do
    let(:card2)      { create(:flashcard, deck: deck, front_content: "Au revoir", back_content: "Goodbye") }
    let!(:progress2) { create(:card_progress, :due, user: user, flashcard: card2) }

    it "loads the next card after rating without a full page reload" do
      visit study_deck_path(deck)
      current_url = page.current_url

      click_button I18n.t("study_modes.study.show_answer")
      find(".rating-btn--good").click

      # Turbo Frame updates — URL stays the same (study page, not a redirect)
      expect(page.current_url).to eq(current_url)
      # New card content appears
      expect(page).to have_css(".study-card")
    end
  end

  # ─── Settings drawer ─────────────────────────────────────────────────────

  it "opens the settings drawer when the gear button is clicked" do
    visit study_deck_path(deck)
    find("[data-action='click->study-mode#openSettings']").click
    expect(page).to have_css(".study-options.is-open")
  end

  it "closes the settings drawer when the close button inside is clicked" do
    visit study_deck_path(deck)
    find("[data-action='click->study-mode#openSettings']").click
    find("[data-action='click->study-mode#closeSettings']").click
    expect(page).not_to have_css(".study-options.is-open")
  end

  # ─── Empty / all-caught-up state ─────────────────────────────────────────

  it "renders all-caught-up state when no cards are due" do
    # Override the due card to be scheduled in the future
    progress.update!(next_review_at: 1.week.from_now)

    visit study_deck_path(deck)
    expect(page).to have_content(I18n.t("study_modes.study.empty_title"))
  end

  # ─── Session summary ─────────────────────────────────────────────────────

  it "shows the session summary after the last card is reviewed" do
    visit study_deck_path(deck)
    click_button I18n.t("study_modes.study.show_answer")
    find(".rating-btn--good").click

    expect(page).to have_content(I18n.t("study_modes.study.summary_title"))
  end
end
