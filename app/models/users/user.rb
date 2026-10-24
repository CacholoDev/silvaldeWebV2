module Users
  class User < ApplicationRecord
    self.table_name = "users"

    # Keep the model name as "User" (not "Users::User") so the i18n keys
    # (activerecord.errors.models.user.*) and form params (user[...]) stay clean.
    def self.model_name
      ActiveModel::Name.new(self, nil, "User")
    end

    has_secure_password

    enum :role, { customer: 0, admin: 1 }, default: :customer

    # Normalize email to lowercase so uniqueness and lookups are
    # case-insensitive at the application layer (MySQL's default
    # utf8mb4_0900_ai_ci collation already handles this for the
    # unique index, but normalizing avoids relying on collation).
    normalizes :email, with: ->(email) { email.strip.downcase }

    EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
    EMAIL_MAX_LENGTH = 255
    NAME_MAX_LENGTH = 100
    PASSWORD_MIN_LENGTH = 8

    validates :email,
              presence: true,
              format: { with: EMAIL_FORMAT },
              length: { maximum: EMAIL_MAX_LENGTH },
              uniqueness: { case_sensitive: false }

    validates :name,
              presence: true,
              length: { maximum: NAME_MAX_LENGTH }

    # Minimum length on creation and password changes; blank keeps profile
    # updates (without a password) working. The 72-byte cap is bcrypt's and
    # is enforced by has_secure_password.
    validates :password,
              length: { minimum: PASSWORD_MIN_LENGTH },
              allow_blank: true
  end
end
