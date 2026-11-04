require "rails_helper"

RSpec.describe Carts::RemoveItem do
  it "destroys the line" do
    item = create(:cart_item)

    result = described_class.call(item: item)

    expect(result).to be_destroyed
    expect(Carts::CartItem.exists?(item.id)).to be(false)
  end

  it "leaves the other lines of the cart untouched" do
    item = create(:cart_item)
    other = create(:cart_item, cart: item.cart)

    described_class.call(item: item)

    expect(item.cart.cart_items).to contain_exactly(other)
  end
end
