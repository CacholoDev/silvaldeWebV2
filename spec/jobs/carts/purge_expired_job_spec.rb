require "rails_helper"

RSpec.describe Carts::PurgeExpiredJob do
  it "purges the expired carts and keeps the rest" do
    expired_cart = create(:cart)
    expired_cart.update_column(:updated_at, 7.months.ago)
    active_cart = create(:cart)

    described_class.perform_now

    expect(Carts::Cart.exists?(expired_cart.id)).to be(false)
    expect(Carts::Cart.exists?(active_cart.id)).to be(true)
  end

  it "runs quietly when there is nothing to purge" do
    expect { described_class.perform_now }.not_to raise_error
  end
end
