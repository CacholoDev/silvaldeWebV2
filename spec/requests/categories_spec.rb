require "rails_helper"

RSpec.describe "Category pages", type: :request do
  describe "GET /categories/:slug" do
    it "shows the products of the category" do
      category = create(:category, name: "Jarrones")
      product = create(:product, category: category, name: "Jarrón artesanal")
      create(:product, name: "Vela de soja")

      get category_path(category.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jarrones")
      expect(response.body).to include("Jarrón artesanal")
      expect(response.body).not_to include("Vela de soja")
    end

    it "returns not found for an unknown slug" do
      get category_path("no-existe")

      expect(response).to have_http_status(:not_found)
    end
  end
end
