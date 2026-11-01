require "rails_helper"

RSpec.describe Carts::Cart, type: :model do
  describe "validations" do
    it "is valid without a user (guest cart)" do
      expect(build(:cart)).to be_valid
    end

    it "is valid with a user (customer cart)" do
      expect(build(:cart, user: create(:user))).to be_valid
    end
  end

  describe "associations" do
    it "destroys its items when the cart is destroyed" do
      cart = create(:cart)
      create(:cart_item, cart: cart)

      expect { cart.destroy }.to change(Carts::CartItem, :count).by(-1)
    end
  end

  describe "#expired?" do
    it "marks a cart inactive for over six months with #expired?" do
      cart = create(:cart)
      cart.update_column(:updated_at, 7.months.ago)

      expect(cart.expired?).to be(true)
    end

    it "does not mark a recently active cart with #expired?" do
      expect(create(:cart).expired?).to be(false)
    end
  end
end
