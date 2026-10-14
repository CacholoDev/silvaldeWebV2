require "test_helper"

class PasswordResetTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "ada@example.com", password: "oldpassword", confirmed_at: Time.current)
  end

  test "GET /password renders the forgot form" do
    get new_password_path
    assert_response :success
  end

  test "POST /password with a known email sends a reset email" do
    assert_emails 1 do
      post passwords_path, params: { email_address: "ada@example.com" }
    end
    assert_redirected_to login_path
    assert_equal 1, @user.password_reset_tokens.count
  end

  test "POST /password with an unknown email responds the same way (no enumeration)" do
    assert_no_emails do
      post passwords_path, params: { email_address: "ghost@example.com" }
    end
    assert_redirected_to login_path
  end

  test "GET /password/edit renders the form for a valid token" do
    raw = PasswordResetToken.issue_for!(@user)
    get edit_password_path(token: raw, user_id: @user.id)
    assert_response :success
  end

  test "PATCH /password with a valid token updates the password" do
    raw = PasswordResetToken.issue_for!(@user)
    patch update_password_path, params: {
      user_id: @user.id,
      token: raw,
      user: { password: "newpassword", password_confirmation: "newpassword" }
    }
    assert_redirected_to login_path
    assert @user.reload.authenticate("newpassword")
    assert_not @user.authenticate("oldpassword")
  end

  test "PATCH /password with a wrong token is rejected" do
    PasswordResetToken.issue_for!(@user)
    patch update_password_path, params: {
      user_id: @user.id,
      token: "wrong",
      user: { password: "newpassword", password_confirmation: "newpassword" }
    }
    assert_redirected_to new_password_path
    assert @user.reload.authenticate("oldpassword")
  end

  test "PATCH /password with a consumed token is rejected" do
    raw = PasswordResetToken.issue_for!(@user)
    record = @user.password_reset_tokens.last
    record.consume!
    patch update_password_path, params: {
      user_id: @user.id,
      token: raw,
      user: { password: "newpassword", password_confirmation: "newpassword" }
    }
    assert_redirected_to new_password_path
  end

  test "PATCH /password with a mismatched confirmation is rejected" do
    raw = PasswordResetToken.issue_for!(@user)
    patch update_password_path, params: {
      user_id: @user.id,
      token: raw,
      user: { password: "newpassword", password_confirmation: "different" }
    }
    assert_response :unprocessable_entity
  end
end
