module Auth
  class RegistrationsController < ApplicationController
    def new
      @user = Users::User.new
    end

    def create
      @user = Register.call(user_params)

      if @user.persisted?
        start_new_session_for @user
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
