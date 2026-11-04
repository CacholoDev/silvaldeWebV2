require "rails_helper"

RSpec.describe Carts::Search do
  describe ".active" do
    it "includes a cart with recent activity" do
      cart = create(:cart)

      expect(described_class.active).to include(cart)
    end

    it "includes a cart touched five months ago" do
      cart = create(:cart)
      cart.update_column(:updated_at, 5.months.ago)

      expect(described_class.active).to include(cart)
    end

    it "excludes a cart inactive for over six months" do
      cart = create(:cart)
      cart.update_column(:updated_at, 7.months.ago)

      expect(described_class.active).not_to include(cart)
    end
  end

  describe ".find_active_cart" do
    it "returns the cart when it has recent activity" do
      cart = create(:cart)

      expect(described_class.find_active_cart(cart.id)).to eq(cart)
    end

    it "returns nil when there is no cart with that id" do
      expect(described_class.find_active_cart(0)).to be_nil
    end

    it "returns nil when the cart is expired" do
      cart = create(:cart)
      cart.update_column(:updated_at, 7.months.ago)

      expect(described_class.find_active_cart(cart.id)).to be_nil
    end
  end

  describe ".find_item_by_variant" do
    it "returns the cart line for the variant" do
      cart = create(:cart)
      item = create(:cart_item, cart: cart)

      expect(described_class.find_item_by_variant(cart, item.variant)).to eq(item)
    end

    it "returns nil when the variant is not in the cart" do
      cart = create(:cart)
      variant = create(:variant)

      expect(described_class.find_item_by_variant(cart, variant)).to be_nil
    end
  end

  describe ".total_quantity" do
    it "sums the quantities of the cart lines" do
      cart = create(:cart)
      create(:cart_item, cart: cart, quantity: 2)
      create(:cart_item, cart: cart, quantity: 3)

      expect(described_class.total_quantity(cart)).to eq(5)
    end

    it "is zero for an empty cart" do
      cart = create(:cart)

      expect(described_class.total_quantity(cart)).to eq(0)
    end
  end

  describe ".expired" do
    it "includes a cart inactive for over six months" do
      cart = create(:cart)
      cart.update_column(:updated_at, 7.months.ago)

      expect(described_class.expired).to include(cart)
    end

    it "excludes a cart with recent activity" do
      cart = create(:cart)

      expect(described_class.expired).not_to include(cart)
    end
  end
end
