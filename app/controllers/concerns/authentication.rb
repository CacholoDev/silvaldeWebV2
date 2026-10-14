module Authentication
  extend ActiveSupport::Concern

  COOKIE_KEY = :session_token

  included do
    before_action :resolve_session_from_cookie
    before_action :require_authentication
    helper_method :current_user, :user_signed_in?
  end

  class_methods do
    # Public controllers (login, signup, password reset, email confirmation)
    # opt out of authentication with skip_authentication.
    def skip_authentication(**opts)
      skip_before_action :require_authentication, **opts
    end
  end

  def current_user
    Current.user ||= User.find_by(id: Current.session&.user_id)
  end

  def user_signed_in?
    Current.user_signed_in?
  end

  def start_new_session_for(user, remember_me: false)
    session_record = Session.start_for!(user, request: request, remember_me: remember_me)
    renew_browser_session
    cookies.signed[COOKIE_KEY] = {
      value: session_record.id,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?,
      expires: session_record.expires_at
    }
    Current.session = session_record
    Current.user = user
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(COOKIE_KEY)
    renew_browser_session
    Current.user = nil
    Current.session = nil
  end

  def require_authentication
    return if current_user.present?

    redirect_to login_path, alert: I18n.t("authentication.flash.sign_in_required")
  end

  private

  def resolve_session_from_cookie
    return Current.session if Current.session.present?

    raw = cookies.signed[COOKIE_KEY]
    return nil if raw.blank?

    record = Session.active.find_by(id: raw)
    if record.nil?
      cookies.delete(COOKIE_KEY)
      return nil
    end

    Current.session = record
    Current.user = record.user
  end

  def renew_browser_session
    request.session_options[:renew] = true
  end
end
