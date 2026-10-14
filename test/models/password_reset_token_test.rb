require "test_helper"

class PasswordResetTokenTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "reset@example.com", password: "password123")
  end

  test "issue_for! returns a raw token and stores its digest" do
    raw = PasswordResetToken.issue_for!(@user)
    record = @user.password_reset_tokens.last
    refute_equal raw, record.token_digest
    assert_equal 64, record.token_digest.length
  end

  test "issue_for! sets an expiration in the future" do
    raw = PasswordResetToken.issue_for!(@user)
    record = @user.password_reset_tokens.last
    assert record.expires_at > Time.current
    assert record.expires_at <= 20.minutes.from_now
  end

  test "active scope hides used and expired tokens" do
    fresh_raw = PasswordResetToken.issue_for!(@user)
    consumed_raw = PasswordResetToken.issue_for!(@user)
    consumed = @user.password_reset_tokens.find_by!(token_digest: PasswordResetToken.digest_for(consumed_raw))
    consumed.consume!

    expired_raw = PasswordResetToken.issue_for!(@user)
    expired = @user.password_reset_tokens.find_by!(token_digest: PasswordResetToken.digest_for(expired_raw))
    expired.update_columns(expires_at: 1.minute.ago)

    fresh_record = @user.password_reset_tokens.find_by!(token_digest: PasswordResetToken.digest_for(fresh_raw))
    active = PasswordResetToken.active.where(user: @user)
    assert_includes active, fresh_record
    refute_includes active, consumed
    refute_includes active, expired
  end

  test "matches? returns true only for the raw token that produced it" do
    raw = PasswordResetToken.issue_for!(@user)
    record = @user.password_reset_tokens.last
    assert record.matches?(raw)
    assert_not record.matches?("nope")
    assert_not record.matches?("")
  end

  test "consume! flips used_at" do
    PasswordResetToken.issue_for!(@user)
    record = @user.password_reset_tokens.last
    assert_nil record.used_at
    record.consume!
    assert_not_nil record.reload.used_at
  end
end
