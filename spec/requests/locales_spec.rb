require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "POST /locale" do
    it "switches the language for subsequent requests" do
      post locale_path, params: { locale: "en" }
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response.body).to include(I18n.t("catalog.landing.title", locale: :en))
    end

    it "ignores an unsupported locale" do
      post locale_path, params: { locale: "xx" }
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response.body).to include(I18n.t("catalog.landing.title", locale: :es))
    end
  end
end
