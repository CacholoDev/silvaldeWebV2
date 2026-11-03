module Carts
  # Removes a line from a cart, the use case behind the "remove" button of
  # the cart page. The destroy touches the cart (CartItem's touch: true) so
  # the expiry clock restarts. Returns the destroyed CartItem.
  class RemoveItem
    def self.call(item:)
      # Destroy through the association: a bare `item.destroy` leaves the
      # destroyed line inside the cart's loaded cart_items cache (ActiveRecord
      # does not evict it), so a caller re-rendering the cart would still see it.
      item.cart.cart_items.destroy(item)
      item
    end
  end
end
