module Auth
  class RegistrationsController < ApplicationController
    # Spam protection: 5 sign-ups per IP every hour.
    rate_limit to: 5, within: 1.hour, only: :create,
               with: -> { redirect_to signup_path, alert: I18n.t("authentication.flash.rate_limited") }

    def new
      @user = Users::User.new
    end

    def create
      @user = Register.call(user_params)

      if @user.persisted?
        start_new_session_for @user
        merge_current_cart_into(@user)
        redirect_to root_path, notice: I18n.t("authentication.flash.signed_up")
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :communications_consent)
    end
  end
end
