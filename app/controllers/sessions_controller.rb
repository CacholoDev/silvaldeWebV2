class SessionsController < ApplicationController
  layout "auth"
  skip_authentication only: %i[new create]

  def new
    redirect_to(root_path) and return if user_signed_in?

    @email = params[:email_address]
  end

  def create
    redirect_to(root_path) and return if user_signed_in?

    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      unless user.confirmed?
        redirect_to login_path, alert: I18n.t("authentication.flash.confirmation_required")
        return
      end

      start_new_session_for(user, remember_me: params[:remember_me] == "1")
      redirect_to root_path, notice: I18n.t("authentication.flash.signed_in")
    else
      flash.now[:alert] = I18n.t("authentication.flash.invalid_credentials")
      @email = params[:email_address]
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: I18n.t("authentication.flash.signed_out")
  end
end
