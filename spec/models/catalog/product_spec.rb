require "rails_helper"

RSpec.describe Catalog::Product, type: :model do
  describe "validations" do
    subject { build(:product) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      product = build(:product, name: nil)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to include("El nombre no puede estar vacío.")
    end

    it "enforces maximum length on name (150)" do
      product = build(:product, name: "a" * 151)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to include("El nombre es demasiado largo (máximo 150 caracteres).")
    end

    it "enforces unique name (case insensitive)" do
      create(:product, name: "Vela aromática")
      duplicate = build(:product, name: "vela aromática")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("Ese nombre ya está en uso.")
    end

    it "requires a description" do
      product = build(:product, description: nil)
      expect(product).not_to be_valid
      expect(product.errors[:description]).to include("La descripción no puede estar vacía.")
    end

    it "requires a price" do
      product = build(:product, price_cents: nil)
      expect(product).not_to be_valid
      expect(product.errors[:price_cents]).to include("El precio no puede estar vacío.")
    end

    it "rejects a negative price" do
      product = build(:product, price_cents: -1)
      expect(product).not_to be_valid
      expect(product.errors[:price_cents]).to include("El precio no puede ser negativo.")
    end
  end

  describe "slug" do
    it "generates the slug from the name" do
      product = create(:product, name: "Jarrón artesanal")
      expect(product.slug).to eq("jarron-artesanal")
    end

    it "enforces unique slug" do
      create(:product, name: "Vela", slug: "vela")
      duplicate = build(:product, name: "Vela grande", slug: "vela")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("Ese slug ya está en uso.")
    end
  end

  describe "category" do
    it "requires a category" do
      product = build(:product, category: nil)
      expect(product).not_to be_valid
      expect(product.errors[:category]).to include("La categoría no puede estar vacía.")
    end
  end

  describe "variants" do
    it "has many variants" do
      product = create(:product)
      variant = create(:variant, product: product)
      expect(product.variants).to contain_exactly(variant)
    end

    it "destroys its variants with it" do
      product = create(:product)
      variant = create(:variant, product: product)
      expect { product.destroy }.to change { Catalog::Variant.count }.by(-1)
    end
  end

  describe "availability" do
    it "is unavailable without variants" do
      product = create(:product)
      expect(product).not_to be_available
    end

    it "is available when at least one variant has stock" do
      product = create(:product)
      create(:variant, product: product, stock: 0)
      create(:variant, product: product, stock: 3)
      expect(product).to be_available
    end

    it "is unavailable when every variant is out of stock" do
      product = create(:product)
      create(:variant, product: product, stock: 0)
      expect(product).not_to be_available
    end
  end
end
