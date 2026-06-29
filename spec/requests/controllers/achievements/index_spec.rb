require "rails_helper"

describe "Achievements#index", type: :request do
  let(:user) { create(:user) }

  describe "GET /achievements" do
    context "when unauthenticated" do
      it "redirects to login" do
        get achievements_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "returns 200 OK" do
        get achievements_path
        expect(response).to have_http_status(:ok)
      end

      it "displays the achievements title" do
        get achievements_path
        expect(response.body).to include(I18n.t("achievements.title"))
      end

      context "without any earned badges" do
        before { create_list(:badge, 5) }

        it "displays earned count as 0" do
          get achievements_path
          expect(response.body).to include("0 of 5 badges earned")
        end

        it "still shows badge grid with locked badges" do
          get achievements_path
          expect(response.body).to include("badge-card--locked")
        end
      end

      context "with no badges at all in the system" do
        it "displays the empty state message" do
          get achievements_path
          expect(response.body).to include(I18n.t("achievements.no_badges"))
        end
      end

      context "with earned badges" do
        let!(:badges) { create_list(:badge, 5) }

        before do
          badges[0..2].each do |badge|
            create(:user_badge, user:, badge:)
          end
        end

        it "displays correct earned count" do
          get achievements_path
          expect(response.body).to include("3 of 5 badges earned")
        end

        it "renders all badge cards" do
          get achievements_path
          badges.each do |badge|
            expect(response.body).to include(badge.icon)
            expect(response.body).to include(badge.name)
          end
        end

        it "marks earned badges with earned styling" do
          get achievements_path
          expect(response.body).to include("badge-card--earned")
        end

        it "marks locked badges with locked styling" do
          get achievements_path
          expect(response.body).to include("badge-card--locked")
        end
      end
    end
  end
end
