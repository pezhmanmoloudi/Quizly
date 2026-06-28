OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    google_opts = { scope: "email profile", prompt: "select_account" }
    google_opts[:redirect_uri] = ENV["GOOGLE_REDIRECT_URI"] if ENV["GOOGLE_REDIRECT_URI"].present?

    provider :google_oauth2,
             ENV["GOOGLE_CLIENT_ID"],
             ENV["GOOGLE_CLIENT_SECRET"],
             **google_opts
  else
    Rails.logger.warn "[Auth] Google OAuth disabled — GOOGLE_CLIENT_ID/SECRET not set"
  end

  if ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
    github_opts = { scope: "user:email" }
    github_opts[:redirect_uri] = ENV["GITHUB_REDIRECT_URI"] if ENV["GITHUB_REDIRECT_URI"].present?

    provider :github,
             ENV["GITHUB_CLIENT_ID"],
             ENV["GITHUB_CLIENT_SECRET"],
             **github_opts
  else
    Rails.logger.warn "[Auth] GitHub OAuth disabled — GITHUB_CLIENT_ID/SECRET not set"
  end
end
