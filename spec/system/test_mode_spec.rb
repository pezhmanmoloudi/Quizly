require "rails_helper"

RSpec.describe "Test Mode UI", type: :system do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  before { sign_in_as(user) }

  # 1 card → QuestionEngine always picks "written" (only eligible type)
  let!(:card) { create(:flashcard, deck: deck, front_content: "Capital of France?", back_content: "Paris") }

  # ─── Page renders ─────────────────────────────────────────────────────────

  it "shows the question prompt" do
    visit test_deck_path(deck)
    expect(page).to have_content("Capital of France?")
  end

  it "shows the timer badge" do
    visit test_deck_path(deck)
    expect(page).to have_css("[data-test-mode-target='timer']")
  end

  it "shows the score badge" do
    visit test_deck_path(deck)
    expect(page).to have_css("#test_score")
  end

  it "shows the progress bar" do
    visit test_deck_path(deck)
    expect(page).to have_css("#test_progress")
  end

  it "renders the empty state when deck has no cards" do
    empty_deck = create(:deck, user: user)
    visit test_deck_path(empty_deck)
    expect(page).to have_content(I18n.t("study_modes.no_cards_title"))
  end

  # ─── Written question (guaranteed with exactly 1 card) ───────────────────

  it "renders a text input for written questions" do
    visit test_deck_path(deck)
    expect(page).to have_css(".test-question__written-input")
  end

  it "submitting the correct answer completes the test with a perfect score" do
    visit test_deck_path(deck)
    fill_in :answer, with: "Paris"
    find(".test-question__submit-btn").click
    expect(page).to have_css(".test-summary")
    expect(page).to have_content("100%")
  end

  it "submitting a wrong answer completes the test with zero score" do
    visit test_deck_path(deck)
    fill_in :answer, with: "London"
    find(".test-question__submit-btn").click
    expect(page).to have_css(".test-summary")
    expect(page).to have_content("0%")
  end

  # ─── Intermediate feedback state (requires 2+ questions) ─────────────────
  # 2 cards → QuestionEngine generates 2 questions; answering the first shows
  # the feedback div before the test is finished.

  context "with a second card so the test has 2 questions" do
    let!(:card2) { create(:flashcard, deck: deck, front_content: "Capital of Germany?", back_content: "Berlin") }

    # Submit whatever question type appears first (written or true/false with 2 cards)
    def submit_first_answer
      if page.has_css?(".test-question__written-input", wait: 3)
        fill_in :answer, with: "x"
        find(".test-question__submit-btn").click
      elsif page.has_css?(".test-tf-btn--true", wait: 1)
        find(".test-tf-btn--true").click
      end
    end

    it "shows the feedback div after answering a non-final question" do
      visit test_deck_path(deck)
      submit_first_answer
      expect(page).to have_css(".test-question__feedback")
    end

    it "shows the Continue button after answering a non-final question" do
      visit test_deck_path(deck)
      submit_first_answer
      expect(page).to have_css(".test-question__continue")
    end
  end

  # ─── Multiple-choice question (requires 4 cards for MC eligibility) ───────

  context "with 4 cards so multiple choice may be generated" do
    let!(:card2) { create(:flashcard, deck: deck, front_content: "C of Germany?",  back_content: "Berlin") }
    let!(:card3) { create(:flashcard, deck: deck, front_content: "C of Italy?",    back_content: "Rome") }
    let!(:card4) { create(:flashcard, deck: deck, front_content: "C of Spain?",    back_content: "Madrid") }

    it "renders option buttons when the question is multiple choice" do
      visit test_deck_path(deck)
      # MC options only appear when QuestionEngine picks multiple_choice;
      # skip if a different type was generated this run
      skip "No MC question generated this run" unless page.has_css?(".test-option", wait: 2)
      expect(page).to have_css(".test-option", minimum: 2)
    end
  end

  # ─── True/false question (requires 2 cards for T/F eligibility) ──────────

  context "with 2 cards so true/false may be generated" do
    let!(:card2) { create(:flashcard, deck: deck, front_content: "C of Germany?", back_content: "Berlin") }

    it "renders true and false buttons when the question is true/false" do
      visit test_deck_path(deck)
      skip "No T/F question generated this run" unless page.has_css?(".test-tf-btn--true", wait: 2)
      expect(page).to have_css(".test-tf-btn--true")
      expect(page).to have_css(".test-tf-btn--false")
    end
  end

  # ─── Completion flow ─────────────────────────────────────────────────────

  it "shows the session summary after the last question is answered" do
    visit test_deck_path(deck)
    fill_in :answer, with: "Paris"
    find(".test-question__submit-btn").click
    expect(page).to have_css(".test-summary")
  end

  it "shows a retake link on the summary screen" do
    visit test_deck_path(deck)
    fill_in :answer, with: "Paris"
    find(".test-question__submit-btn").click
    expect(page).to have_link(I18n.t("study_modes.test.retake"))
  end
end
