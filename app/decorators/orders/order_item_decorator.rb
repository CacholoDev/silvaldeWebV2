module Orders
  # Presentation of an order line for the checkout summary: money formatting
  # only (same family as Carts::CartItemDecorator).
  class OrderItemDecorator < ApplicationDecorator
    def formatted_unit_price
      euros(unit_price_cents)
    end

    def formatted_subtotal
      euros(subtotal_cents)
    end
  end
end
