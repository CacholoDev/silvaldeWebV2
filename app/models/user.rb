class User < ApplicationRecord
  has_secure_password

  enum :role, { customer: 0, admin: 1 }, default: :customer

  has_many :password_reset_tokens, dependent: :destroy

  before_validation :normalize_email_address

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email_address, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :role, presence: true

  normalizes :email_address, with: ->(value) { value.to_s.strip.downcase }

  # Generates a confirmation token, stores its digest on the user and returns
  # the raw token so the caller can email it. The raw token is never persisted.
  def generate_confirmation_token!
    raw = SecureRandom.urlsafe_base64(32)
    update!(
      confirmation_digest: digest_for(raw),
      confirmation_sent_at: Time.current
    )
    raw
  end

  def confirm_with_token!(raw)
    return false if confirmation_digest.blank?
    return false if !ActiveSupport::SecurityUtils.secure_compare(confirmation_digest, digest_for(raw))

    update!(confirmed_at: Time.current, confirmation_digest: nil)
    true
  end

  def confirmed?
    confirmed_at.present?
  end

  private

  def normalize_email_address
    self.email_address = email_address.to_s.strip.downcase if email_address.present?
  end

  def digest_for(raw)
    OpenSSL::Digest::SHA256.hexdigest(raw)
  end
end
