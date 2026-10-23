require "rails_helper"

RSpec.describe Auth::Search do
  describe ".find_active_password_reset_token" do
    let(:user) { create(:user) }

    it "returns the active token matching the plaintext" do
      token, plaintext = Auth::PasswordResetToken.build_for(user)
      token.save!

      expect(described_class.find_active_password_reset_token(plaintext)).to eq(token)
    end

    it "returns nil for a wrong plaintext" do
      Auth::PasswordResetToken.build_for(user).first.save!

      expect(described_class.find_active_password_reset_token("wrong")).to be_nil
    end

    it "returns nil for an expired token" do
      token, plaintext = Auth::PasswordResetToken.build_for(user)
      token.update!(expires_at: 1.minute.ago)
      token.save!

      expect(described_class.find_active_password_reset_token(plaintext)).to be_nil
    end

    it "returns nil for a used token" do
      token, plaintext = Auth::PasswordResetToken.build_for(user)
      token.save!
      token.mark_used!

      expect(described_class.find_active_password_reset_token(plaintext)).to be_nil
    end
  end

  describe ".find_session_by_plaintext" do
    let(:user) { create(:user) }

    it "returns the active session matching the plaintext" do
      session, plaintext = Auth::Session.build_for(user)
      session.save!

      expect(described_class.find_session_by_plaintext(plaintext)).to eq(session)
    end

    it "returns nil for a blank token" do
      expect(described_class.find_session_by_plaintext(nil)).to be_nil
      expect(described_class.find_session_by_plaintext("")).to be_nil
    end

    it "returns nil for a wrong plaintext" do
      Auth::Session.build_for(user).first.save!

      expect(described_class.find_session_by_plaintext("wrong")).to be_nil
    end

    it "returns nil for an expired session" do
      session, plaintext = Auth::Session.build_for(user)
      session.update!(expires_at: 1.minute.ago)

      expect(described_class.find_session_by_plaintext(plaintext)).to be_nil
    end
  end
end
