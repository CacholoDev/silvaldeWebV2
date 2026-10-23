module Authentication
  extend ActiveSupport::Concern

  COOKIE_KEY = :session_token

  included do
    before_action :resolve_session_from_cookie
    helper_method :current_user, :user_signed_in?
  end

  class_methods do
    # Public controllers (login, signup, password reset) opt out of
    # authentication with `skip_authentication`.
    def require_authentication(**opts)
      before_action :require_authentication, **opts
    end

    def skip_authentication(**opts)
      skip_before_action :require_authentication, **opts
    end
  end

  def current_user
    Current.user ||= Current.session&.user
  end

  def user_signed_in?
    Current.user_signed_in?
  end

  # Creates a new session for the given user, sets the cookie, and
  # populates Current. If remember_me is true, the cookie is persistent
  # (survives browser close) and the DB-side expiration is 30 days.
  # Otherwise the cookie is session-only and the DB-side cap is 1 day.
  def start_new_session_for(user, remember_me: false)
    session_record, plaintext = Session.build_for(
      user,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      remember_me: remember_me
    )
    session_record.save!

    cookie_options = {
      value: plaintext,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }
    if remember_me
      cookies.signed.permanent[COOKIE_KEY] = cookie_options.merge(expires: session_record.expires_at)
    else
      cookies.signed[COOKIE_KEY] = cookie_options
    end

    Current.session = session_record
    Current.user = user
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(COOKIE_KEY)
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

    plaintext = cookies.signed[COOKIE_KEY]
    record = Session.lookup(plaintext)
    if record.nil?
      cookies.delete(COOKIE_KEY)
      return nil
    end

    Current.session = record
    Current.user = record.user
  end
end
