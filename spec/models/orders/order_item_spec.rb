require "rails_helper"

RSpec.describe Orders::OrderItem, type: :model do
  describe "validations" do
    subject { build(:order_item) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires an order" do
      item = build(:order_item, order: nil)
      expect(item).not_to be_valid
      expect(item.errors[:order]).to include("El pedido no puede estar vacío.")
    end

    it "requires a variant" do
      item = build(:order_item, variant: nil)
      expect(item).not_to be_valid
      expect(item.errors[:variant]).to include("La variante no puede estar vacía.")
    end

    it "requires a quantity" do
      item = build(:order_item, quantity: nil)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad no puede estar vacía.")
    end

    it "rejects a zero quantity" do
      item = build(:order_item, quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser al menos 1.")
    end

    it "rejects a negative quantity" do
      item = build(:order_item, quantity: -2)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser al menos 1.")
    end

    it "rejects a non-numeric quantity" do
      item = build(:order_item, quantity: "abc")
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser un número.")
    end

    it "rejects a fractional quantity" do
      item = build(:order_item, quantity: "2.5")
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("La cantidad debe ser un número entero.")
    end

    it "rejects quantities above the maximum" do
      item = build(:order_item, quantity: Orders::OrderItem::MAX_QUANTITY + 1)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to be_present
    end

    it "requires a unit price" do
      item = build(:order_item, unit_price_cents: nil)
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario no puede estar vacío.")
    end

    it "rejects a negative unit price" do
      item = build(:order_item, unit_price_cents: -1)
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario no puede ser negativo.")
    end

    it "rejects a non-numeric unit price" do
      item = build(:order_item, unit_price_cents: "abc")
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario debe ser un número.")
    end

    it "rejects a fractional unit price" do
      item = build(:order_item, unit_price_cents: "9900.5")
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to include("El precio unitario debe ser un número entero.")
    end

    it "rejects the same variant twice in the same order" do
      order = create(:order)
      variant = create(:variant)
      create(:order_item, order: order, variant: variant)

      duplicate = build(:order_item, order: order, variant: variant)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:variant_id]).to include("Esa variante ya está en el pedido.")
    end

    it "allows the same variant in a different order" do
      variant = create(:variant)
      create(:order_item, variant: variant)

      other = build(:order_item, variant: variant)
      expect(other).to be_valid
    end
  end

  # The CHECK constraints live in the migration, below the app validations.
  # #save(validate: false) skips the model rules and hits the database rules,
  # proving the defence in depth is really there.
  describe "database constraints" do
    it "rejects an out-of-range quantity at the database level" do
      item = build(:order_item, quantity: 0)
      expect { item.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects a negative unit price at the database level" do
      item = build(:order_item, unit_price_cents: -1)
      expect { item.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "#subtotal_cents" do
    it "multiplies the frozen unit price by the quantity" do
      item = build(:order_item, quantity: 3, unit_price_cents: 1200)
      expect(item.subtotal_cents).to eq(3600)
    end
  end
end
