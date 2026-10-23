require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /password/reset" do
    it "renders the request form" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /password/reset" do
    let(:user) { create(:user) }

    before { ActionMailer::Base.deliveries.clear }

    it "creates a token, sends an email and redirects for an existing email" do
      expect {
        post new_password_path, params: { email: user.email }
      }.to change(PasswordResetToken, :count).by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to redirect_to(new_password_path)
      expect(flash[:notice]).to eq(I18n.t("passwords.flash.sent"))
    end

    it "does not leak whether an email exists" do
      post new_password_path, params: { email: "unknown@example.com" }

      expect(response).to redirect_to(new_password_path)
      expect(flash[:notice]).to eq(I18n.t("passwords.flash.sent"))
      expect(PasswordResetToken.count).to eq(0)
    end
  end
end
