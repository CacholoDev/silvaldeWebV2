FactoryBot.define do
  factory :password_reset_token do
    user
    token_digest { BCrypt::Password.create(SecureRandom.urlsafe_base64(32)) }
    expires_at { 15.minutes.from_now }
  end
end
