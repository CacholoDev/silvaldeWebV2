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

  describe ".products_on_offer" do
    it "returns products with a variant priced below the product price" do
      producto = create(:product, name: "Set de velas", price_cents: 2400)
      create(:variant, product: producto, name: "Pack de 4", price_cents: 1800)

      expect(described_class.products_on_offer).to contain_exactly(producto)
    end

    it "ignores variants priced above the product price" do
      producto = create(:product, name: "Maceta de barro", price_cents: 3200)
      create(:variant, product: producto, name: "Grande", price_cents: 3900)

      expect(described_class.products_on_offer).to be_empty
    end
  end

  describe ".products_with_photos" do
    it "returns only products with at least one photo" do
      con_foto = create(:product, name: "Jarrón de cerámica")
      con_foto.images.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/images/red-square.jpg")),
        filename: "red-square.jpg"
      )
      create(:product, name: "Vela de soja")

      expect(described_class.products_with_photos).to contain_exactly(con_foto)
    end
  end

  describe ".categories" do
    it "returns every category ordered by name" do
      segundo = create(:category, name: "Velas")
      primero = create(:category, name: "Jarrones")

      expect(described_class.categories).to eq([ primero, segundo ])
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

  describe ".product_by_slug!" do
    it "finds the product for its public URL" do
      producto = create(:product, name: "Jarrón artesanal")

      expect(described_class.product_by_slug!("jarron-artesanal")).to eq(producto)
    end

    it "raises RecordNotFound for an unknown slug" do
      expect { described_class.product_by_slug!("no-existe") }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".category_by_slug!" do
    it "finds the category for its public URL" do
      category = create(:category, name: "Jarrones de cristal")

      expect(described_class.category_by_slug!("jarrones-de-cristal")).to eq(category)
    end

    it "raises RecordNotFound for an unknown slug" do
      expect { described_class.category_by_slug!("no-existe") }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
