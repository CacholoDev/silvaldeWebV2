require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /login" do
    it "renders the login form" do
      get login_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "starts a session for the user and redirects to the home page" do
        post login_path, params: { email: user.email, password: "secret123" }

        expect(response).to redirect_to(root_path)
        expect(Auth::Session.count).to eq(1)
        expect(Auth::Session.last.user).to eq(user)
      end
    end

    context "with invalid credentials" do
      it "does not start a session and redirects back to the login page" do
        post login_path, params: { email: user.email, password: "wrong" }

        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("authentication.flash.invalid_credentials"))
        expect(Auth::Session.count).to eq(0)
      end
    end
  end

  describe "DELETE /logout" do
    it "terminates the session and redirects to the home page" do
      post login_path, params: { email: user.email, password: "secret123" }

      delete logout_path

      expect(response).to redirect_to(root_path)
      expect(Auth::Session.count).to eq(0)
    end
  end
end
