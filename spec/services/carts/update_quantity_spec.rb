require "rails_helper"

RSpec.describe Carts::UpdateQuantity do
  it "updates the line quantity" do
    item = create(:cart_item, quantity: 2)

    result = described_class.call(item: item, quantity: 5)

    expect(result.quantity).to eq(5)
    expect(item.reload.quantity).to eq(5)
  end

  it "returns the item with errors and keeps the stored quantity when invalid" do
    item = create(:cart_item, quantity: 2)

    result = described_class.call(item: item, quantity: 0)

    expect(result.errors[:quantity]).to be_present
    expect(item.reload.quantity).to eq(2)
  end
end
