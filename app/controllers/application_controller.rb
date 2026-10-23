class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_locale

  private

  # Resolve the UI locale from the user's explicit choice (stored in a cookie
  # by LocalesController). Falls back to the default locale when missing or
  # unsupported.
  def set_locale
    requested = cookies[:locale].presence_in(I18n.available_locales.map(&:to_s))
    I18n.locale = requested ? requested.to_sym : I18n.default_locale
  end
end
