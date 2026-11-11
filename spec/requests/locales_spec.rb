require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "POST /locale" do
    it "switches the language for subsequent requests" do
      post locale_path, params: { locale: "en" }
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response.body).to include(I18n.t("catalog.landing.title", locale: :en))
    end

    it "remembers the language after the browser is closed, in a protected cookie" do
      post locale_path, params: { locale: "en" }

      cookie = response.headers["Set-Cookie"].then { |h| Array(h).join("\n") }.lines.find { |l| l.start_with?("locale=") }
      expect(cookie).to include("expires=")
      expect(cookie).to match(/httponly/i)
      expect(cookie).to match(/samesite=lax/i)
    end

    it "ignores an unsupported locale" do
      post locale_path, params: { locale: "xx" }
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response.body).to include(I18n.t("catalog.landing.title", locale: :es))
    end
  end
end
