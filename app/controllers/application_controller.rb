class ApplicationController < ActionController::Base
  include Authentication
  include CurrentCart

  # Only allow modern browsers supporting webp images, web push, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale
  before_action :load_categories
  before_action :load_cart_counter

  private

  # Resolve the UI locale from the user's explicit choice (stored in a cookie
  # by LocalesController). Falls back to the default locale when missing or
  # unsupported.
  def set_locale
    requested = cookies[:locale].presence_in(I18n.available_locales.map(&:to_s))
    I18n.locale = requested ? requested.to_sym : I18n.default_locale
  end

  # Load the catalog categories for the footer, which is rendered on every
  # page. Views never query the database: the lookup is delegated to
  # Catalog::Search here, in the controller layer.
  def load_categories
    @categories = Catalog::Search.categories
  end

  # Units in the shopping cart for the header counter (zero when there is no
  # cart yet). The lookup is delegated to Carts::Search, like every read.
  def load_cart_counter
    @cart_item_count = current_cart ? Carts::Search.total_quantity(current_cart) : 0
  end
end
