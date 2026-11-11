require "rails_helper"

RSpec.describe "Navigation", type: :request do
  describe "the navbar" do
    it "shows sign in and sign up links when logged out" do
      get root_path

      expect(response.body).to include("Iniciar sesión")
      expect(response.body).to include("Crear cuenta")
      expect(response.body).not_to include("Cerrar sesión")
    end

    it "signs out with a real form, so it also works without JavaScript" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "secret123" }

      get root_path

      form = Nokogiri::HTML(response.body).at_css(%(form[action="#{logout_path}"]))
      expect(form).to be_present
      expect(form.at_css('input[name="_method"]')["value"]).to eq("delete")
    end

    it "shows a sign out link when logged in" do
      user = create(:user)
      post login_path, params: { email: user.email, password: "secret123" }

      get root_path

      expect(response.body).to include("Cerrar sesión")
      expect(response.body).not_to include("Crear cuenta")
    end
  end

  describe "cross-links" do
    it "links from the login page to sign up" do
      get login_path

      expect(response.body).to include(signup_path)
    end

    it "links from the sign up page to login" do
      get signup_path

      expect(response.body).to include(login_path)
    end
  end
end
