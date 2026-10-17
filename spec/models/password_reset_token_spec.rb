require "rails_helper"

RSpec.describe PasswordResetToken, type: :model do
  describe "associations" do
    it "belongs to a user" do
      expect(PasswordResetToken.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "is invalid without a user" do
      token = build(:password_reset_token, user: nil)
      expect(token).not_to be_valid
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:password_reset_token)).to be_valid
    end

    it "requires a token_digest" do
      token = build(:password_reset_token, token_digest: nil)
      expect(token).not_to be_valid
    end

    it "requires an expires_at" do
      token = build(:password_reset_token, expires_at: nil)
      expect(token).not_to be_valid
    end

    it "enforces unique token_digest" do
      digest = BCrypt::Password.create("shared-token")
      create(:password_reset_token, token_digest: digest)
      duplicate = build(:password_reset_token, token_digest: digest)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".build_for" do
    it "returns the token and the plaintext" do
      user = create(:user)
      token, plaintext = described_class.build_for(user)

      expect(token).to be_a(described_class)
      expect(token.user).to eq(user)
      expect(plaintext).to be_present
      expect(token.expires_at).to be_within(2.seconds).of(15.minutes.from_now)
    end

    it "stores the BCrypt digest, not the plaintext" do
      user = create(:user)
      token, plaintext = described_class.build_for(user)

      expect(token.token_digest).not_to eq(plaintext)
      expect(BCrypt::Password.new(token.token_digest) == plaintext).to be(true)
    end
  end

  describe "scopes and state" do
    let(:user) { create(:user) }

    it "is active by default and remains active until used or expired" do
      token = create(:password_reset_token, user: user)
      expect(token).to be_active
      expect(described_class.active).to include(token)
    end

    it "is not active when expired" do
      token = create(:password_reset_token, user: user, expires_at: 1.minute.ago)
      expect(token).not_to be_active
      expect(token).to be_expired
      expect(described_class.expired).to include(token)
      expect(described_class.active).not_to include(token)
    end

    it "is not active when used" do
      token = create(:password_reset_token, user: user)
      token.mark_used!
      expect(token).to be_used
      expect(token).not_to be_active
      expect(described_class.used).to include(token)
      expect(described_class.active).not_to include(token)
    end

    it "mark_used! sets used_at to the current time" do
      token = create(:password_reset_token, user: user)
      before_call = Time.current
      token.mark_used!
      expect(token.used_at).to be_within(1.second).of(before_call)
    end
  end
end
