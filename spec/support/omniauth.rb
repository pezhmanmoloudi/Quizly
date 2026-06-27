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

  def mock_github_auth(uid: "github-uid-123", email: "github-user@example.com", name: "GitHub User")
    auth = OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: { email: email, name: name }
    )
    OmniAuth.config.mock_auth[:github] = auth
    Rails.application.env_config["omniauth.auth"] = auth
    auth
  end

  def clear_github_auth
    OmniAuth.config.mock_auth[:github] = nil
    Rails.application.env_config["omniauth.auth"] = nil
  end
end

RSpec.configure do |config|
  config.include OmniauthHelpers, type: :request

  config.after(:each, type: :request) do
    clear_google_auth
    clear_github_auth
  end
end
