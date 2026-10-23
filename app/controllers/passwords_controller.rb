class PasswordsController < ApplicationController
  def new
  end

  def create
    Passwords::RequestReset.call(email: params[:email])
    redirect_to new_password_path, notice: I18n.t("passwords.flash.sent")
  end
end
