require "rails_helper"

RSpec.describe "Catalog demo seeds" do
  def load_seeds_twice
    Rails.application.load_seed
    Rails.application.load_seed
  end

  it "creates categories, products and variants idempotently" do
    load_seeds_twice

    expect(Catalog::Category.count).to eq(4)
    expect(Catalog::Product.count).to eq(8)
    expect(Catalog::Variant.count).to eq(13)
  end

  it "attaches the demo photos without duplicating them" do
    load_seeds_twice

    vase = Catalog::Product.find_by(name: "Jarrón de cerámica")
    expect(vase.images.count).to eq(1)
    expect(vase.images.first.filename.to_s).to eq("sample-vase.jpg")
  end

  it "creates both available and unavailable products" do
    load_seeds_twice

    expect(Catalog::Product.find_by(name: "Jarrón de cerámica")).to be_available
    expect(Catalog::Product.find_by(name: "Funda de algodón")).not_to be_available
  end
end
