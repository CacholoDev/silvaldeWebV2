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
      }.to change(Auth::PasswordResetToken, :count).by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to redirect_to(new_password_path)
      expect(flash[:notice]).to eq(I18n.t("passwords.flash.sent"))
    end

    it "does not leak whether an email exists" do
      post new_password_path, params: { email: "unknown@example.com" }

      expect(response).to redirect_to(new_password_path)
      expect(flash[:notice]).to eq(I18n.t("passwords.flash.sent"))
      expect(Auth::PasswordResetToken.count).to eq(0)
    end
  end

  describe "GET /password/reset/:token/edit" do
    let(:user) { create(:user) }

    def build_plaintext
      token, plaintext = Auth::PasswordResetToken.build_for(user)
      token.save!
      plaintext
    end

    it "renders the new password form with a valid token" do
      get edit_password_path(token: build_plaintext)

      expect(response).to have_http_status(:ok)
    end

    it "redirects with an invalid token" do
      get edit_password_path(token: "invalid")

      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PATCH /password/reset/:token" do
    let(:user) { create(:user) }

    def build_plaintext
      token, plaintext = Auth::PasswordResetToken.build_for(user)
      token.save!
      plaintext
    end

    it "updates the password and redirects to login" do
      patch update_password_path(token: build_plaintext),
            params: { user: { password: "newsecret", password_confirmation: "newsecret" } }

      expect(response).to redirect_to(login_path)
      expect(user.reload.authenticate("newsecret")).to eq(user)
    end

    it "re-renders the form with an invalid password" do
      patch update_password_path(token: build_plaintext),
            params: { user: { password: "newsecret", password_confirmation: "different" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("newsecret")).to be(false)
    end

    it "shows a translated error when the confirmation does not match" do
      patch update_password_path(token: build_plaintext),
            params: { user: { password: "newsecret", password_confirmation: "different" } }

      expect(response.body).to include("La confirmación de contraseña no coincide.")
      expect(response.body).not_to include("Translation missing")
    end

    it "revokes the user's other sessions on success" do
      create(:session, user: user)
      patch update_password_path(token: build_plaintext),
            params: { user: { password: "newsecret", password_confirmation: "newsecret" } }

      expect(Auth::Session.where(user: user).count).to eq(0)
    end

    it "redirects with an invalid token" do
      patch update_password_path(token: "invalid"),
            params: { user: { password: "newsecret", password_confirmation: "newsecret" } }

      expect(response).to redirect_to(new_password_path)
    end
  end
end
