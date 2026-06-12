require "rails_helper"

RSpec.describe "Registrations#create", type: :request do
  describe "POST /signup" do
    context "with valid params" do
      it "creates user and redirects to dashboard" do
        post signup_path, params: {
          user: { email_address: "new@example.com", password: "password123", password_confirmation: "password123" }
        }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "with invalid params" do
      it "re-renders with unprocessable_entity status" do
        post signup_path, params: {
          user: { email_address: "", password: "password123", password_confirmation: "password123" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders inline error span for blank email" do
        post signup_path, params: {
          user: { email_address: "", password: "password123", password_confirmation: "password123" }
        }
        expect(response.body).to include('class="field-error"')
        expect(response.body).to include('data-server-error="true"')
      end

      it "does not render block-level form errors div" do
        post signup_path, params: {
          user: { email_address: "", password: "password123", password_confirmation: "password123" }
        }
        expect(response.body).not_to include('class="form-errors"')
      end

      it "renders inline error span for short password" do
        post signup_path, params: {
          user: { email_address: "test@example.com", password: "short", password_confirmation: "short" }
        }
        expect(response.body).to include('data-server-error="true"')
      end

      it "renders inline error span for mismatched password confirmation" do
        post signup_path, params: {
          user: { email_address: "test@example.com", password: "password123", password_confirmation: "different456" }
        }
        expect(response.body).to include('data-server-error="true"')
      end

      it "includes aria-live polite on error spans" do
        post signup_path, params: {
          user: { email_address: "", password: "password123", password_confirmation: "password123" }
        }
        expect(response.body).to include('aria-live="polite"')
      end
    end

    context "when already authenticated" do
      let(:user) { create(:user) }

      it "redirects to dashboard" do
        sign_in(user)
        get signup_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "rate limiting" do
      before { ActionController::Base.cache_store.clear }

      it "allows requests up to the limit" do
        10.times do
          post signup_path, params: {
            user: { email_address: "", password: "password123", password_confirmation: "password123" }
          }
          expect(response).not_to redirect_to(signup_url)
        end
      end

      it "redirects with alert after exceeding the limit" do
        10.times do
          post signup_path, params: {
            user: { email_address: "", password: "password123", password_confirmation: "password123" }
          }
        end
        post signup_path, params: {
          user: { email_address: "overflow@example.com", password: "password123", password_confirmation: "password123" }
        }
        expect(response).to redirect_to(signup_url)
        expect(flash[:alert]).to eq(I18n.t("registrations.errors.rate_limited"))
      end
    end
  end
end
