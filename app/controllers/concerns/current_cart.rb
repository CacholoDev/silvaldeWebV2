module CurrentCart
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart
  end

  # The cart of this session (guest carts live here). A guest only sees guest
  # carts and a signed-in user only their own: a leftover cart from another
  # account in a shared browser is forgotten, never shown nor written to.
  # Signed-in users fall back to their own cart in a fresh browser session
  # (the session cookie dies before the auth cookie does).
  # It only reads: creating and modifying carts belongs to the Carts::
  # use-case services.
  #
  # Memoized per request: the layout, the header counter and the controller
  # all ask for it, and each call used to hit the database. The memo is keyed
  # on the session cart id and the signed-in user, so logging in or out (or
  # anything else that touches session[:cart_id]) resolves the cart again.
  def current_cart
    return @current_cart if @current_cart_key == current_cart_key

    @current_cart = resolve_current_cart
    @current_cart_key = current_cart_key
    @current_cart
  end

  # Remembers the cart for the rest of the session (nil forgets it).
  def current_cart=(cart)
    session[:cart_id] = cart&.id
    @current_cart = cart
    @current_cart_key = current_cart_key
  end

  # After sign in or sign up: merges the guest cart into the user's cart and
  # remembers the resulting one (Carts::Merge does the heavy lifting).
  def merge_current_cart_into(user)
    self.current_cart = Carts::Merge.call(user: user, cart: current_cart)
  end

  private

  def current_cart_key
    [ session[:cart_id], current_user&.id ]
  end

  def resolve_current_cart
    cart = Carts::Search.find_active_cart(session[:cart_id])

    if cart && (cart.user_id.nil? || cart.user_id == current_user&.id)
      return cart
    end

    # The remembered cart is not usable here (another account's, expired or
    # already purged): forget it.
    self.current_cart = nil if session[:cart_id].present?
    return nil unless current_user

    self.current_cart = Carts::Search.find_cart_for_user(current_user)
  end
end
