require "rails_helper"

RSpec.describe Carts::CartItem, type: :model do
  describe "validations" do
    subject { build(:cart_item) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a cart" do
      item = build(:cart_item, cart: nil)
      expect(item).not_to be_valid
      expect(item.errors[:cart]).to include("El carrito no puede estar vacío.")
    end

    it "requires a variant" do
      item = build(:cart_item, variant: nil)
      expect(item).not_to be_valid
      expect(item.errors[:variant]).to include("La variante no puede estar vacía.")
    end

    it "requires a quantity" do
      item = build(:cart_item, quantity: nil)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad no puede estar vacía.")
    end

    it "rejects a zero quantity" do
      item = build(:cart_item, quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser al menos 1.")
    end

    it "rejects a negative quantity" do
      item = build(:cart_item, quantity: -2)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser al menos 1.")
    end

    it "rejects a non-numeric quantity" do
      item = build(:cart_item, quantity: "abc")
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser un número.")
    end

    it "rejects a fractional quantity" do
      item = build(:cart_item, quantity: "2.5")
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser un número entero.")
    end

    it "requires a unit price" do
      item = build(:cart_item, unit_price_cents: nil)
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario no puede estar vacío.")
    end

    it "rejects a negative unit price" do
      item = build(:cart_item, unit_price_cents: -1)
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario no puede ser negativo.")
    end

    it "rejects a non-numeric unit price" do
      item = build(:cart_item, unit_price_cents: "abc")
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario debe ser un número.")
    end

    it "rejects a fractional unit price" do
      item = build(:cart_item, unit_price_cents: "9900.5")
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario debe ser un número entero.")
    end

    it "rejects the same variant twice in the same cart" do
      cart = create(:cart)
      variant = create(:variant)
      create(:cart_item, cart: cart, variant: variant)

      duplicate = build(:cart_item, cart: cart, variant: variant)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:variant_id]).to include("Esa variante ya está en el carrito.")
    end

    it "allows the same variant in a different cart" do
      variant = create(:variant)
      create(:cart_item, variant: variant)

      other = build(:cart_item, variant: variant)
      expect(other).to be_valid
    end
  end

  describe "cart activity" do
    it "refreshes the cart when an item is created" do
      cart = create(:cart)
      cart.update_column(:updated_at, 2.days.ago)

      create(:cart_item, cart: cart)
      expect(cart.reload.updated_at).to be > 1.hour.ago
    end
  end

  describe "#subtotal_cents" do
    it "multiplies the frozen unit price by the quantity" do
      item = build(:cart_item, quantity: 3, unit_price_cents: 1200)

      expect(item.subtotal_cents).to eq(3600)
    end
  end
end
