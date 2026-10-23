module Auth
  class Session < ApplicationRecord
    self.table_name = "sessions"

    # Sessions expire after 30 days when the user opts into "remember me",
    # otherwise they expire after 1 day (the cookie is session-only and
    # disappears when the browser closes, but we set a DB-side cap as
    # belt-and-braces).
    REMEMBER_ME_DURATION = 30.days
    DEFAULT_DURATION = 1.day

    belongs_to :user, class_name: "Users::User"

    validates :token_digest, presence: true, uniqueness: true
    validates :expires_at, presence: true

    scope :active, -> { where("expires_at > ?", Time.current) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }

    # Hashes a plaintext token with SHA256 and returns the hex digest.
    # SHA256 is fast and sufficient for opaque session tokens (which
    # already have 256 bits of entropy); we don't need the brute-force
    # resistance that BCrypt provides for passwords.
    def self.digest_for(plaintext)
      Digest::SHA256.hexdigest(plaintext)
    end

    # Creates a new session for the given user, hashing the given
    # plaintext token and returning the [session, plaintext] pair so the
    # caller can put the plaintext into the cookie.
    def self.build_for(user, ip_address: nil, user_agent: nil, remember_me: false)
      plaintext = SecureRandom.urlsafe_base64(32)
      duration = remember_me ? REMEMBER_ME_DURATION : DEFAULT_DURATION
      session = new(
        user: user,
        token_digest: digest_for(plaintext),
        ip_address: ip_address,
        user_agent: user_agent,
        expires_at: duration.from_now
      )
      [ session, plaintext ]
    end

    def expired?
      expires_at.past?
    end

    def active?
      !expired?
    end
  end
end
