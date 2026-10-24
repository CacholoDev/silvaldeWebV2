module Auth
  # Encapsulates the read queries of the authentication domain. Use-case
  # services (Authenticate, Register, RequestReset, Reset) and controllers
  # delegate their lookups here instead of querying models directly.
  class Search
    # Finds an active session by its plaintext token (from the cookie).
    def self.find_session_by_plaintext(plaintext)
      return nil if plaintext.blank?

      Session.active.find_by(token_digest: Session.digest_for(plaintext))
    end

    # Finds an active password reset token by its plaintext (from an email link).
    def self.find_active_password_reset_token(plaintext)
      return nil if plaintext.blank?

      PasswordResetToken.active.find_by(token_digest: PasswordResetToken.digest_for(plaintext))
    end

    # Finds a user by email (login, signup and password reset lookups).
    def self.find_user_by_email(email)
      return nil if email.blank?

      Users::User.find_by(email: email)
    end

    # Authenticates a user by email and password, or nil when invalid.
    def self.authenticate(email:, password:)
      Users::User.authenticate_by(email: email, password: password)
    end
  end
end
