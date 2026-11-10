require "rails_helper"

RSpec.describe "Cart items", type: :request do
  let(:variant) { create(:variant, price_cents: 1500) }
  let(:turbo_stream_headers) { { "ACCEPT" => "text/vnd.turbo-stream.html" } }

  describe "POST /cart/items" do
    it "adds a line and redirects back to the product page" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 2 }

      item = Carts::CartItem.sole
      expect(item.quantity).to eq(2)
      expect(item.unit_price_cents).to eq(1500)
      expect(item.cart.user).to be_nil
      expect(response).to redirect_to(product_path(variant.product.slug))
      expect(flash[:notice]).to eq(I18n.t("cart.added"))
    end

    it "keeps adding to the same session cart" do
      other = create(:variant)

      post cart_items_path, params: { variant_id: variant.id, quantity: 1 }
      post cart_items_path, params: { variant_id: other.id, quantity: 1 }

      expect(Carts::Cart.count).to eq(1)
      expect(Carts::CartItem.count).to eq(2)
    end

    it "shows an error and stores nothing when the quantity is invalid" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 0 }

      expect(Carts::CartItem.count).to eq(0)
      expect(response).to redirect_to(product_path(variant.product.slug))
      expect(flash[:alert]).to eq(I18n.t("cart.add_failed"))
    end

    it "treats a malformed quantity (an array) as invalid instead of a 500" do
      post cart_items_path, params: { variant_id: variant.id, quantity: [ "1" ] }

      expect(Carts::CartItem.count).to eq(0)
      expect(flash[:alert]).to eq(I18n.t("cart.add_failed"))
    end

    it "returns 404 for an unknown variant" do
      post cart_items_path, params: { variant_id: 0, quantity: 1 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /cart/items with Turbo" do
    it "updates the header counter without reloading" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 2 }, headers: turbo_stream_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="cart_counter"')
      expect(response.body).to include(I18n.t("cart.items_count", count: 2))
    end

    it "confirms the addition near the form" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 1 }, headers: turbo_stream_headers

      expect(response.body).to include('target="cart_feedback"')
      expect(response.body).to include(I18n.t("cart.added"))
    end

    it "reports the error near the form when the quantity is invalid" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 0 }, headers: turbo_stream_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('target="cart_feedback"')
      expect(response.body).to include(I18n.t("cart.add_failed"))
    end
  end

  describe "the product page" do
    it "offers variant, quantity and the add button" do
      get product_path(variant.product.slug)

      expect(response.body).to include(I18n.t("cart.add_to_cart"))
      expect(response.body).to include('name="variant_id"')
      expect(response.body).to include('name="quantity"')
    end

    it "shows an empty cart counter in the header" do
      get product_path(variant.product.slug)

      expect(response.body).to include('id="cart_counter"')
      expect(response.body).to include(I18n.t("cart.items_count", count: 0))
    end

    it "shows the cart counter with the units already added" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 2 }

      get product_path(variant.product.slug)

      expect(response.body).to include(I18n.t("cart.items_count", count: 2))
    end
  end

  describe "PATCH /cart/items/:id" do
    it "updates the quantity and refreshes the cart without reloading" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 1 }
      item = Carts::CartItem.sole

      patch cart_item_path(item), params: { quantity: 5 }, headers: turbo_stream_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(item.reload.quantity).to eq(5)
      expect(response.body).to include('target="cart_contents"')
      expect(response.body).to include('target="cart_counter"')
      expect(response.body).to include(I18n.t("cart.updated"))
    end

    it "reports the error and keeps the quantity when it is invalid" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
      item = Carts::CartItem.sole

      patch cart_item_path(item), params: { quantity: 0 }, headers: turbo_stream_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(item.reload.quantity).to eq(2)
      expect(response.body).to include(I18n.t("cart.update_failed"))
    end

    it "falls back to redirect with flash without turbo" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 1 }
      item = Carts::CartItem.sole

      patch cart_item_path(item), params: { quantity: 5 }

      expect(item.reload.quantity).to eq(5)
      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq(I18n.t("cart.updated"))
    end

    it "returns 404 for a line of another cart" do
      foreign_item = create(:cart_item)

      patch cart_item_path(foreign_item), params: { quantity: 5 }

      expect(response).to have_http_status(:not_found)
      expect(foreign_item.reload.quantity).to eq(1)
    end
  end

  describe "DELETE /cart/items/:id" do
    it "removes the line and shows the empty state when it was the last" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 1 }
      item = Carts::CartItem.sole

      delete cart_item_path(item), headers: turbo_stream_headers

      expect(Carts::CartItem.count).to eq(0)
      expect(response.body).to include('target="cart_contents"')
      expect(response.body).to include(I18n.t("cart.empty_title"))
      expect(response.body).to include(I18n.t("cart.removed"))
    end

    it "falls back to redirect with flash without turbo" do
      post cart_items_path, params: { variant_id: variant.id, quantity: 1 }
      item = Carts::CartItem.sole

      delete cart_item_path(item)

      expect(Carts::CartItem.count).to eq(0)
      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to eq(I18n.t("cart.removed"))
    end

    it "returns 404 for a line of another cart" do
      foreign_item = create(:cart_item)

      delete cart_item_path(foreign_item)

      expect(response).to have_http_status(:not_found)
      expect(Carts::CartItem.count).to eq(1)
    end
  end
end
