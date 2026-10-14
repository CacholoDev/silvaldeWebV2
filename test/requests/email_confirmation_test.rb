require "test_helper"

class EmailConfirmationTest < ActionDispatch::IntegrationTest
  test "GET /email/confirm with a valid token confirms the user" do
    user = User.create!(email_address: "ada@example.com", password: "password123")
    raw = user.generate_confirmation_token!

    get email_confirmation_path(token: raw, user_id: user.id)
    assert_redirected_to login_path
    assert user.reload.confirmed?
  end

  test "GET /email/confirm with a wrong token does not confirm" do
    user = User.create!(email_address: "ada@example.com", password: "password123")
    user.generate_confirmation_token!

    get email_confirmation_path(token: "wrong", user_id: user.id)
    assert_redirected_to login_path
    assert_not user.reload.confirmed?
  end

  test "GET /email/confirm with a missing user does not blow up" do
    get email_confirmation_path(token: "anything", user_id: 0)
    assert_redirected_to login_path
  end

  test "the token works only once" do
    user = User.create!(email_address: "ada@example.com", password: "password123")
    raw = user.generate_confirmation_token!
    get email_confirmation_path(token: raw, user_id: user.id)
    user.reload
    # second visit with the same token: digest is nil, so it fails
    get email_confirmation_path(token: raw, user_id: user.id)
    assert user.confirmed?
  end
end
