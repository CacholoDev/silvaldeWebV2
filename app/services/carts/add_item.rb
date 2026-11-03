module Carts
  # Adds a variant to a cart, the use case behind "add to cart".
  #
  # The first add of a guest creates the cart (owned by `user` when given,
  # guest otherwise). The line's unit price is frozen from the variant at add
  # time (Catalog::Variant#effective_price_cents): later catalog price changes
  # never rewrite it. A variant already in the cart sums the quantities
  # (2 + 1 = 3) — one line per variant, as the unique index enforces too.
  #
  # Returns the CartItem. When the resulting line is invalid (for example a
  # quantity below 1) nothing is persisted and the item carries the errors.
  # `quantity` must be an Integer; controllers coerce form input at the edge.
  class AddItem
    def self.call(cart:, variant:, quantity: 1, user: nil)
      item = nil

      ActiveRecord::Base.transaction do
        target_cart = cart || Cart.create!(user: user)

        item = Search.find_item_by_variant(target_cart, variant) ||
               target_cart.cart_items.build(variant: variant, unit_price_cents: variant.effective_price_cents)
        if item.new_record?
          item.quantity = quantity
        else
          item.quantity += quantity
        end

        raise ActiveRecord::Rollback unless item.save
      end

      item
    end
  end
end
