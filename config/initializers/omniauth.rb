OmniAuth.config.logger = Rails.logger

if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    options = {
      scope: "email profile",
      prompt: "select_account"
    }
    options[:redirect_uri] = ENV["GOOGLE_REDIRECT_URI"] if ENV["GOOGLE_REDIRECT_URI"].present?

    provider :google_oauth2,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      **options
  end
end
