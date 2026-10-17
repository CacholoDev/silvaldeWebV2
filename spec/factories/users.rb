FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "secret123" }
    password_confirmation { "secret123" }
  end
end
