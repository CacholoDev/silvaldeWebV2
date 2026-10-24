require "rails_helper"

RSpec.describe Auth::Reset do
  let(:user) { create(:user) }

  def build_plaintext
    token, plaintext = Auth::PasswordResetToken.build_for(user)
    token.save!
    plaintext
  end

  describe ".call" do
    context "when the user has open sessions and other outstanding tokens" do
      it "revokes every session and consumes every token" do
        create(:session, user: user)
        create(:session, user: user)
        other_token = create(:password_reset_token, user: user)
        plaintext = build_plaintext

        result = described_class.call(
          plaintext: plaintext,
          password: "newsecret",
          password_confirmation: "newsecret"
        )

        expect(result.errors).to be_empty
        expect(Auth::Session.where(user: user).count).to eq(0)
        expect(other_token.reload).to be_used
      end
    end

    context "when the token was already consumed" do
      it "returns nil and leaves the password unchanged" do
        plaintext = build_plaintext
        described_class.call(
          plaintext: plaintext,
          password: "newsecret",
          password_confirmation: "newsecret"
        )

        second = described_class.call(
          plaintext: plaintext,
          password: "othersecret",
          password_confirmation: "othersecret"
        )

        expect(second).to be_nil
        expect(user.reload.authenticate("othersecret")).to be(false)
      end
    end

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
        expect(Auth::Search.find_active_password_reset_token(plaintext)).to be_nil
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
        expect(Auth::Search.find_active_password_reset_token(plaintext)).to be_present
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
