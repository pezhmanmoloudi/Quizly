require "rails_helper"

RSpec.describe "Folders#show", type: :request do
  let(:user)   { create(:user) }
  let(:folder) { create(:folder, user: user, name: "Spanish") }

  describe "GET /folders/:id" do
    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns 200" do
        get folder_path(folder)
        expect(response).to have_http_status(:ok)
      end

      it "displays the folder name" do
        get folder_path(folder)
        expect(response.body).to include("Spanish")
      end

      it "shows decks in the folder" do
        deck = create(:deck, user: user, name: "Vocab")
        create(:deck_folder, deck: deck, folder: folder)
        get folder_path(folder)
        expect(response.body).to include("Vocab")
      end

      it "shows empty state when no decks" do
        get folder_path(folder)
        expect(response.body).to include("folder-#{folder.id}-empty-state")
      end

      it "renders rename and delete options" do
        get folder_path(folder)
        expect(response.body).to include(I18n.t("folders.show.rename"))
        expect(response.body).to include(I18n.t("folders.show.delete"))
      end

      it "renders the folder icon header" do
        get folder_path(folder)
        expect(response.body).to include("folder-show-header")
      end

      it "renders the All filter chip" do
        get folder_path(folder)
        expect(response.body).to include(I18n.t("folders.show.all_filter"))
      end

      it "renders the Add tag chip" do
        get folder_path(folder)
        expect(response.body).to include(I18n.t("folders.show.add_tag"))
      end

      it "shows the add study materials button" do
        get folder_path(folder)
        expect(response.body).to include(I18n.t("folders.show.add_study_materials"))
      end

      it "renders a chip for each folder tag" do
        create(:folder_tag, folder: folder, name: "Grammar")
        get folder_path(folder)
        expect(response.body).to include("Grammar")
      end

      context "when filtering by a tag" do
        let(:tag)     { create(:folder_tag, folder: folder, name: "Grammar") }
        let(:tagged)  { create(:deck, user: user, name: "TaggedDeck") }
        let(:other)   { create(:deck, user: user, name: "OtherDeck") }

        before do
          create(:deck_folder, deck: tagged, folder: folder)
          create(:deck_folder, deck: other, folder: folder)
          create(:deck_folder_tag, folder_tag: tag, deck: tagged)
        end

        # The folder's deck list region only — the sidebar lists every deck.
        def deck_region(body)
          start  = body.index("folder-#{folder.id}-decks")
          finish = body.index("folder-show-fixed-bar")
          body[start...finish]
        end

        it "shows only decks assigned to that tag" do
          get folder_path(folder, tag_id: tag.id)
          region = deck_region(response.body)
          expect(region).to include("TaggedDeck")
          expect(region).not_to include("OtherDeck")
        end

        it "shows all decks when no tag is selected" do
          get folder_path(folder)
          region = deck_region(response.body)
          expect(region).to include("TaggedDeck")
          expect(region).to include("OtherDeck")
        end

        it "ignores a tag_id from another folder" do
          foreign_tag = create(:folder_tag, folder: create(:folder, user: user))
          get folder_path(folder, tag_id: foreign_tag.id)
          region = deck_region(response.body)
          expect(region).to include("TaggedDeck")
          expect(region).to include("OtherDeck")
        end
      end
    end

    context "when authenticated as another user" do
      before { sign_in(create(:user)) }

      it "redirects away when folder belongs to a different user" do
        get folder_path(folder)
        expect(response).to redirect_to(decks_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get folder_path(folder)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
