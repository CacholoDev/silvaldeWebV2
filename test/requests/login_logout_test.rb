require "test_helper"

class LoginLogoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "ada@example.com", password: "password123", confirmed_at: Time.current)
  end

  test "GET /login renders the form" do
    get login_path
    assert_response :success
    assert_select "form[action='#{login_path}']"
  end

  test "POST /login with valid credentials signs the user in" do
    post login_path, params: { email_address: "ada@example.com", password: "password123" }
    assert_redirected_to root_path
    assert cookies[:session_token].present?, "expected the session cookie to be set"
  end

  test "POST /login with a wrong password re-renders the form with an alert" do
    post login_path, params: { email_address: "ada@example.com", password: "nope" }
    assert_response :unprocessable_entity
    assert cookies[:session_token].blank?
  end

  test "POST /login for an unconfirmed user does not sign them in" do
    @user.update!(confirmed_at: nil)
    post login_path, params: { email_address: "ada@example.com", password: "password123" }
    assert_redirected_to login_path
    assert cookies[:session_token].blank?
  end

  test "DELETE /logout destroys the session row" do
    post login_path, params: { email_address: "ada@example.com", password: "password123" }
    assert_difference "Session.count", -1 do
      delete logout_path
    end
    assert_redirected_to root_path
    assert cookies[:session_token].blank?
  end
end
