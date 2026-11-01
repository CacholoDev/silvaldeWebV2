module Carts
  # Encapsulates the read queries of the cart domain. Use-case services and
  # controllers delegate their lookups here instead of querying models
  # directly (same pattern as Auth::Search and Catalog::Search).
  class Search
    # Carts with activity inside the retention window (Cart::MAX_INACTIVITY).
    def self.active
      Cart.where(updated_at: Cart::MAX_INACTIVITY.ago..)
    end

    # Carts without activity for longer than the retention window.
    def self.expired
      Cart.where.not(updated_at: Cart::MAX_INACTIVITY.ago..)
    end
  end
end
