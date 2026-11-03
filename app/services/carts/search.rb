module Carts
  # Encapsulates the read queries of the cart domain. Use-case services and
  # controllers delegate their lookups here instead of querying models
  # directly (same pattern as Auth::Search and Catalog::Search).
  class Search
    # Carts with activity inside the retention window (Cart::MAX_INACTIVITY).
    def self.active
      Cart.where(updated_at: Cart::MAX_INACTIVITY.ago..)
    end

    # The non-expired cart with this id (the session stores just the id), or
    # nil when it is missing or already expired.
    def self.find_active_cart(id)
      active.find_by(id: id)
    end

    # The cart line for a variant, or nil.
    def self.find_item_by_variant(cart, variant)
      cart.cart_items.find_by(variant: variant)
    end

    # Carts without activity for longer than the retention window.
    def self.expired
      Cart.where.not(updated_at: Cart::MAX_INACTIVITY.ago..)
    end
  end
end
