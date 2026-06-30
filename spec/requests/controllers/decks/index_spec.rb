require "rails_helper"

RSpec.describe "Decks#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /decks" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200" do
        get decks_path
        expect(response).to have_http_status(:ok)
      end

      it "shows only decks belonging to the current user" do
        own_deck   = create(:deck, user: user, name: "My Deck")
        other_deck = create(:deck, user: create(:user), name: "Other Deck")
        get decks_path
        expect(response.body).to include("My Deck")
        expect(response.body).not_to include("Other Deck")
      end

      it "shows empty state when user has no decks" do
        get decks_path
        expect(response.body).to include("No decks yet")
      end

      # The results region only; the sidebar nav (#sidebar-decks) lists all the
      # user's decks regardless of the query, so assert against the index section.
      def index_section
        Nokogiri::HTML(response.body).at_css("#decks-index-section")&.text.to_s
      end

      it "filters the user's decks by the search query" do
        create(:deck, user: user, name: "Spanish Basics")
        create(:deck, user: user, name: "French Vocab")
        get decks_path, params: { q: "Spanish" }
        expect(index_section).to include("Spanish Basics")
        expect(index_section).not_to include("French Vocab")
      end

      it "only searches within the current user's decks" do
        create(:deck, user: user, name: "My Biology Deck")
        create(:deck, user: create(:user), name: "Their Biology Deck")
        get decks_path, params: { q: "Biology" }
        expect(index_section).to include("My Biology Deck")
        expect(index_section).not_to include("Their Biology Deck")
      end

      it "shows the search empty state when nothing matches the query" do
        create(:deck, user: user, name: "Spanish Basics")
        get decks_path, params: { q: "nonexistent xyz" }
        expect(response.body).to include("No decks found for")
      end

      it "renders sort dropdown" do
        get decks_path
        expect(response.body).to include("auto-submit")
      end

      it "points the navbar search at the My Decks index (context-aware)" do
        get decks_path
        expect(response.body).to match(/<form[^>]*class="topbar__search"[^>]*action="#{Regexp.escape(decks_path)}"/)
      end

      it "keeps the navbar search input populated with the current query" do
        create(:deck, user: user, name: "Spanish Basics")
        get decks_path, params: { q: "Spanish" }
        expect(response.body).to include('value="Spanish"')
      end

      it "sorts decks alphabetically with sort=az" do
        create(:deck, user: user, name: "Zebra")
        create(:deck, user: user, name: "Apple")
        get decks_path, params: { sort: "az" }
        expect(response.body.index("Apple")).to be < response.body.index("Zebra")
      end

      it "defaults to recent sort without sort param" do
        get decks_path
        expect(response).to have_http_status(:ok)
      end

      it "accepts most_due sort param without error" do
        create(:deck, user: user)
        get decks_path, params: { sort: "most_due" }
        expect(response).to have_http_status(:ok)
      end

      it "does not render Study, Edit, or Delete buttons on deck tiles" do
        create(:deck, user: user, name: "My Deck")
        get decks_path
        expect(response.body).not_to include("study_deck")
        expect(response.body).not_to include("edit_deck")
        expect(response.body).not_to include("inline-confirm")
      end

      it "renders deck tiles as clickable links to the deck show page" do
        deck = create(:deck, user: user, name: "Clickable Deck")
        get decks_path
        expect(response.body).to include(deck_path(deck))
        expect(response.body).to include("deck-row")
      end

      it "paginates decks at 12 per page" do
        create_list(:deck, DecksController::DECK_INDEX_PER_PAGE + 1, user: user)
        get decks_path
        expect(response.body).to include("pagination")
      end

      it "does not show pagination when decks fit on one page" do
        create_list(:deck, 3, user: user)
        get decks_path
        expect(response.body).not_to include("pagination__btn")
      end

      it "includes from_page param in deck tile links" do
        create(:deck, user: user)
        get decks_path
        expect(response.body).to include("from_page=1")
      end

      it "assigns last_studied_dates as a hash" do
        deck = create(:deck, user: user)
        create(:study_session, user: user, deck: deck, started_at: 3.days.ago)
        get decks_path
        expect(controller.instance_variable_get(:@last_studied_dates)).to be_a(Hash)
      end

      it "shows studied_time for decks with a study session" do
        deck = create(:deck, user: user)
        create(:study_session, user: user, deck: deck, started_at: 2.days.ago)
        get decks_path
        expect(response.body).to include(I18n.t("decks.deck_card.studied_label"))
      end

      it "shows an open lock icon for own password-protected decks" do
        create(:deck, :password_protected, user: user)
        get decks_path
        expect(response.body).to include("deck-row__lock-icon--open")
      end

      it "shows the draft badge for incomplete decks" do
        create(:deck, user: user)
        get decks_path
        expect(response.body).to include("deck-row__draft-badge")
        expect(response.body).to include(I18n.t("decks.deck_card.draft"))
      end

      it "does not show the draft badge for complete decks" do
        deck = create(:deck, user: user)
        create(:flashcard, deck: deck)
        get decks_path
        expect(response.body).not_to include("deck-tile__draft-badge")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get decks_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
