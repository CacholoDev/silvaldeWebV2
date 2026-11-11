require "rails_helper"

RSpec.describe Carts::Merge do
  let(:user) { create(:user) }
  let(:variant) { create(:variant) }
  let(:other_variant) { create(:variant) }

  it "adopts the guest cart when the user has none" do
    guest_cart = create(:cart)
    item = create(:cart_item, cart: guest_cart, variant: variant, quantity: 2)

    result = described_class.call(user: user, cart: guest_cart)

    expect(result).to eq(guest_cart)
    expect(result.user).to eq(user)
    expect(result.cart_items).to contain_exactly(item)
  end

  it "sums the quantities of the common variants" do
    user_cart = create(:cart, user: user)
    user_item = create(:cart_item, cart: user_cart, variant: variant, quantity: 1)
    guest_cart = create(:cart)
    create(:cart_item, cart: guest_cart, variant: variant, quantity: 2)

    result = described_class.call(user: user, cart: guest_cart)

    expect(result).to eq(user_cart)
    expect(user_item.reload.quantity).to eq(3)
  end

  it "caps a summed quantity at the maximum per line instead of failing" do
    user_cart = create(:cart, user: user)
    user_item = create(:cart_item, cart: user_cart, variant: variant, quantity: 600)
    guest_cart = create(:cart)
    create(:cart_item, cart: guest_cart, variant: variant, quantity: 600)

    result = described_class.call(user: user, cart: guest_cart)

    expect(result).to eq(user_cart)
    expect(user_item.reload.quantity).to eq(Carts::CartItem::MAX_QUANTITY)
  end

  it "moves the guest-only lines to the user cart" do
    user_cart = create(:cart, user: user)
    create(:cart_item, cart: user_cart, variant: variant, quantity: 1)
    guest_cart = create(:cart)
    guest_item = create(:cart_item, cart: guest_cart, variant: other_variant, quantity: 2)

    result = described_class.call(user: user, cart: guest_cart)

    expect(result.cart_items.reload.map(&:variant)).to contain_exactly(variant, other_variant)
    expect(guest_item.reload.cart).to eq(user_cart)
  end

  it "keeps the frozen price of the user line when the quantities are summed" do
    user_cart = create(:cart, user: user)
    user_item = create(:cart_item, cart: user_cart, variant: variant, quantity: 1, unit_price_cents: 1200)
    guest_cart = create(:cart)
    create(:cart_item, cart: guest_cart, variant: variant, quantity: 2, unit_price_cents: 900)

    described_class.call(user: user, cart: guest_cart)

    expect(user_item.reload.quantity).to eq(3)
    expect(user_item.reload.unit_price_cents).to eq(1200)
  end

  it "keeps the frozen price of the moved lines" do
    user_cart = create(:cart, user: user)
    guest_cart = create(:cart)
    guest_item = create(:cart_item, cart: guest_cart, variant: other_variant, quantity: 2, unit_price_cents: 800)

    result = described_class.call(user: user, cart: guest_cart)

    moved = result.cart_items.sole
    expect(moved.id).to eq(guest_item.id)
    expect(moved.unit_price_cents).to eq(800)
  end

  it "destroys the guest cart after the merge" do
    user_cart = create(:cart, user: user)
    create(:cart_item, cart: user_cart, variant: variant, quantity: 1)
    guest_cart = create(:cart)
    create(:cart_item, cart: guest_cart, variant: other_variant, quantity: 2)

    described_class.call(user: user, cart: guest_cart)

    expect(Carts::Cart.exists?(guest_cart.id)).to be(false)
    expect(Carts::Cart.count).to eq(1)
  end

  it "leaves a cart owned by another user untouched" do
    other_user = create(:user)
    foreign_cart = create(:cart, user: other_user)
    foreign_item = create(:cart_item, cart: foreign_cart, variant: variant, quantity: 2)

    result = described_class.call(user: user, cart: foreign_cart)

    expect(result).to be_nil
    expect(foreign_item.reload.quantity).to eq(2)
    expect(foreign_cart.reload.user).to eq(other_user)
  end

  it "returns the user cart when there is no guest cart" do
    user_cart = create(:cart, user: user)

    expect(described_class.call(user: user, cart: nil)).to eq(user_cart)
  end
end
