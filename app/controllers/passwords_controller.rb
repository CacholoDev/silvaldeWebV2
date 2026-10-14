class PasswordsController < ApplicationController
  layout "auth"
  skip_authentication

  def new
  end

  def create
    email = params[:email_address].to_s.strip.downcase
    user = User.find_by(email_address: email)

    if user
      token = PasswordResetToken.issue_for!(user)
      Authentication::SendPasswordResetEmailJob.perform_later(user, token)
    end

    # Always render the same response to avoid leaking which emails exist.
    redirect_to login_path, notice: I18n.t("authentication.flash.password_reset_sent")
  end

  def edit
    @user_id = params[:user_id]
    @token = params[:token]
  end

  def update
    user = User.find_by(id: params[:user_id])
    record = user&.password_reset_tokens&.active&.find_by(token_digest: PasswordResetToken.digest_for(params[:token].to_s))

    if record.nil?
      redirect_to new_password_path, alert: I18n.t("authentication.flash.password_reset_invalid")
      return
    end

    if user.update(password_params)
      record.consume!
      # Terminate any other outstanding reset tokens for this user.
      user.password_reset_tokens.active.where.not(id: record.id).destroy_all
      redirect_to login_path, notice: I18n.t("authentication.flash.password_reset_success")
    else
      @user_id = params[:user_id]
      @token = params[:token]
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
