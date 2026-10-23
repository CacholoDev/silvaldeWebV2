require "rails_helper"

RSpec.describe Passwords::RequestReset do
  describe ".call" do
    context "with an existing user" do
      let(:user) { create(:user) }

      it "creates a password reset token for the user" do
        expect {
          described_class.call(email: user.email)
        }.to change(PasswordResetToken, :count).by(1)

        expect(PasswordResetToken.last.user).to eq(user)
      end
    end

    context "with an unknown email" do
      it "does not create a token" do
        expect {
          described_class.call(email: "unknown@example.com")
        }.not_to change(PasswordResetToken, :count)
      end
    end
  end
end
