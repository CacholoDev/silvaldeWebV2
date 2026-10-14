require "test_helper"

class AuthenticationGateTest < ActionDispatch::IntegrationTest
  test "Home is public" do
    get root_path
    assert_response :success
  end

  test "Login is public" do
    get login_path
    assert_response :success
  end

  test "Signup is public" do
    get signup_path
    assert_response :success
  end

  test "Forgot password is public" do
    get new_password_path
    assert_response :success
  end

  test "Email confirmation is public" do
    get email_confirmation_path(token: "x", user_id: 0)
    assert_redirected_to login_path
  end

  test "A signed-in user visiting /signup is redirected to the home" do
    user = User.create!(email_address: "ada@example.com", password: "password123", confirmed_at: Time.current)
    post login_path, params: { email_address: "ada@example.com", password: "password123" }
    get signup_path
    assert_redirected_to root_path
  end
end
