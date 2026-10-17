FactoryBot.define do
  factory :session do
    user
    token_digest { Session.digest_for(SecureRandom.urlsafe_base64(32)) }
    ip_address { "127.0.0.1" }
    user_agent { "RSpec" }
    expires_at { 1.day.from_now }
  end
end
