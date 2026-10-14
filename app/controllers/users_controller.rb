class UsersController < ApplicationController
  layout "auth"
  skip_authentication only: %i[new create]

  def new
    redirect_to(root_path) and return if user_signed_in?

    @user = User.new
  end

  def create
    redirect_to(root_path) and return if user_signed_in?

    @user = User.new(user_params)
    @user.role ||= :customer

    if @user.save
      token = @user.generate_confirmation_token!
      Authentication::SendConfirmationEmailJob.perform_later(@user, token)
      redirect_to login_path, notice: I18n.t("authentication.flash.account_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :name, :password, :password_confirmation)
  end
end
