class OAuthCallbackService
  Result = Data.define(:ok, :user, :reason, :error)

  def self.call(provider, auth)
    Rails.logger.info "[Auth][OAuth] #{provider} callback started"

    unless auth.present? && auth.uid.present? && auth.info&.email.present?
      Rails.logger.warn "[Auth][OAuth] #{provider} — invalid auth hash (uid=#{auth&.uid.inspect} email=#{auth&.info&.email.inspect})"
      return Result.new(ok: false, user: nil, reason: :invalid_auth_hash, error: "Missing uid or email in auth hash")
    end

    Rails.logger.info "[Auth][OAuth] #{provider} auth hash valid — uid=#{auth.uid} email=#{auth.info.email}"

    user = case provider.to_sym
    when :google_oauth2 then User.find_or_create_from_google(auth)
    when :github        then User.find_or_create_from_github(auth)
    else
      Rails.logger.error "[Auth][OAuth] Unknown provider: #{provider}"
      return Result.new(ok: false, user: nil, reason: :unknown_provider, error: "Unknown provider: #{provider}")
    end

    if user.persisted?
      Rails.logger.info "[Auth][OAuth] #{provider} — user persisted: id=#{user.id} email=#{user.email_address}"
      Result.new(ok: true, user: user, reason: :success, error: nil)
    else
      errors = user.errors.full_messages.join(", ")
      Rails.logger.warn "[Auth][OAuth] #{provider} — user not persisted: #{errors}"
      Result.new(ok: false, user: nil, reason: :user_invalid, error: errors)
    end
  rescue => e
    Rails.logger.error "[Auth][OAuth] #{provider} callback raised: #{e.class} — #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    Result.new(ok: false, user: nil, reason: :exception, error: e.message)
  end
end
