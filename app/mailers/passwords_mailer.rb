class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    I18n.with_locale(user.locale) do
      mail subject: I18n.t("passwords_mailer.reset_subject"), to: user.email_address
    end
  end
end
