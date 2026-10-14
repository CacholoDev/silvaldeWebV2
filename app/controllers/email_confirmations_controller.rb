class EmailConfirmationsController < ApplicationController
  layout false
  skip_authentication

  def show
    token = params[:token].to_s
    user = User.find_by(id: params[:user_id])

    if user&.confirm_with_token!(token)
      flash[:notice] = I18n.t("authentication.flash.email_confirmed")
    else
      flash[:alert] = I18n.t("authentication.flash.confirmation_invalid")
    end

    redirect_to login_path
  end
end
