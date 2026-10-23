require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }

  def sign_in
    post login_path, params: { email: user.email, password: "secret123" }
  end

  describe "GET /profile" do
    it "redirects to login when not authenticated" do
      get profile_path

      expect(response).to redirect_to(login_path)
    end

    it "shows the profile when authenticated" do
      sign_in
      get profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.name)
      expect(response.body).to include(user.email)
    end
  end

  describe "GET /profile/edit" do
    it "redirects to login when not authenticated" do
      get edit_profile_path

      expect(response).to redirect_to(login_path)
    end

    it "renders the edit form when authenticated" do
      sign_in
      get edit_profile_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /profile" do
    it "redirects to login when not authenticated" do
      patch profile_path, params: { user: { name: "X" } }

      expect(response).to redirect_to(login_path)
    end

    it "updates the profile with valid params" do
      sign_in
      patch profile_path, params: { user: { name: "Nuevo Nombre", email: "nuevo@example.com" } }

      expect(response).to redirect_to(profile_path)
      expect(user.reload.name).to eq("Nuevo Nombre")
      expect(user.reload.email).to eq("nuevo@example.com")
    end

    it "updates the communications consent" do
      sign_in
      patch profile_path, params: { user: { name: user.name, email: user.email, communications_consent: "1" } }

      expect(user.reload.communications_consent).to be(true)
    end

    it "re-renders the form with invalid params" do
      sign_in
      patch profile_path, params: { user: { name: "", email: user.email } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.name).not_to eq("")
    end
  end
end
