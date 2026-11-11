module Carts
  # Merges a guest cart into the user's cart after login. Variants already in
  # the user's cart sum their quantities (2 + 1 = 3) keeping the user's frozen
  # price; the guest-only lines move over with their own frozen price; the
  # guest cart is destroyed.
  #
  # A cart owned by ANOTHER user is never touched (shared computers): only
  # guest carts merge. Returns the cart the session must use afterwards (the
  # user's cart, which may be nil).
  class Merge
    def self.call(user:, cart:)
      target = Search.find_cart_for_user(user)
      return cart if cart&.user_id == user.id
      return target if cart.nil? || cart.user_id.present?

      if target.nil?
        cart.update!(user: user)
        return cart
      end

      ActiveRecord::Base.transaction do
        cart.cart_items.each do |line|
          existing = Search.find_item_by_variant(target, line.variant)
          if existing
            # Two carts can each be near the per-line maximum; merging them
            # must not fail the login, so the sum is capped at the maximum.
            existing.update!(quantity: [ existing.quantity + line.quantity, CartItem::MAX_QUANTITY ].min)
          else
            line.update!(cart: target)
          end
        end

        # The moves above leave stale membership in the loaded cart_items
        # cache; without this reset, destroying the cart would destroy the
        # moved lines too (dependent: :destroy walks the cached children).
        cart.cart_items.reset
        cart.destroy!
      end

      target
    end
  end
end
