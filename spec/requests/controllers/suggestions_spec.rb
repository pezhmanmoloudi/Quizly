require "rails_helper"

RSpec.describe "Suggestions#index", type: :request do
  before do
    allow(DictionaryAdapter).to receive(:fetch).and_return(["hello", "help", "house"])
  end

  describe "GET /suggestions" do
    it "returns 200 with a suggestions array" do
      get suggestions_path, params: { q: "hel" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["suggestions"]).to eq(["hello", "help", "house"])
    end

    it "returns empty array when q is shorter than 2 characters" do
      get suggestions_path, params: { q: "h" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["suggestions"]).to eq([])
      expect(DictionaryAdapter).not_to have_received(:fetch)
    end

    it "returns empty array when q is longer than 50 characters" do
      get suggestions_path, params: { q: "a" * 51 }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["suggestions"]).to eq([])
      expect(DictionaryAdapter).not_to have_received(:fetch)
    end

    it "returns empty array when q is absent" do
      get suggestions_path
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["suggestions"]).to eq([])
    end

    it "does not require authentication" do
      get suggestions_path, params: { q: "hel" }
      expect(response).not_to redirect_to(login_path)
    end

    it "passes the lang param to the query" do
      allow(DictionaryAdapter).to receive(:fetch)
        .with(q: "hel", lang: "de", limit: 8)
        .and_return(["hallo", "helfen"])
      get suggestions_path, params: { q: "hel", lang: "de" }
      expect(response.parsed_body["suggestions"]).to eq(["hallo", "helfen"])
    end

    it "returns empty array when the adapter returns nothing" do
      allow(DictionaryAdapter).to receive(:fetch).and_return([])
      get suggestions_path, params: { q: "xyz" }
      expect(response.parsed_body["suggestions"]).to eq([])
    end
  end
end
