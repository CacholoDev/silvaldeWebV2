require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:token) { "plaintext-token" }
    let(:mail) { described_class.with(user: user, token: token).reset }

    it "renders the subject" do
      expect(mail.subject).to eq(I18n.t("passwords.mailer.subject"))
    end

    it "sends to the user's email" do
      expect(mail.to).to eq([ user.email ])
    end

    it "includes the reset link with the token" do
      # Parts are quoted-printable encoded; decode before matching the URL.
      decoded_parts = mail.parts.map { |part| part.body.decoded }

      expect(decoded_parts.join).to include(edit_password_url(token: token))
    end
  end
end
