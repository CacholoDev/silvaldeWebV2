require "rails_helper"

RSpec.describe "Products pages", type: :request do
  describe "GET /products" do
    it "lists the catalog products" do
      product = create(:product, name: "Jarrón artesanal")

      get products_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jarrón artesanal")
    end

    it "filters products with the search query" do
      jarron = create(:product, name: "Jarrón artesanal")
      create(:product, name: "Vela de soja")

      get products_path, params: { q: "jarron" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jarrón artesanal")
      expect(response.body).not_to include("Vela de soja")
    end
  end

  describe "GET /products/:slug" do
    it "shows the product with its variants, price and availability" do
      product = create(:product, name: "Jarrón artesanal", price_cents: 4500)
      create(:variant, product: product, name: "Única", stock: 3)

      get product_path(product.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jarrón artesanal")
      expect(response.body).to include("45,00 €")
      expect(response.body).to include("Única")
      expect(response.body).to include("Disponible")
    end

    it "returns not found for an unknown slug" do
      get product_path("no-existe")

      expect(response).to have_http_status(:not_found)
    end
  end
end
