require "rails_helper"

RSpec.describe Carts::PurgeExpired do
  it "destroys the carts without activity for over six months" do
    expired_cart = create(:cart)
    create(:cart_item, cart: expired_cart)
    expired_cart.update_column(:updated_at, 7.months.ago)

    result = described_class.call

    expect(result).to eq(1)
    expect(Carts::Cart.exists?(expired_cart.id)).to be(false)
    expect(Carts::CartItem.count).to eq(0)
  end

  it "keeps the carts with recent activity" do
    active_cart = create(:cart)

    described_class.call

    expect(Carts::Cart.exists?(active_cart.id)).to be(true)
  end

  it "is quiet when there is nothing to purge" do
    expect(described_class.call).to eq(0)
  end
end
