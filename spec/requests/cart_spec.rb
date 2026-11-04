require "rails_helper"

RSpec.describe "Cart page", type: :request do
  let(:variant) { create(:variant, name: "Única", price_cents: 1500) }
  let(:other_variant) { create(:variant, name: "Pack de 2", price_cents: 500) }

  describe "GET /cart" do
    it "shows the empty state for guests without cart" do
      get cart_path

      expect(response.body).to include(I18n.t("cart.empty_title"))
      expect(response.body).to include(I18n.t("cart.continue_shopping"))
    end

    it "lists the lines with quantity, unit price and subtotal" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
      post cart_items_path, params: { variant_id: other_variant.id, quantity: 1 }

      get cart_path

      expect(response.body).to include(variant.name)
      expect(response.body).to include(other_variant.name)
      expect(response.body).to include("15,00 €")
      expect(response.body).to include("30,00 €")
      expect(response.body).to include("5,00 €")
      expect(response.body).to include(I18n.t("cart.update"))
      expect(response.body).to include(I18n.t("cart.remove"))
    end

    it "shows the total of the lines" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
      post cart_items_path, params: { variant_id: other_variant.id, quantity: 1 }

      get cart_path

      expect(response.body).to include("35,00 €")
    end

    it "links the header counter to the cart page" do
      get cart_path

      expect(response.body).to include(%(href="#{cart_path}"))
    end
  end
end
