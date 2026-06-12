require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:mail) { described_class.reset(user) }

  it "sends to the user's email address" do
    expect(mail.to).to eq([user.email_address])
  end

  it "has the correct subject" do
    expect(mail.subject).to eq(I18n.t("passwords_mailer.reset_subject"))
  end

  it "includes a reset URL in the HTML body" do
    expect(mail.html_part.body.encoded).to include("/reset-password/")
  end

  it "includes a reset URL in the text body" do
    expect(mail.text_part.body.encoded).to include("/reset-password/")
  end

  it "sends in the user's preferred locale" do
    user.update!(locale: "fr")
    fr_mail = described_class.reset(user)
    expect(fr_mail.subject).to eq(I18n.t("passwords_mailer.reset_subject", locale: "fr"))
  end
end
