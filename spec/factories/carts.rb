FactoryBot.define do
  factory :cart, class: "Carts::Cart" do
    user { nil }

    trait :with_user do
      user
    end
  end
end
