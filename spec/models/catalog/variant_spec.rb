require "rails_helper"

RSpec.describe Catalog::Variant, type: :model do
  describe "validations" do
    subject { build(:variant) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a product" do
      variant = build(:variant, product: nil)
      expect(variant).not_to be_valid
      expect(variant.errors[:product]).to include("El producto no puede estar vacío.")
    end

    it "requires a name" do
      variant = build(:variant, name: nil)
      expect(variant).not_to be_valid
      expect(variant.errors[:name]).to include("El nombre no puede estar vacío.")
    end

    it "enforces maximum length on name (100)" do
      variant = build(:variant, name: "a" * 101)
      expect(variant).not_to be_valid
      expect(variant.errors[:name]).to include("El nombre es demasiado largo (máximo 100 caracteres).")
    end

    it "enforces unique name within the same product" do
      product = create(:product)
      create(:variant, product: product, name: "Única")
      duplicate = build(:variant, product: product, name: "Única")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("Ese nombre ya está en uso.")
    end

    it "allows the same name in a different product" do
      create(:variant, name: "Única")
      other = build(:variant, name: "Única")
      expect(other).to be_valid
    end

    it "requires stock" do
      variant = build(:variant, stock: nil)
      expect(variant).not_to be_valid
      expect(variant.errors[:stock]).to include("El stock no puede estar vacío.")
    end

    it "rejects negative stock" do
      variant = build(:variant, stock: -1)
      expect(variant).not_to be_valid
      expect(variant.errors[:stock]).to include("El stock no puede ser negativo.")
    end

    it "rejects non-numeric stock" do
      variant = build(:variant, stock: "abc")
      expect(variant).not_to be_valid
      expect(variant.errors[:stock]).to include("El stock debe ser un número.")
    end

    it "rejects fractional stock" do
      variant = build(:variant, stock: "3.5")
      expect(variant).not_to be_valid
      expect(variant.errors[:stock]).to include("El stock debe ser un número entero.")
    end

    it "accepts a variant without price override" do
      variant = build(:variant, price_cents: nil)
      expect(variant).to be_valid
    end

    it "rejects a negative price override" do
      variant = build(:variant, price_cents: -1)
      expect(variant).not_to be_valid
      expect(variant.errors[:price_cents]).to include("El precio no puede ser negativo.")
    end

    it "rejects a non-numeric price override" do
      variant = build(:variant, price_cents: "abc")
      expect(variant).not_to be_valid
      expect(variant.errors[:price_cents]).to include("El precio debe ser un número.")
    end

    it "rejects a fractional price override" do
      variant = build(:variant, price_cents: "9900.5")
      expect(variant).not_to be_valid
      expect(variant.errors[:price_cents]).to include("El precio debe ser un número entero.")
    end
  end

  describe "#available?" do
    it "is available with stock" do
      expect(build(:variant, stock: 3)).to be_available
    end

    it "is unavailable without stock" do
      expect(build(:variant, stock: 0)).not_to be_available
    end
  end

  describe "#effective_price_cents" do
    it "uses the product price when there is no override" do
      product = create(:product, price_cents: 2500)
      variant = build(:variant, product: product, price_cents: nil)
      expect(variant.effective_price_cents).to eq(2500)
    end

    it "uses the variant price when it is overridden" do
      product = create(:product, price_cents: 2500)
      variant = build(:variant, product: product, price_cents: 9900)
      expect(variant.effective_price_cents).to eq(9900)
    end

    it "treats zero as an explicit override, not as a missing one" do
      product = create(:product, price_cents: 2500)
      variant = build(:variant, product: product, price_cents: 0)
      expect(variant.effective_price_cents).to eq(0)
    end
  end
end
