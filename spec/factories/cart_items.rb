FactoryBot.define do
  factory :cart_item, class: "Carts::CartItem" do
    cart
    variant
    quantity { 1 }
  end
end
