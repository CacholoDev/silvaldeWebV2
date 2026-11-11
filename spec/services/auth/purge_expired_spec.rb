require "rails_helper"

RSpec.describe Auth::PurgeExpired do
  let(:user) { create(:user) }

  it "deletes expired sessions and keeps the active ones" do
    expired = create(:session, user: user)
    expired.update_column(:expires_at, 1.minute.ago)
    active = create(:session, user: user)

    described_class.call

    expect(Auth::Session.exists?(expired.id)).to be(false)
    expect(Auth::Session.exists?(active.id)).to be(true)
  end

  it "deletes used and expired reset tokens and keeps the usable ones" do
    used = create(:password_reset_token, user: user)
    used.update_column(:used_at, 1.minute.ago)
    expired = create(:password_reset_token, user: user)
    expired.update_column(:expires_at, 1.minute.ago)
    usable = create(:password_reset_token, user: user)

    described_class.call

    expect(Auth::PasswordResetToken.exists?(used.id)).to be(false)
    expect(Auth::PasswordResetToken.exists?(expired.id)).to be(false)
    expect(Auth::PasswordResetToken.exists?(usable.id)).to be(true)
  end

  it "returns how many rows it deleted" do
    create(:session, user: user).update_column(:expires_at, 1.minute.ago)

    expect(described_class.call).to eq(sessions: 1, password_reset_tokens: 0)
  end
end
