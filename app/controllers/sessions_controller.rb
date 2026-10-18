class SessionsController < ApplicationController
  include Authentication

  def new
  end

  def create
    user = Users::Authenticate.call(email: params[:email], password: params[:password])

    if user
      start_new_session_for user
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
