module Auth
  class Register
    # Builds and persists a User from the given attributes.
    # Returns the User (persisted on success, with errors otherwise).
    def self.call(attributes)
      user = Users::User.new(attributes)
      user.save
      user
    end
  end
end
