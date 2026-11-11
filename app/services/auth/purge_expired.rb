module Auth
  # Deletes the authentication records that can never be used again: expired
  # sessions and used or expired password reset tokens. Without it both
  # tables grow forever. Quiet by design: with nothing to purge it returns
  # zeros. Returns how many rows it deleted per table.
  class PurgeExpired
    def self.call
      {
        sessions: Search.expired_sessions.delete_all,
        password_reset_tokens: Search.stale_password_reset_tokens.delete_all
      }
    end
  end
end
