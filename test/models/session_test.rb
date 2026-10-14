require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "session@example.com", password: "password123")
    @fake_request = Struct.new(:remote_ip, :user_agent).new("127.0.0.1", "test-agent")
  end

  test "start_for! creates a session for the user" do
    s = Session.start_for!(@user, request: @fake_request)
    assert_equal @user, s.user
    assert_equal "127.0.0.1", s.ip_address
    assert_equal "test-agent", s.user_agent
  end

  test "default lifetime is 1 day" do
    s = Session.start_for!(@user, request: @fake_request)
    delta = s.expires_at - Time.current
    assert delta > 23.hours, "expected ~1 day, got #{delta}"
    assert delta <= 25.hours
  end

  test "remember_me extends lifetime to 30 days" do
    s = Session.start_for!(@user, request: @fake_request, remember_me: true)
    delta = s.expires_at - Time.current
    assert delta > 29.days
    assert delta <= 31.days
  end

  test "active scope excludes expired rows" do
    active = Session.start_for!(@user, request: @fake_request)
    expired = Session.start_for!(@user, request: @fake_request)
    expired.update_columns(expires_at: 1.minute.ago)

    assert_includes Session.active, active
    refute_includes Session.active, expired
  end
end
