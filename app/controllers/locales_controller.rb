class LocalesController < ApplicationController
  def update
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s))
    cookies[:locale] = locale if locale
    redirect_back(fallback_location: root_path)
  end
end
