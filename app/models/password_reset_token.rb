class PasswordResetToken < ApplicationRecord
  belongs_to :user

  EXPIRATION = 15.minutes

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def consume!
    update!(used_at: Time.current)
  end

  def matches?(raw)
    return false if token_digest.blank? || raw.blank?

    ActiveSupport::SecurityUtils.secure_compare(token_digest, digest_for(raw))
  end

  def self.issue_for!(user)
    raw = SecureRandom.urlsafe_base64(32)
    create!(
      user: user,
      token_digest: digest_for(raw),
      expires_at: EXPIRATION.from_now
    )
    raw
  end

  def self.digest_for(raw)
    OpenSSL::Digest::SHA256.hexdigest(raw)
  end

  private

  def digest_for(raw)
    self.class.digest_for(raw)
  end
end
