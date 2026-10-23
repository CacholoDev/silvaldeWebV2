module Passwords
  class Reset
    # Resets the user's password using a valid reset token.
    # Returns the user (with errors when the password is invalid), or
    # nil when the token is invalid/expired/used.
    def self.call(plaintext:, password:, password_confirmation:)
      token = PasswordResetToken.find_active_by_plaintext(plaintext)
      return nil if token.nil?

      user = token.user
      if user.update(password: password, password_confirmation: password_confirmation)
        token.mark_used!
      end
      user
    end
  end
end
