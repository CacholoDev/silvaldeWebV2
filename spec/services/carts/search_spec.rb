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

  describe ".items_for" do
    it "returns the lines of the cart, in insertion order" do
      cart = create(:cart)
      first_item = create(:cart_item, cart: cart)
      second_item = create(:cart_item, cart: cart)
      create(:cart_item)

      expect(described_class.items_for(cart)).to eq([ first_item, second_item ])
    end

    it "is empty when there is no cart" do
      expect(described_class.items_for(nil)).to eq([])
    end
  end

  describe ".total_cents" do
    it "sums the subtotals of the lines" do
      cart = create(:cart)
      create(:cart_item, cart: cart, quantity: 2, unit_price_cents: 1500)
      create(:cart_item, cart: cart, quantity: 1, unit_price_cents: 500)

      expect(described_class.total_cents(cart)).to eq(3500)
    end

    it "is zero when there is no cart" do
      expect(described_class.total_cents(nil)).to eq(0)
    end
  end

  describe ".find_item_by_id!" do
    it "returns the line when it belongs to the cart" do
      cart = create(:cart)
      item = create(:cart_item, cart: cart)

      expect(described_class.find_item_by_id!(cart, item.id)).to eq(item)
    end

    it "raises RecordNotFound for a line of another cart" do
      cart = create(:cart)
      item = create(:cart_item)

      expect { described_class.find_item_by_id!(cart, item.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises RecordNotFound when there is no cart" do
      expect { described_class.find_item_by_id!(nil, 1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".find_cart_for_user" do
    it "returns the active cart of the user" do
      user = create(:user)
      cart = create(:cart, user: user)
      create(:cart)

      expect(described_class.find_cart_for_user(user)).to eq(cart)
    end

    it "is nil when the user has no cart" do
      user = create(:user)

      expect(described_class.find_cart_for_user(user)).to be_nil
    end

    it "ignores expired carts" do
      user = create(:user)
      cart = create(:cart, user: user)
      cart.update_column(:updated_at, 7.months.ago)

      expect(described_class.find_cart_for_user(user)).to be_nil
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
