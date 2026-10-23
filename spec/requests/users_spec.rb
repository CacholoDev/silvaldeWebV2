require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "renders the signup form" do
      get signup_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /signup" do
    let(:valid_params) do
      { user: { name: "Nueva", email: "nueva@example.com", password: "secret123", password_confirmation: "secret123" } }
    end

    context "with valid params" do
      it "creates the user, starts a session and redirects to the home page" do
        post signup_path, params: valid_params

        expect(response).to redirect_to(root_path)
        expect(Users::User.count).to eq(1)
        expect(Users::User.last.email).to eq("nueva@example.com")
        expect(Auth::Session.count).to eq(1)
      end

      it "stores the communications consent when opted in" do
        post signup_path, params: { user: { name: "Nueva", email: "consent@example.com", password: "secret123", password_confirmation: "secret123", communications_consent: "1" } }

        expect(Users::User.last.communications_consent).to be(true)
      end
    end

    context "with invalid params" do
      it "does not create the user and re-renders the form" do
        post signup_path, params: { user: { name: "", email: "invalid", password: "secret123", password_confirmation: "secret123" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Users::User.count).to eq(0)
        expect(response.body).to include(I18n.t("activerecord.errors.models.user.attributes.name.blank"))
      end
    end
  end
end
