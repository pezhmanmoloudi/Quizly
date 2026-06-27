OmniAuth.config.test_mode = true

module OmniauthHelpers
  def mock_google_auth(uid: "google-uid-123", email: "google-user@example.com", name: "Google User")
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name }
    )
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    Rails.application.env_config["omniauth.auth"] = auth
    auth
  end

  def clear_google_auth
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    Rails.application.env_config["omniauth.auth"] = nil
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers, type: :request

  config.after(:each, type: :request) { clear_google_auth }
end
