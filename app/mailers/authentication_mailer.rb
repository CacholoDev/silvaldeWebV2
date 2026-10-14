class AuthenticationMailer < ApplicationMailer
  def confirmation(user, token)
    @user = user
    @confirmation_url = email_confirmation_url(user_id: user.id, token: token, host: default_url_options[:host])
    mail to: user.email_address, subject: I18n.t("mailers.authentication.confirmation.subject")
  end

  def password_reset(user, token)
    @user = user
    @reset_url = edit_password_url(user_id: user.id, token: token, host: default_url_options[:host])
    mail to: user.email_address, subject: I18n.t("mailers.authentication.password_reset.subject")
  end

  private

  def default_url_options
    Rails.application.config.action_mailer.default_url_options || {}
  end
end
