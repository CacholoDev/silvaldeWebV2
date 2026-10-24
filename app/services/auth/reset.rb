module Auth
  class Reset
    # Resets the user's password using a valid reset token.
    #
    # Everything happens in a single transaction: the token is consumed
    # atomically (two concurrent submissions cannot both win), every other
    # outstanding token of the user is invalidated, and all sessions are
    # revoked (a password reset is the remediation for a compromised
    # account, so stolen cookies must stop working).
    #
    # Returns the user (with errors when the password is invalid), or nil
    # when the token is invalid/expired/used.
    def self.call(plaintext:, password:, password_confirmation:)
      token = Search.find_active_password_reset_token(plaintext)
      return nil if token.nil?

      user = token.user
      token_lost = false

      ActiveRecord::Base.transaction do
        consumed = PasswordResetToken.active.where(id: token.id).update_all(used_at: Time.current)
        if consumed != 1
          token_lost = true
          raise ActiveRecord::Rollback
        end

        unless user.update(password: password, password_confirmation: password_confirmation)
          raise ActiveRecord::Rollback
        end

        PasswordResetToken.active.where(user: user).update_all(used_at: Time.current)
        Session.where(user: user).destroy_all
      end

      return nil if token_lost

      user
    end
  end
end
