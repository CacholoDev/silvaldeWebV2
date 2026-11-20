FactoryBot.define do
  factory :order_item, class: "Orders::OrderItem" do
    order
    variant
    quantity { 1 }
    unit_price_cents { variant&.effective_price_cents || 1000 }
  end
end
