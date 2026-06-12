require "rails_helper"

RSpec.describe "Passwords#new", type: :request do
  describe "GET /forgot-password" do
    it "returns 200" do
      get forgot_password_path
      expect(response).to have_http_status(:ok)
    end

    it "is accessible without authentication" do
      get forgot_password_path
      expect(response).not_to redirect_to(login_path)
    end
  end
end
