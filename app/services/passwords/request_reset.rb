module Passwords
  class RequestReset
    # Creates a reset token and emails the reset link for the given email.
    # Silently does nothing for unknown emails (avoids account enumeration).
    def self.call(email:)
      user = User.find_by(email: email)
      return unless user

      token, plaintext = PasswordResetToken.build_for(user)
      token.save!
      PasswordsMailer.with(user: user, token: plaintext).reset.deliver_later
    end
  end
end
