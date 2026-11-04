require "rails_helper"

RSpec.describe "Cart ownership across sessions", type: :request do
  let(:variant) { create(:variant) }
  let(:user) { create(:user) }

  it "forgets the user cart after logout (shared browser)" do
    post login_path, params: { email: user.email, password: "secret123" }
    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
    user_cart = Carts::Cart.sole

    delete logout_path
    post cart_items_path, params: { variant_id: variant.id, quantity: 1 }

    guest_cart = Carts::Cart.where(user: nil).sole
    expect(guest_cart.cart_items.sole.quantity).to eq(1)
    expect(user_cart.reload.cart_items.sole.quantity).to eq(2)
    expect(Carts::Cart.count).to eq(2)

    get cart_path
    expect(response.body).to include(I18n.t("cart.items_count", count: 1))
  end

  it "keeps the guest cart after signup" do
    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }

    post signup_path, params: {
      user: { name: "Nueva", email: "nueva@example.com", password: "secret123", password_confirmation: "secret123" }
    }

    cart = Carts::Cart.sole
    expect(cart.user).to be_present
    expect(cart.cart_items.sole.quantity).to eq(2)
    expect(cart.cart_items.sole.variant).to eq(variant)
  end

  it "leaves the user cart untouched when another account signs in" do
    post login_path, params: { email: user.email, password: "secret123" }
    post cart_items_path, params: { variant_id: variant.id, quantity: 2 }
    user_cart = Carts::Cart.sole
    delete logout_path

    other = create(:user)
    post login_path, params: { email: other.email, password: "secret123" }

    expect(user_cart.reload.cart_items.sole.quantity).to eq(2)
    expect(Carts::Cart.count).to eq(1)
  end
end
