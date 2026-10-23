class PasswordsController < ApplicationController
  def new
  end

  def create
    Passwords::RequestReset.call(email: params[:email])
    redirect_to new_password_path, notice: I18n.t("passwords.flash.sent")
  end

  def edit
    @token = params[:token]
    token_record = PasswordResetToken.find_active_by_plaintext(@token)

    if token_record.nil?
      redirect_to new_password_path, alert: I18n.t("passwords.flash.invalid_token")
    else
      @user = token_record.user
    end
  end

  def update
    @user = Passwords::Reset.call(
      plaintext: params[:token],
      password: password_params[:password],
      password_confirmation: password_params[:password_confirmation]
    )

    if @user.nil?
      redirect_to new_password_path, alert: I18n.t("passwords.flash.invalid_token")
    elsif @user.errors.any?
      @token = params[:token]
      render :edit, status: :unprocessable_content
    else
      redirect_to login_path, notice: I18n.t("passwords.flash.reset_success")
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
