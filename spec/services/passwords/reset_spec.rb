require "rails_helper"

RSpec.describe Passwords::Reset do
  let(:user) { create(:user) }

  def build_plaintext
    token, plaintext = PasswordResetToken.build_for(user)
    token.save!
    plaintext
  end

  describe ".call" do
    context "with a valid token and valid password" do
      it "updates the password and consumes the token" do
        plaintext = build_plaintext

        result = described_class.call(
          plaintext: plaintext,
          password: "newsecret",
          password_confirmation: "newsecret"
        )

        expect(result).to eq(user)
        expect(result.errors).to be_empty
        expect(user.reload.authenticate("newsecret")).to eq(user)
        expect(PasswordResetToken.find_active_by_plaintext(plaintext)).to be_nil
      end
    end

    context "with a valid token but invalid password" do
      it "returns the user with errors and keeps the token active" do
        plaintext = build_plaintext

        result = described_class.call(
          plaintext: plaintext,
          password: "newsecret",
          password_confirmation: "different"
        )

        expect(result).to eq(user)
        expect(result.errors).not_to be_empty
        expect(PasswordResetToken.find_active_by_plaintext(plaintext)).to be_present
      end
    end

    context "with an invalid token" do
      it "returns nil" do
        expect(
          described_class.call(
            plaintext: "invalid",
            password: "newsecret",
            password_confirmation: "newsecret"
          )
        ).to be_nil
      end
    end
  end
end
