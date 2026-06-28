require "database_cleaner/active_record"

module SystemTestHelpers
  # Signs in by injecting a signed session cookie directly — bypasses the login
  # form and the rate_limit before_action entirely.
  def sign_in_as(user)
    session_record = user.sessions.create!(user_agent: "SystemTest", ip_address: "127.0.0.1")

    key_generator = ActiveSupport::CachingKeyGenerator.new(
      ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000)
    )
    salt   = Rails.application.config.action_dispatch.signed_cookie_salt || "signed cookie"
    digest = Rails.application.config.action_dispatch.signed_cookie_digest || "SHA1"
    secret = key_generator.generate_key(salt)
    signed_value = ActiveSupport::MessageVerifier.new(secret, digest: digest)
                                                  .generate(session_record.id.to_s)

    visit root_path
    page.driver.browser.manage.add_cookie(
      name: "session_id",
      value: signed_value,
      path: "/",
      http_only: true
    )
    visit dashboard_path
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    if example.metadata[:type] == :system
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
    Capybara.reset_session!
  end

  config.include SystemTestHelpers, type: :system
end
