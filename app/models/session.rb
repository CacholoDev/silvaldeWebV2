class Session < ApplicationRecord
  belongs_to :user

  # Lifetimes: 1 day without "remember me", 30 days with it.
  DEFAULT_LIFETIME = 1.day
  REMEMBER_ME_LIFETIME = 30.days

  scope :active, -> { where("expires_at > ?", Time.current) }

  before_validation :set_default_expiration, on: :create

  def self.start_for!(user, request:, remember_me: false)
    lifetime = remember_me ? REMEMBER_ME_LIFETIME : DEFAULT_LIFETIME
    create!(
      user: user,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      expires_at: lifetime.from_now
    )
  end

  def self.prune_expired!
    where("expires_at <= ?", Time.current).delete_all
  end

  def expired?
    expires_at <= Time.current
  end

  private

  def set_default_expiration
    self.expires_at ||= DEFAULT_LIFETIME.from_now
  end
end
