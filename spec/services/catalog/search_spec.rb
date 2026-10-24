require "rails_helper"

RSpec.describe Catalog::Search do
  describe ".products_matching" do
    it "matches product names regardless of case and accents" do
      jarron = create(:product, name: "Jarrón artesanal")
      create(:product, name: "Vela de soja")

      expect(described_class.products_matching("jarron")).to contain_exactly(jarron)
    end

    it "matches the description too" do
      producto = create(:product, name: "Espejo", description: "Con marco de latón")
      create(:product, name: "Manta", description: "De lino lavado")

      expect(described_class.products_matching("latón")).to contain_exactly(producto)
    end

    it "returns every product for a blank query" do
      create(:product, name: "Jarrón")
      create(:product, name: "Vela")

      expect(described_class.products_matching("").size).to eq(2)
    end

    it "treats LIKE wildcards as literal text" do
      producto = create(:product, name: "Oferta 50%")
      create(:product, name: "Jarrón")

      expect(described_class.products_matching("50%")).to contain_exactly(producto)
      expect(described_class.products_matching("%")).to contain_exactly(producto)
    end
  end

  describe ".products_for_category" do
    it "returns only the products of the category" do
      category = create(:category)
      producto = create(:product, category: category)
      create(:product)

      expect(described_class.products_for_category(category)).to contain_exactly(producto)
    end
  end

  describe ".products" do
    it "preloads the variants to avoid N+1 queries" do
      create(:product)

      first = described_class.products.first

      expect(first.association(:variants)).to be_loaded
    end
  end

  describe ".product_by_slug" do
    it "finds the product for its public URL" do
      producto = create(:product, name: "Jarrón artesanal")

      expect(described_class.product_by_slug("jarron-artesanal")).to eq(producto)
    end

    it "returns nil for an unknown slug" do
      expect(described_class.product_by_slug("no-existe")).to be_nil
    end
  end

  describe ".category_by_slug" do
    it "finds the category for its public URL" do
      category = create(:category, name: "Jarrones de cristal")

      expect(described_class.category_by_slug("jarrones-de-cristal")).to eq(category)
    end

    it "returns nil for an unknown slug" do
      expect(described_class.category_by_slug("no-existe")).to be_nil
    end
  end
end
