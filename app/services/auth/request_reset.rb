module Auth
  class RequestReset
    # Creates a reset token and emails the reset link for the given email.
    # Silently does nothing for unknown emails (avoids account enumeration).
    #
    # Requesting a new link invalidates the user's previous outstanding
    # tokens: only the latest link works, so old emails cannot be replayed.
    def self.call(email:)
      user = Search.find_user_by_email(email)
      return unless user

      PasswordResetToken.active.where(user: user).update_all(used_at: Time.current)

      token, plaintext = PasswordResetToken.build_for(user)
      token.save!
      PasswordsMailer.with(user: user, token: plaintext).reset.deliver_later
    end
  end
end
