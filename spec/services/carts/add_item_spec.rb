require "rails_helper"

RSpec.describe Carts::AddItem do
  let(:variant) { create(:variant, price_cents: 1500) }

  it "creates a guest cart and a line when there is no cart yet" do
    item = described_class.call(cart: nil, variant: variant, quantity: 2)

    expect(item).to be_persisted
    expect(item.quantity).to eq(2)
    expect(item.unit_price_cents).to eq(1500)
    expect(item.cart.user).to be_nil
    expect(item.cart.cart_items).to contain_exactly(item)
  end

  it "assigns the created cart to the given user" do
    user = create(:user)

    item = described_class.call(cart: nil, variant: variant, quantity: 1, user: user)

    expect(item.cart.user).to eq(user)
  end

  it "adds a new line to an existing cart" do
    cart = create(:cart)
    other_item = create(:cart_item, cart: cart)

    item = described_class.call(cart: cart, variant: variant, quantity: 3)

    expect(item).to be_persisted
    expect(item.cart).to eq(cart)
    expect(cart.cart_items).to contain_exactly(other_item, item)
  end

  it "sums the quantity when the variant is already in the cart" do
    cart = create(:cart)
    create(:cart_item, cart: cart, variant: variant, quantity: 2)

    described_class.call(cart: cart, variant: variant, quantity: 1)

    expect(cart.cart_items.sole.quantity).to eq(3)
  end

  it "keeps the frozen price when the variant is added again" do
    cart = create(:cart)
    create(:cart_item, cart: cart, variant: variant, quantity: 1, unit_price_cents: 1200)

    described_class.call(cart: cart, variant: variant, quantity: 1)

    expect(cart.cart_items.sole.unit_price_cents).to eq(1200)
  end

  it "returns a line with errors when the quantity is invalid" do
    item = described_class.call(cart: nil, variant: variant, quantity: 0)

    expect(item).not_to be_persisted
    expect(item.errors[:quantity]).to be_present
  end

  it "creates no cart when the first add has an invalid quantity" do
    expect {
      described_class.call(cart: nil, variant: variant, quantity: 0)
    }.not_to change(Carts::Cart, :count)
  end

  it "keeps the stored quantity when the sum turns the line invalid" do
    cart = create(:cart)
    item = create(:cart_item, cart: cart, variant: variant, quantity: 2)

    result = described_class.call(cart: cart, variant: variant, quantity: -3)

    expect(result.errors[:quantity]).to be_present
    expect(item.reload.quantity).to eq(2)
  end

  context "when a concurrent request inserts the same line first" do
    it "retries once and sums into the line the other request created" do
      cart = create(:cart)
      existing = create(:cart_item, cart: cart, variant: variant, quantity: 2)

      # First attempt: misses the line (the other request has not committed
      # yet) and the unique index rejects the insert.
      lookups = 0
      allow(Carts::Search).to receive(:find_item_by_variant).and_wrap_original do |original, *args|
        lookups += 1
        lookups == 1 ? nil : original.call(*args)
      end
      saves = 0
      allow_any_instance_of(Carts::CartItem).to receive(:save).and_wrap_original do |original, *args|
        saves += 1
        raise ActiveRecord::RecordNotUnique, "Duplicate entry" if saves == 1

        original.call(*args)
      end

      item = described_class.call(cart: cart, variant: variant, quantity: 1)

      expect(item).to eq(existing)
      expect(existing.reload.quantity).to eq(3)
      expect(cart.cart_items.count).to eq(1)
    end

    it "gives up after the retry instead of looping" do
      cart = create(:cart)
      allow_any_instance_of(Carts::CartItem).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      expect {
        described_class.call(cart: cart, variant: variant, quantity: 1)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
