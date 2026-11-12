FactoryBot.define do
  factory :order, class: "Orders::Order" do
    # Guest orders are the default: passing a user makes it an account order.
    user { nil }
    contact_name { "Ana Iglesias" }
    contact_email { "ana@example.com" }
    contact_phone { "600 123 456" }
    pickup_store { "bertamirans" }
    payment_method { "bank_transfer" }
  end
end
