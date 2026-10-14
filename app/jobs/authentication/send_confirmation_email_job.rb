class Authentication::SendConfirmationEmailJob < ApplicationJob
  queue_as :default

  def perform(user, token)
    AuthenticationMailer.confirmation(user, token).deliver_now
  end
end
