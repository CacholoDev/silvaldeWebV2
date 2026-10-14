require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with a unique email and a password of 8+ chars" do
    user = User.new(email_address: "ada@example.com", password: "password123")
    assert user.valid?, user.errors.full_messages.inspect
  end

  test "normalizes email_address to downcase" do
    user = User.create!(email_address: "MIXED@Example.COM", password: "password123")
    assert_equal "mixed@example.com", user.email_address
    assert_equal "mixed@example.com", User.find(user.id).email_address
  end

  test "rejects invalid email" do
    user = User.new(email_address: "not-an-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address].join, "invalid"
  end

  test "rejects short password" do
    user = User.new(email_address: "short@example.com", password: "short")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "is case-insensitively unique by email" do
    User.create!(email_address: "dupe@example.com", password: "password123")
    dup = User.new(email_address: "DUPE@example.com", password: "password123")
    assert_not dup.valid?
    assert_includes dup.errors[:email_address].join, "taken"
  end

  test "stores password as a bcrypt digest" do
    user = User.create!(email_address: "bcrypt@example.com", password: "password123")
    refute_equal "password123", user.password_digest
    assert user.password_digest.start_with?("$2")
  end

  test "authenticate returns the user for the right password" do
    user = User.create!(email_address: "auth@example.com", password: "password123")
    assert_equal user, user.authenticate("password123")
  end

  test "authenticate returns false for a wrong password" do
    user = User.create!(email_address: "wrong@example.com", password: "password123")
    assert_equal false, user.authenticate("nope")
  end

  test "defaults role to customer" do
    user = User.create!(email_address: "role@example.com", password: "password123")
    assert user.customer?
    assert_not user.admin?
  end

  test "can be created as admin" do
    user = User.create!(email_address: "admin@example.com", password: "password123", role: :admin)
    assert user.admin?
  end

  test "generate_confirmation_token! returns a raw token and stores its digest" do
    user = User.create!(email_address: "confirm@example.com", password: "password123")
    raw = user.generate_confirmation_token!
    assert_kind_of String, raw
    refute_equal raw, user.confirmation_digest
    assert_equal 64, user.confirmation_digest.length # SHA-256 hex
  end

  test "confirm_with_token! flips confirmed_at when the token matches" do
    user = User.create!(email_address: "ok@example.com", password: "password123")
    raw = user.generate_confirmation_token!
    assert user.confirm_with_token!(raw)
    assert user.confirmed?
    assert_nil user.reload.confirmation_digest
  end

  test "confirm_with_token! rejects a wrong token" do
    user = User.create!(email_address: "bad@example.com", password: "password123")
    user.generate_confirmation_token!
    assert_not user.confirm_with_token!("definitely-wrong-token")
    assert_not user.confirmed?
  end

  test "confirm_with_token! rejects a token after the digest was cleared" do
    user = User.create!(email_address: "cleared@example.com", password: "password123")
    raw = user.generate_confirmation_token!
    user.update!(confirmation_digest: nil)
    assert_not user.confirm_with_token!(raw)
  end
end
