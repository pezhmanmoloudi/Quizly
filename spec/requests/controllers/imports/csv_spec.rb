require "rails_helper"

RSpec.describe "Imports#csv", type: :request do
  let(:user) { create(:user) }
  let(:deck) { create(:deck, user: user) }

  before { sign_in(user) }

  def upload(content, filename: "cards.csv", type: "text/csv")
    Rack::Test::UploadedFile.new(
      StringIO.new(content),
      type,
      original_filename: filename
    )
  end

  describe "POST /decks/:deck_id/import/csv" do
    it "creates flashcard records via CsvImporter.call" do
      expect {
        post csv_deck_import_path(deck), params: { file: upload("front,back\nHello,Hola\nGoodbye,Adiós") }
      }.to change(Flashcard, :count).by(2)
    end

    it "redirects to the deck editor after successful html import" do
      post csv_deck_import_path(deck), params: { file: upload("front,back\nHello,Hola") }
      expect(response).to redirect_to(edit_deck_path(deck))
    end

    it "redirects to deck with alert when no file is provided" do
      post csv_deck_import_path(deck), params: {}
      expect(response).to redirect_to(deck_path(deck))
      follow_redirect!
      expect(response.body).to include(I18n.t("imports.no_file"))
    end

    it "redirects to deck with alert when CSV has only one column and no data" do
      post csv_deck_import_path(deck), params: { file: upload("only_one_column") }
      expect(response).to redirect_to(deck_path(deck))
      follow_redirect!
      expect(response.body).to include(I18n.t("imports.csv_too_few_columns"))
    end

    it "redirects to deck with alert when all content rows are blank" do
      post csv_deck_import_path(deck), params: { file: upload("front,back\n,\n,") }
      expect(response).to redirect_to(deck_path(deck))
      follow_redirect!
      expect(response.body).to include(I18n.t("imports.csv_no_valid_rows"))
    end

    it "denies access to another user's deck" do
      other_deck = create(:deck, user: create(:user))
      post csv_deck_import_path(other_deck), params: { file: upload("front,back\nA,B") }
      expect(response).to redirect_to(decks_path)
    end
  end
end
