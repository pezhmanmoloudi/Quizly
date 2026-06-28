require "rails_helper"

RSpec.describe PasswordResetService, type: :service do
  let(:user) { create(:user, email_address: "test@example.com") }

  describe ".call" do
    context "when the email is not in the database" do
      it "returns ok: false" do
        result = described_class.call("nobody@example.com")
        expect(result.ok).to be false
      end

      it "returns reason: :user_not_found" do
        result = described_class.call("nobody@example.com")
        expect(result.reason).to eq(:user_not_found)
      end

      it "does not enqueue a mailer" do
        expect { described_class.call("nobody@example.com") }
          .not_to have_enqueued_mail(PasswordsMailer, :reset)
      end
    end

    context "when the email matches a user" do
      before { user }

      it "returns ok: true" do
        result = described_class.call("test@example.com")
        expect(result.ok).to be true
      end

      it "returns reason: :email_sent" do
        result = described_class.call("test@example.com")
        expect(result.reason).to eq(:email_sent)
      end

      it "enqueues the reset mailer" do
        expect { described_class.call("test@example.com") }
          .to have_enqueued_mail(PasswordsMailer, :reset)
      end
    end

    context "with leading/trailing whitespace in the input" do
      before { user }

      it "strips and matches correctly" do
        result = described_class.call("  test@example.com  ")
        expect(result.ok).to be true
      end
    end

    context "with mixed-case email input" do
      before { user }

      it "matches case-insensitively" do
        result = described_class.call("TEST@EXAMPLE.COM")
        expect(result.ok).to be true
      end
    end

    context "when the mailer raises an error" do
      before do
        user
        allow(PasswordsMailer).to receive(:reset).and_raise(RuntimeError, "SMTP error")
      end

      it "returns ok: false" do
        result = described_class.call("test@example.com")
        expect(result.ok).to be false
      end

      it "returns reason: :mailer_error" do
        result = described_class.call("test@example.com")
        expect(result.reason).to eq(:mailer_error)
      end

      it "includes the error message" do
        result = described_class.call("test@example.com")
        expect(result.error).to eq("SMTP error")
      end
    end
  end
end
