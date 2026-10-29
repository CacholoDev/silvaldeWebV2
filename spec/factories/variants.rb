FactoryBot.define do
  factory :variant, class: "Catalog::Variant" do
    product
    sequence(:name) { |n| "Variant #{n}" }
    stock { 10 }
  end
end
