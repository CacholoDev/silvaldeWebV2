require "rails_helper"

# The test cache is a null store, so the counter never grows on its own here.
# Each example puts the counter over the limit and checks that the endpoint
# refuses the request without running the action.
RSpec.describe "Rate limits on authentication endpoints", type: :request do
  def exceed_rate_limit
    allow(ActionController::Base.cache_store).to receive(:increment).and_return(1_000)
  end

  it "throttles login attempts without authenticating" do
    user = create(:user)
    exceed_rate_limit

    post login_path, params: { email: user.email, password: "secret123" }

    expect(response).to redirect_to(login_path)
    expect(flash[:alert]).to eq(I18n.t("authentication.flash.rate_limited"))
    expect(Auth::Session.where(user: user)).to be_empty
  end

  it "throttles sign-ups without creating the account" do
    exceed_rate_limit

    expect do
      post signup_path, params: { user: { name: "Nueva", email: "new@example.com",
                                          password: "secret123", password_confirmation: "secret123" } }
    end.not_to change(Users::User, :count)

    expect(response).to redirect_to(signup_path)
    expect(flash[:alert]).to eq(I18n.t("authentication.flash.rate_limited"))
  end

  it "throttles password reset requests without creating a token or email" do
    user = create(:user)
    exceed_rate_limit

    expect do
      post password_reset_path, params: { email: user.email }
    end.not_to change(Auth::PasswordResetToken, :count)

    expect(response).to redirect_to(new_password_path)
    expect(flash[:alert]).to eq(I18n.t("authentication.flash.rate_limited"))
  end

  it "throttles password updates without consuming the token" do
    user = create(:user)
    token, plaintext = Auth::PasswordResetToken.build_for(user)
    token.save!
    exceed_rate_limit

    patch update_password_path, params: { token: plaintext,
                                          user: { password: "newsecret", password_confirmation: "newsecret" } }

    expect(response).to redirect_to(new_password_path)
    expect(Auth::Search.find_active_password_reset_token(plaintext)).to be_present
  end

  it "does not throttle under the limit" do
    user = create(:user)

    post login_path, params: { email: user.email, password: "secret123" }

    expect(response).to redirect_to(root_path)
  end
end
