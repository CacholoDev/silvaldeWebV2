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
