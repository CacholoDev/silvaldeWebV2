require "test_helper"

class SignupTest < ActionDispatch::IntegrationTest
  test "GET /signup renders the form" do
    get signup_path
    assert_response :success
    assert_select "form[action='#{signup_path}']"
  end

  test "POST /signup creates a user and enqueues a confirmation email" do
    assert_emails 1 do
      assert_difference "User.count", 1 do
        post signup_path, params: {
          user: {
            name: "Ada Lovelace",
            email_address: "ada@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end
    assert_redirected_to login_path
  end

  test "POST /signup with mismatched passwords re-renders the form" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: { email_address: "ada@example.com", password: "password123", password_confirmation: "different123" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /signup with a short password re-renders the form" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: { email_address: "short@example.com", password: "short", password_confirmation: "short" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /signup with a duplicate email re-renders the form" do
    User.create!(email_address: "ada@example.com", password: "password123")
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: { email_address: "ada@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end
end
