module Auth
  class Authenticate
    # Returns the matching User for valid credentials, or nil otherwise.
    def self.call(email:, password:)
      Users::User.authenticate_by(email: email, password: password)
    end
  end
end
