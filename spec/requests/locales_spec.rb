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

    it "switches the language to Galician" do
      post locale_path, params: { locale: "gl" }

      get root_path
      expect(response.body).to include(I18n.t("catalog.landing.title", locale: :gl))
      expect(response.body).to include('lang="gl"')
    end

    it "offers Spanish, Galician and English in the language menu" do
      get root_path

      menu = Nokogiri::HTML(response.body).css('form[action^="/locale"] button').map(&:text).map(&:strip)
      expect(menu).to eq(%w[Español Galego English])
    end

    it "ignores an unsupported locale" do
      post locale_path, params: { locale: "xx" }
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response.body).to include(I18n.t("catalog.landing.title", locale: :es))
    end
  end
end
