FactoryBot.define do
  factory :product, class: "Catalog::Product" do
    category
    sequence(:name) { |n| "Product #{n}" }
    description { "Handmade decoration piece." }
    price_cents { 4500 }
  end
end
