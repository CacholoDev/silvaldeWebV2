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

    # Total units in the cart (the header counter): the sum of the line
    # quantities, zero for an empty cart.
    def self.total_quantity(cart)
      cart.cart_items.sum(:quantity)
    end

    # The lines of a cart (variant and product preloaded), in insertion order.
    # A nil cart (guest without a cart yet) has no lines.
    def self.items_for(cart)
      return [] if cart.nil?

      cart.cart_items.includes(variant: :product).order(:id)
    end

    # Cart total in cents: the sum of the line subtotals, zero without cart.
    def self.total_cents(cart)
      return 0 if cart.nil?

      cart.cart_items.sum("quantity * unit_price_cents")
    end

    # The line with this id inside the given cart (ownership check), or raises
    # ActiveRecord::RecordNotFound so the controller responds 404.
    def self.find_item_by_id!(cart, id)
      item = cart&.cart_items&.find_by(id: id)
      raise ActiveRecord::RecordNotFound if item.nil?

      item
    end

    # The user's current cart (the most recently active one), or nil.
    def self.find_cart_for_user(user)
      active.where(user: user).order(updated_at: :desc).first
    end

    # Carts without activity for longer than the retention window.
    def self.expired
      Cart.where.not(updated_at: Cart::MAX_INACTIVITY.ago..)
    end
  end
end
