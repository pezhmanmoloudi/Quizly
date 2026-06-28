require "rails_helper"

RSpec.describe OauthCallbackService, type: :service do
  def google_auth(uid: "g-uid-1", email: "google@example.com", name: "Google User")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name }
    )
  end

  def github_auth(uid: "gh-uid-1", email: "github@example.com", name: "GitHub User")
    OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: { email: email, name: name }
    )
  end

  describe ".call" do
    context "with an invalid auth hash (missing uid)" do
      let(:auth) { OmniAuth::AuthHash.new(provider: "google_oauth2", uid: nil, info: { email: "x@y.com" }) }

      it "returns ok: false" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.ok).to be false
      end

      it "returns reason: :invalid_auth_hash" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.reason).to eq(:invalid_auth_hash)
      end
    end

    context "with an invalid auth hash (missing email)" do
      let(:auth) { OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "uid-1", info: {}) }

      it "returns ok: false" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.ok).to be false
      end

      it "returns reason: :invalid_auth_hash" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.reason).to eq(:invalid_auth_hash)
      end
    end

    context "with an unknown provider" do
      it "returns ok: false" do
        result = described_class.call(:twitter, google_auth)
        expect(result.ok).to be false
      end

      it "returns reason: :unknown_provider" do
        result = described_class.call(:twitter, google_auth)
        expect(result.reason).to eq(:unknown_provider)
      end
    end

    context "with valid Google auth" do
      let(:auth) { google_auth }

      it "returns ok: true" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.ok).to be true
      end

      it "returns reason: :success" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.reason).to eq(:success)
      end

      it "returns the persisted user" do
        result = described_class.call(:google_oauth2, auth)
        expect(result.user).to be_persisted
      end
    end

    context "with valid GitHub auth" do
      let(:auth) { github_auth }

      it "returns ok: true" do
        result = described_class.call(:github, auth)
        expect(result.ok).to be true
      end

      it "returns reason: :success" do
        result = described_class.call(:github, auth)
        expect(result.reason).to eq(:success)
      end

      it "returns the persisted user" do
        result = described_class.call(:github, auth)
        expect(result.user).to be_persisted
      end
    end

    context "when the user cannot be persisted" do
      let(:invalid_user) { User.new }

      before do
        allow(User).to receive(:find_or_create_from_google).and_return(invalid_user)
      end

      it "returns ok: false" do
        result = described_class.call(:google_oauth2, google_auth)
        expect(result.ok).to be false
      end

      it "returns reason: :user_invalid" do
        result = described_class.call(:google_oauth2, google_auth)
        expect(result.reason).to eq(:user_invalid)
      end
    end

    context "when User.find_or_create_from_google raises" do
      before do
        allow(User).to receive(:find_or_create_from_google).and_raise(RuntimeError, "DB error")
      end

      it "returns ok: false" do
        result = described_class.call(:google_oauth2, google_auth)
        expect(result.ok).to be false
      end

      it "returns reason: :exception" do
        result = described_class.call(:google_oauth2, google_auth)
        expect(result.reason).to eq(:exception)
      end

      it "captures the error message" do
        result = described_class.call(:google_oauth2, google_auth)
        expect(result.error).to eq("DB error")
      end
    end
  end
end
