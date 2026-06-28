class PasswordResetService
  Result = Data.define(:ok, :reason, :error)

  def self.call(email_address)
    email = email_address.to_s.strip.downcase

    Rails.logger.info "[Auth][PasswordReset] Request received for email='#{email}'"

    user = User.find_by(email_address: email)

    unless user
      Rails.logger.warn "[Auth][PasswordReset] password reset requested for non-existing email='#{email}'"
      return Result.new(ok: false, reason: :user_not_found, error: nil)
    end

    Rails.logger.info "[Auth][PasswordReset] user found id=#{user.id} email='#{email}' — queuing mailer"
    PasswordsMailer.reset(user).deliver_later
    Rails.logger.info "[Auth][PasswordReset] Mailer queued successfully for user id=#{user.id}"

    Result.new(ok: true, reason: :email_sent, error: nil)
  rescue => e
    Rails.logger.error "[Auth][PasswordReset] FAILED email='#{email}': #{e.class} — #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    Result.new(ok: false, reason: :mailer_error, error: e.message)
  end
end
