class LocalesController < ApplicationController
  def update
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s))
    # Remember the choice for a year (a session cookie forgot it when the
    # browser closed). JavaScript never needs it: httponly and same-site.
    cookies[:locale] = { value: locale, expires: 1.year, httponly: true, same_site: :lax } if locale
    redirect_back(fallback_location: root_path)
  end
end
