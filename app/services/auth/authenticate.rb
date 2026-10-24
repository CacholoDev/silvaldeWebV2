module Auth
  class Authenticate
    # Returns the matching User for valid credentials, or nil otherwise.
    def self.call(email:, password:)
      Search.authenticate(email: email, password: password)
    end
  end
end
