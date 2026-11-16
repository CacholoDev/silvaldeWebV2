module Carts
  # Presentation of a cart line for the cart page: money formatting only.
  class CartItemDecorator < ApplicationDecorator
    def formatted_unit_price
      euros(variant.effective_price_cents)
    end

    def formatted_subtotal
      euros(subtotal_cents)
    end
  end
end
