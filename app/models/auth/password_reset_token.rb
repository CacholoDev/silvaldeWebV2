module Auth
  class PasswordResetToken < ApplicationRecord
    self.table_name = "password_reset_tokens"

    EXPIRATION = 15.minutes

    belongs_to :user, class_name: "Users::User"

    validates :token_digest, presence: true, uniqueness: true
    validates :expires_at, presence: true

    scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }
    scope :used, -> { where.not(used_at: nil) }

    # Hashes a plaintext token with SHA256 and returns the hex digest.
    # SHA256 is fast and sufficient for opaque reset tokens (256 bits of
    # entropy); we don't need BCrypt's brute-force resistance here.
    def self.digest_for(plaintext)
      Digest::SHA256.hexdigest(plaintext)
    end

    def self.build_for(user, plaintext: SecureRandom.urlsafe_base64(32))
      token = new(
        user: user,
        token_digest: digest_for(plaintext),
        expires_at: EXPIRATION.from_now
      )
      [ token, plaintext ]
    end

    def active?
      used_at.nil? && expires_at.future?
    end

    def expired?
      expires_at.past?
    end

    def used?
      used_at.present?
    end

    def mark_used!
      update!(used_at: Time.current)
    end
  end
end
