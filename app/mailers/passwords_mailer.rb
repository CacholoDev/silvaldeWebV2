class PasswordsMailer < ApplicationMailer
  def reset
    @user = params[:user]
    @token = params[:token]
    mail(to: @user.email, subject: I18n.t("passwords.mailer.subject"))
  end
end
