module Auth
  class SessionsController < ApplicationController
    # Brute force protection: 10 login attempts per IP every 3 minutes.
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to login_path, alert: I18n.t("authentication.flash.rate_limited") }

    def new
    end

    def create
      user = Authenticate.call(email: params[:email], password: params[:password])

      if user
        start_new_session_for user
        merge_current_cart_into(user)
        redirect_to root_path, notice: I18n.t("authentication.flash.signed_in")
      else
        redirect_to login_path, alert: I18n.t("authentication.flash.invalid_credentials")
      end
    end

    def destroy
      terminate_session
      redirect_to root_path, notice: I18n.t("authentication.flash.signed_out")
    end
  end
end
