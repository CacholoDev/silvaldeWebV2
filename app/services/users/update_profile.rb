module Users
  class UpdateProfile
    # Updates the user's editable profile fields (name, email).
    # Returns the user (with errors if invalid).
    def self.call(user, attributes)
      user.update(attributes)
      user
    end
  end
end
