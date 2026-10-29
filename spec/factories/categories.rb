FactoryBot.define do
  factory :category, class: "Catalog::Category" do
    sequence(:name) { |n| "Category #{n}" }
  end
end
