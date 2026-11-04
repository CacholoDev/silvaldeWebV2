module Carts
  # Changes the quantity of a cart line, the use case behind the quantity
  # field of the cart page. The line keeps its frozen unit price, and the save
  # touches the cart (CartItem's touch: true) so the expiry clock restarts.
  #
  # Returns the CartItem, with errors when the quantity is invalid (below 1);
  # in that case the stored quantity is left untouched. `quantity` must be an
  # Integer; controllers coerce form input at the edge.
  class UpdateQuantity
    def self.call(item:, quantity:)
      item.update(quantity: quantity)
      item
    end
  end
end
