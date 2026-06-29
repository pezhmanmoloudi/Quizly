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

  # ─── Settings persistence ↔ runtime sync ──────────────────────────────────
  #
  # Study mode is server-rendered: the runtime (due query + hidden rating fields) comes from URL
  # params, defaulting to 10. localStorage is the persisted source of truth. On a plain revisit the
  # persisted value must reach the request so runtime + hidden fields + modal all agree.

  describe "persisted settings on revisit" do
    # A few new (repetitions: 0) due cards so the new-cards limit is meaningful.
    before do
      3.times do |i|
        c = create(:flashcard, deck: deck, front_content: "New#{i}", back_content: "B#{i}")
        create(:card_progress, :due, user: user, flashcard: c, repetitions: 0)
      end
    end

    def seed_study_settings(new_limit:, priority: "due")
      visit study_deck_path(deck) # establish origin so localStorage is writable
      page.execute_script(
        "window.localStorage.setItem('quizly.study.settings', " \
        "JSON.stringify({ new_limit: '#{new_limit}', priority: '#{priority}' }))"
      )
    end

    def open_settings
      find("[data-action='click->study-mode#openSettings']").click
      expect(page).to have_css(".study-options.is-open")
    end

    it "reapplies the persisted value to the runtime on a plain revisit (no URL params)" do
      seed_study_settings(new_limit: 5)

      visit study_deck_path(deck) # no params

      # The controller navigates once to carry the persisted value into the request.
      expect(page).to have_current_path(/new_limit=5/)
      # Runtime: the hidden rating field submitted on every grade now uses 5.
      expect(find("input[name='new_limit']", visible: :all).value).to eq("5")
      # UI: the modal select agrees.
      open_settings
      expect(find("#study_new_limit").value).to eq("5")
    end

    it "keeps URL params authoritative over localStorage (no override, no nav)" do
      seed_study_settings(new_limit: 5)

      visit study_deck_path(deck, new_limit: 20)

      expect(page).to have_current_path(/new_limit=20/)
      expect(find("input[name='new_limit']", visible: :all).value).to eq("20")
      open_settings
      expect(find("#study_new_limit").value).to eq("20")
    end

    it "falls back to the server default when nothing is persisted (no nav)" do
      visit study_deck_path(deck)
      page.execute_script("window.localStorage.removeItem('quizly.study.settings')")

      visit study_deck_path(deck)

      expect(page.current_url).not_to include("new_limit")
      expect(find("input[name='new_limit']", visible: :all).value).to eq("10")
      open_settings
      expect(find("#study_new_limit").value).to eq("10")
    end

    it "persists through the modal and survives leaving and re-entering Study" do
      visit study_deck_path(deck)
      open_settings
      select "5", from: "study_new_limit"
      click_button I18n.t("study_modes.study.apply_settings")

      # Applying drives the runtime immediately and saves to localStorage.
      expect(page).to have_current_path(/new_limit=5/)

      # Leave to the deck, then re-enter Study with a plain link (no params).
      visit deck_path(deck)
      visit study_deck_path(deck)

      expect(page).to have_current_path(/new_limit=5/)
      expect(find("input[name='new_limit']", visible: :all).value).to eq("5")
    end

    it "does not reset mid-session: rating a card keeps the persisted limit" do
      seed_study_settings(new_limit: 5)
      visit study_deck_path(deck)
      expect(page).to have_current_path(/new_limit=5/)

      click_button I18n.t("study_modes.study.show_answer")
      find(".rating-btn--good").click

      # After the rating redirect the runtime still carries 5 (no fallback to 10, no nav loop).
      expect(page).to have_current_path(/new_limit=5/)
      expect(find("input[name='new_limit']", visible: :all).value).to eq("5")
    end
  end

  # ─── Keyboard shortcuts (BUG 3 regression) ────────────────────────────────

  describe "keyboard shortcuts" do
    def press(*keys)
      keys.each { |k| page.driver.browser.action.send_keys(k).perform }
    end

    it "reveals (Space) and rates (1-4) via the keyboard" do
      visit study_deck_path(deck)
      press(" ")
      expect(page).to have_css(".study-card__back:not([hidden])")
      press("3") # good
      expect(page).to have_content(I18n.t("study_modes.study.summary_title"))
    end

    it "ignores keys belonging to other modes (KeyboardManager routes only the active map)" do
      visit study_deck_path(deck)
      press(" ")  # reveal
      press("g")  # a Learn-mode key — must be a no-op in Study
      expect(page).to have_css(".study-card__back:not([hidden])")
      expect(page).not_to have_content(I18n.t("study_modes.study.summary_title"))
      press("3")  # the Study key still works
      expect(page).to have_content(I18n.t("study_modes.study.summary_title"))
    end

    it "still works after a mouse click and across a Turbo frame swap" do
      card2 = create(:flashcard, deck: deck, front_content: "Au revoir", back_content: "Goodbye")
      create(:card_progress, :due, user: user, flashcard: card2)

      visit study_deck_path(deck)
      # Reveal by mouse (focus lands on the show button), then rate by keyboard.
      click_button I18n.t("study_modes.study.show_answer")
      press("3")

      # After the Turbo frame swap, the keyboard must keep working on the next card.
      expect(page).to have_content("Au revoir") # wait for the next card to settle in the frame
      press(" ")
      expect(page).to have_css(".study-card__back:not([hidden])")
      press("3")
      expect(page).to have_content(I18n.t("study_modes.study.summary_title"))
    end
  end

  # ─── Progress bar reflects session state (BUG 4 regression) ───────────────

  describe "progress bar" do
    it "advances after a rating (rendered inside the Turbo frame)" do
      card2 = create(:flashcard, deck: deck, front_content: "Au revoir", back_content: "Goodbye")
      create(:card_progress, :due, user: user, flashcard: card2)

      visit study_deck_path(deck)
      expect(page).to have_css(".study-island__progress-wrap")
      expect(page).to have_content("0%") # 0 of 2 done

      click_button I18n.t("study_modes.study.show_answer")
      find(".rating-btn--good").click

      # Frame re-renders the next card AND the updated progress.
      expect(page).to have_content("50%") # 1 of 2 done
    end
  end
end
