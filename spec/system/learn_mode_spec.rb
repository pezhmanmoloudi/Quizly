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

  # ─── Backend-owned membership, completion & refresh (Approach A) ──────────

  describe "session size bounded by learn_new_cards_limit" do
    let(:big_deck) { create(:deck, user: user, learn_new_cards_limit: 5) }

    before { 8.times { |i| create(:flashcard, deck: big_deck, front_content: "F#{i}", back_content: "B#{i}") } }

    # Drives the adaptive queue to completion by flipping the visible card and
    # clicking "Got It" until the completion screen appears.
    def master_session!(max_steps: 60)
      max_steps.times do
        return if page.has_css?("[data-flashcard-browse-target='learnComplete']", visible: true, wait: 0.2)
        card = first(".flashcard-browse__slide:not([hidden]) .flashcard-card", visible: true, wait: 2)
        break unless card
        card.click # flip to back → feedback bar shows
        find(".learn-feedback-btn--got-it", wait: 2).click
      end
    end

    it "renders exactly learn_new_cards_limit slides (DB items == DOM slides)" do
      visit learn_deck_path(big_deck)
      expect(page).to have_css(".flashcard-browse__slide", count: 5, visible: :all)
      expect(LearnSession.last.learn_session_items.count).to eq 5
    end

    it "reaches the completion screen and never leaves a blank stage" do
      visit learn_deck_path(big_deck)
      expect(page).to have_css(".flashcard-browse__slide:not([hidden]) .flashcard-card")

      master_session!

      expect(page).to have_css("[data-flashcard-browse-target='learnComplete']", visible: true)
      expect(page).to have_content(I18n.t("study_modes.learn.summary_title"))
    end

    it "resumes the same session on refresh — no blank, no queue reset, no new session" do
      visit learn_deck_path(big_deck)
      expect(page).to have_css(".flashcard-browse__slide", count: 5, visible: :all)

      # Make partial progress on the first card.
      card = first(".flashcard-browse__slide:not([hidden]) .flashcard-card", visible: true)
      card.click
      find(".learn-feedback-btn--got-it").click

      expect {
        visit learn_deck_path(big_deck)
      }.not_to change(LearnSession, :count)

      # Card stage is restored (not blank) and still bounded to the session.
      expect(page).to have_css(".flashcard-browse__slide:not([hidden]) .flashcard-card")
      expect(page).to have_css(".flashcard-browse__slide", count: 5, visible: :all)
    end
  end

  # ─── Cross-mode settings isolation ────────────────────────────────────────

  describe "flashcard browse settings do not leak into Learn mode" do
    it "ignores autoAdvance / showBothSides stored under quizly.flashcard.settings" do
      visit learn_deck_path(deck) # establish origin so localStorage is writable
      page.execute_script(
        "window.localStorage.setItem('quizly.flashcard.settings', " \
        "JSON.stringify({ autoAdvance: true, showBothSides: true }))"
      )

      # Reload: connect() reads the seeded settings; the side-effects must be gated to browse mode.
      visit learn_deck_path(deck)
      expect(page).to have_css(".flashcard-browse__slide:not([hidden]) .flashcard-card")
      expect(page).not_to have_css(".flashcard-card.fb--both-sides")
    end
  end

  # ─── Keyboard shortcuts (BUG 3 regression) ────────────────────────────────

  describe "keyboard shortcuts" do
    def press(*keys)
      keys.each { |k| page.driver.browser.action.send_keys(k).perform }
    end

    it "flips (Space) and records feedback (G) via the keyboard" do
      visit learn_deck_path(deck)
      press(" ")
      expect(page).to have_css(".learn-feedback-bar:not([hidden])")
      press("g")
      expect(page).to have_css(".learn-feedback-bar[hidden]", visible: :all)
    end

    it "still works after a mouse click on a button (focus on a <button>)" do
      visit learn_deck_path(deck)
      find(".fb__flip-bar").click # mouse flip → focus moves to a button
      expect(page).to have_css(".learn-feedback-bar:not([hidden])")
      press("g")
      expect(page).to have_css(".learn-feedback-bar[hidden]", visible: :all)
    end

    it "ignores keys belonging to other modes (number keys do nothing in Learn)" do
      visit learn_deck_path(deck)
      press(" ") # flip → feedback bar shown
      expect(page).to have_css(".learn-feedback-bar:not([hidden])")
      press("3") # a Study-mode key — must be a no-op in Learn (feedback bar stays open)
      expect(page).to have_css(".learn-feedback-bar:not([hidden])")
    end
  end

  # ─── Progress bar reflects mastery, not queue position (BUG 4 regression) ─

  describe "progress bar" do
    def press(*keys)
      keys.each { |k| page.driver.browser.action.send_keys(k).perform }
    end

    it "stays at 0% after a non-mastering feedback (mastery-driven, not position)" do
      visit learn_deck_path(deck)
      press(" ")
      press("c") # confused → masters nothing

      fill = find("[data-flashcard-browse-target='progressFill']", visible: :all)[:style]
      expect(fill).to include("width: 0%")
    end
  end
end
