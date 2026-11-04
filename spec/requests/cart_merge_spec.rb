require "rails_helper"

RSpec.describe "Cart merge on login", type: :request do
  let(:variant) { create(:variant) }
  let(:user) { create(:user) }

  it "sums the guest quantities into the user cart" do
    user_cart = create(:cart, user: user)
    create(:cart_item, cart: user_cart, variant: variant, quantity: 1)

    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
    post login_path, params: { email: user.email, password: "secret123" }

    expect(user_cart.cart_items.sole.reload.quantity).to eq(3)
    expect(Carts::Cart.count).to eq(1)
  end

  it "keeps using the merged cart after login" do
    user_cart = create(:cart, user: user)
    create(:cart_item, cart: user_cart, variant: variant, quantity: 1)

    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
    post login_path, params: { email: user.email, password: "secret123" }
    get cart_path

    expect(response.body).to include(I18n.t("cart.items_count", count: 3))
  end

  it "adopts the guest cart when the user has none" do
    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
    post login_path, params: { email: user.email, password: "secret123" }
    get cart_path

    expect(Carts::Cart.sole.user).to eq(user)
    expect(response.body).to include(I18n.t("cart.items_count", count: 2))
  end

  it "does not merge anything when the login fails" do
    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }

    post login_path, params: { email: user.email, password: "wrong" }

    expect(Carts::Cart.count).to eq(1)
    expect(Carts::CartItem.sole.quantity).to eq(2)
  end
end
