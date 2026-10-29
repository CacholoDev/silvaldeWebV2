require "rails_helper"

RSpec.describe Catalog::Category, type: :model do
  describe "validations" do
    subject { build(:category) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      category = build(:category, name: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("El nombre no puede estar vacío.")
    end

    it "enforces maximum length on name (100)" do
      category = build(:category, name: "a" * 101)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("El nombre es demasiado largo (máximo 100 caracteres).")
    end

    it "enforces unique name (case insensitive)" do
      create(:category, name: "Jarrones")
      duplicate = build(:category, name: "jarrones")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("Ese nombre ya está en uso.")
    end
  end

  describe "slug" do
    it "generates the slug from the name" do
      category = create(:category, name: "Jarrones de cristal")
      expect(category.slug).to eq("jarrones-de-cristal")
    end

    it "normalizes a manually provided slug to URL-safe form" do
      category = create(:category, name: "Jarrones", slug: "Jarrones Especiales")
      expect(category.slug).to eq("jarrones-especiales")
    end

    it "keeps the slug stable when the name changes" do
      category = create(:category, name: "Jarrones")
      category.update!(name: "Jarrones bonitos")
      expect(category.slug).to eq("jarrones")
    end

    it "enforces unique slug" do
      create(:category, name: "Jarrones", slug: "jarrones")
      duplicate = build(:category, name: "Jarrones bonitos", slug: "jarrones")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("Ese slug ya está en uso.")
    end

    it "cannot build a slug without a name" do
      category = build(:category, name: nil)
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include("El slug no puede estar vacío.")
    end
  end

  describe "products" do
    it "has many products" do
      category = create(:category)
      product = create(:product, category: category)
      expect(category.products).to contain_exactly(product)
    end

    it "cannot be deleted while it has products" do
      category = create(:category)
      create(:product, category: category)
      expect { category.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end
end
