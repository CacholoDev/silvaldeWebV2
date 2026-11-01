FactoryBot.define do
  factory :cart_item, class: "Carts::CartItem" do
    cart
    variant
    quantity { 1 }
    unit_price_cents { variant&.effective_price_cents || 1000 }
  end
end
