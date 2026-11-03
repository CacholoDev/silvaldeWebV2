module CurrentCart
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart
  end

  # The cart of this session (guest carts live here), or nil when the session
  # has no cart yet or that cart is gone (missing or expired). It only reads:
  # creating and modifying carts belongs to the Carts:: use-case services.
  def current_cart
    return nil if session[:cart_id].blank?

    Carts::Search.find_active_cart(session[:cart_id])
  end

  # Remembers the cart for the rest of the session (nil forgets it).
  def current_cart=(cart)
    session[:cart_id] = cart&.id
  end
end
