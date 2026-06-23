require "rails_helper"

RSpec.describe "Flashcards#suggest", type: :request do
  let(:user)  { create(:user) }
  let(:deck)  { create(:deck, user: user) }
  let(:other) { create(:user) }

  # Public flashcard authored by another user, visible to everyone
  let!(:public_card) do
    create(:flashcard, deck: create(:deck, user: other, term_language: "en", definition_language: "fa"),
                       front_content: "elephant",
                       back_content:  "fil",
                       public: true)
  end

  # Private flashcard — must never appear in suggestions
  let!(:private_card) do
    create(:flashcard, deck: create(:deck, user: other),
                       front_content: "elephant",
                       public: false)
  end

  describe "GET /flashcards/suggest" do
    context "when not authenticated" do
      it "redirects to login" do
        get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "en" }
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "returns a turbo frame partial with matching suggestions" do
        get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "en" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("elephant")
      end

      it "excludes private cards that do not belong to the current user" do
        get flashcard_suggest_path, params: { q: "elephant", field: "front", lang: "en" }
        # private_card belongs to `other` (not the signed-in user) and public: false — excluded.
        # public_card appears exactly once after deduplication.
        expect(response.body.scan("data-autocomplete-word-param").size).to eq(1)
      end

      it "returns suggestions from all languages when lang param is blank" do
        create(:flashcard, deck: create(:deck, user: other, term_language: "de"),
                           front_content: "elefant",
                           public: true)

        get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "" }
        expect(response.body).to include("elephant")
        expect(response.body).to include("elefant")
      end

      it "filters by language" do
        create(:flashcard, deck: create(:deck, user: other, term_language: "de"),
                           front_content: "elefant",
                           public: true)

        get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "en" }
        expect(response.body).to include("elephant")
        expect(response.body).not_to include("elefant")
      end

      it "filters by field (back content)" do
        get flashcard_suggest_path, params: { q: "fil", field: "back", lang: "fa" }
        expect(response.body).to include("fil")
      end

      it "defaults to front_content when field param is unrecognised" do
        get flashcard_suggest_path, params: { q: "ele", field: "INVALID", lang: "en" }
        expect(response.body).to include("elephant")
      end

      it "returns empty frame for a query with no matches" do
        get flashcard_suggest_path, params: { q: "zzznomatch", field: "front", lang: "en" }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("ac-item")
      end

      it "highlights the matched substring" do
        get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "en" }
        expect(response.body).to include("<mark>ele</mark>")
      end

      it "matches non-ASCII (Persian) content" do
        create(:flashcard, deck: create(:deck, user: other, term_language: "fa"),
                           front_content: "فیل",
                           public: true)
        get flashcard_suggest_path, params: { q: "فی", field: "front", lang: "fa" }
        expect(response.body).to include("فیل")
        expect(response.body).to include("<mark>فی</mark>")
      end

      context "own cards" do
        let!(:own_private_card) do
          create(:flashcard, deck: deck, front_content: "elephant", public: false)
        end

        it "includes own private cards in suggestions" do
          get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "en" }
          expect(response.body).to include("elephant")
        end

        it "deduplicates own and public match, returning exactly one result" do
          # own_private_card and public_card both have front_content "elephant"
          get flashcard_suggest_path, params: { q: "ele", field: "front", lang: "en" }
          expect(response.body.scan("data-autocomplete-word-param").size).to eq(1)
        end
      end

      context "cross-field suggestions" do
        it "surfaces a public card matched on the opposite field" do
          create(:flashcard, deck: create(:deck, user: other),
                             front_content: "unrelated",
                             back_content:  "elaborate",
                             public: true)

          get flashcard_suggest_path, params: { q: "ela", field: "front", lang: "" }
          expect(response.body).to include("elaborate")
        end
      end

      context "result limit" do
        it "returns at most 3 suggestions" do
          %w[elaborate element elementary elbow elevated].each do |w|
            create(:flashcard, deck: create(:deck, user: other, term_language: "en"),
                               front_content: w, public: true)
          end

          get flashcard_suggest_path, params: { q: "el", field: "front", lang: "en" }
          expect(response.body.scan("data-autocomplete-word-param").size).to be <= 3
        end
      end
    end
  end
end
