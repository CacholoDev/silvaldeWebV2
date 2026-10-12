class Authentication::SendPasswordResetEmailJob < ApplicationJob
  queue_as :default

  def perform(user, token)
    AuthenticationMailer.password_reset(user, token).deliver_now
  end
end
