class User < ApplicationRecord
  has_secure_password

  # Normalize email to lowercase so uniqueness and lookups are
  # case-insensitive at the application layer (MySQL's default
  # utf8mb4_0900_ai_ci collation already handles this for the
  # unique index, but normalizing avoids relying on collation).
  normalizes :email, with: ->(email) { email.strip.downcase }

  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
  EMAIL_MAX_LENGTH = 255
  NAME_MAX_LENGTH = 100

  validates :email,
            presence: true,
            format: { with: EMAIL_FORMAT },
            length: { maximum: EMAIL_MAX_LENGTH },
            uniqueness: { case_sensitive: false }

  validates :name,
            presence: true,
            length: { maximum: NAME_MAX_LENGTH }
end
