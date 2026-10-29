# Demo catalog data for development, tests and manual exploration.
#
# Idempotent: safe to run repeatedly with `bin/rails db:seed` (records are
# looked up by name and never overwritten). Names and descriptions are user
# visible content, so they are written in the shop's language (Spanish);
# code identifiers stay in English. Demo photos live in db/seeds/images/;
# real product photos are uploaded later through the admin forms.

vases = Catalog::Category.find_or_create_by!(name: "Jarrones y cerámica")
candles = Catalog::Category.find_or_create_by!(name: "Velas y fragancias")
decor = Catalog::Category.find_or_create_by!(name: "Espejos y pared")
textiles = Catalog::Category.find_or_create_by!(name: "Textil")

demo_products = [
  {
    category: vases,
    name: "Jarrón de cerámica",
    description: "Jarrón de cerámica hecho a mano con esmalte mate.",
    price_cents: 4500,
    photo: "sample-vase.jpg",
    variants: [ { name: "Única", stock: 3 } ]
  },
  {
    category: vases,
    name: "Maceta de barro",
    description: "Maceta rústica de barro, cada pieza es ligeramente distinta.",
    price_cents: 3200,
    variants: [
      { name: "Pequeña", stock: 5 },
      { name: "Grande", stock: 2, price_cents: 3900 }
    ]
  },
  {
    category: candles,
    name: "Vela aromática",
    description: "Vela de cera de soja con 30 horas de combustión.",
    price_cents: 1200,
    photo: "sample-candle.png",
    variants: [
      { name: "Lavanda", stock: 12 },
      { name: "Vainilla", stock: 8 }
    ]
  },
  {
    category: candles,
    name: "Set de velas pilar",
    description: "Set de tres velas pilar sin perfume.",
    price_cents: 2400,
    variants: [
      { name: "Única", stock: 6 },
      { name: "Pack de 4", stock: 4, price_cents: 1800 }
    ]
  },
  {
    category: decor,
    name: "Espejo redondo de pared",
    description: "Espejo redondo con fino marco de latón.",
    price_cents: 8900,
    photo: "sample-mirror.webp",
    variants: [ { name: "Única", stock: 2 } ]
  },
  {
    category: decor,
    name: "Decoración de madera",
    description: "Panel de madera tallada para paredes de salón.",
    price_cents: 5600,
    variants: [ { name: "Única", stock: 4 } ]
  },
  {
    category: textiles,
    name: "Manta de lino",
    description: "Manta suave de lino lavado para sofás y camas.",
    price_cents: 3500,
    variants: [
      { name: "Gris", stock: 5 },
      { name: "Beige", stock: 0 }
    ]
  },
  {
    category: textiles,
    name: "Funda de algodón",
    description: "Funda de cojín de algodón con cremallera oculta.",
    price_cents: 1800,
    variants: [
      { name: "Blanco", stock: 0 },
      { name: "Gris", stock: 0 }
    ]
  }
]

demo_products.each do |attributes|
  photo = attributes.delete(:photo)
  variants_attributes = attributes.delete(:variants)

  product = Catalog::Product.find_or_create_by!(
    category: attributes[:category], name: attributes[:name]
  ) do |item|
    item.description = attributes[:description]
    item.price_cents = attributes[:price_cents]
  end

  variants_attributes.each do |variant_attributes|
    Catalog::Variant.find_or_create_by!(product: product, name: variant_attributes[:name]) do |item|
      item.stock = variant_attributes[:stock]
      item.price_cents = variant_attributes[:price_cents]
    end
  end

  if photo && !product.images.attached?
    path = Rails.root.join("db/seeds/images", photo)
    product.images.attach(io: File.open(path), filename: photo)
  end
end
