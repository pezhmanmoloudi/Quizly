module AuthenticationHelpers
  def sign_in(user)
    post login_path, params: {
      email_address: user.email_address,
      password: "password123"
    }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
