class PasswordResetToken < ApplicationRecord
  EXPIRATION = 15.minutes

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :used, -> { where.not(used_at: nil) }

  # Hashes a plaintext token with BCrypt and stores the digest. The
  # plaintext token is what gets sent in the email; only the digest
  # is persisted, so a leaked database cannot be used to reset
  # arbitrary passwords.
  def self.digest_for(plaintext)
    BCrypt::Password.create(plaintext)
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
