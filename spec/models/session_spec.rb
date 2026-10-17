require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it "belongs to a user" do
      expect(Session.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "is invalid without a user" do
      session = build(:session, user: nil)
      expect(session).not_to be_valid
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:session)).to be_valid
    end

    it "requires a token_digest" do
      session = build(:session, token_digest: nil)
      expect(session).not_to be_valid
    end

    it "requires an expires_at" do
      session = build(:session, expires_at: nil)
      expect(session).not_to be_valid
    end

    it "enforces unique token_digest" do
      digest = Session.digest_for("shared-token")
      create(:session, token_digest: digest)
      duplicate = build(:session, token_digest: digest)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".build_for" do
    let(:user) { create(:user) }

    it "returns the session and a plaintext token" do
      session, plaintext = described_class.build_for(user)

      expect(session).to be_a(described_class)
      expect(session.user).to eq(user)
      expect(plaintext).to be_present
    end

    it "stores the SHA256 digest, not the plaintext" do
      session, plaintext = described_class.build_for(user)

      expect(session.token_digest).not_to eq(plaintext)
      expect(session.token_digest).to eq(Session.digest_for(plaintext))
    end

    it "sets expires_at to 1 day by default" do
      session, _ = described_class.build_for(user)
      expect(session.expires_at).to be_within(2.seconds).of(1.day.from_now)
    end

    it "sets expires_at to 30 days when remember_me is true" do
      session, _ = described_class.build_for(user, remember_me: true)
      expect(session.expires_at).to be_within(2.seconds).of(30.days.from_now)
    end

    it "stores ip_address and user_agent when provided" do
      session, _ = described_class.build_for(
        user,
        ip_address: "10.0.0.1",
        user_agent: "Mozilla/5.0"
      )
      expect(session.ip_address).to eq("10.0.0.1")
      expect(session.user_agent).to eq("Mozilla/5.0")
    end
  end

  describe ".lookup" do
    let(:user) { create(:user) }

    it "finds an active session by its plaintext token" do
      session, plaintext = described_class.build_for(user)
      session.save!

      expect(described_class.lookup(plaintext)).to eq(session)
    end

    it "returns nil for a blank token" do
      expect(described_class.lookup(nil)).to be_nil
      expect(described_class.lookup("")).to be_nil
    end

    it "returns nil for a wrong token" do
      described_class.build_for(user).first.save!
      expect(described_class.lookup("wrong-token")).to be_nil
    end

    it "returns nil for an expired session" do
      session, plaintext = described_class.build_for(user)
      session.update!(expires_at: 1.minute.ago)

      expect(described_class.lookup(plaintext)).to be_nil
    end
  end

  describe "state predicates" do
    it "is active when expires_at is in the future" do
      session = build(:session, expires_at: 1.hour.from_now)
      expect(session).to be_active
      expect(session).not_to be_expired
    end

    it "is expired when expires_at is in the past" do
      session = build(:session, expires_at: 1.minute.ago)
      expect(session).to be_expired
      expect(session).not_to be_active
    end
  end
end
