module Users
  class UpdateProfile
    # Updates the user's editable profile fields (name, email, consent).
    # Changing the email requires the current password (the :current_password
    # key of the attributes): otherwise a stolen session cookie would be
    # enough to change the email and then take the account over with a
    # password reset. Returns the user (with errors if invalid or if the
    # password check fails).
    def self.call(user, attributes)
      attributes = attributes.to_h.symbolize_keys
      current_password = attributes.delete(:current_password)
      user.assign_attributes(attributes)

      if user.will_save_change_to_email? && !user.authenticate_password(current_password.to_s)
        user.errors.add(:email, :current_password_invalid)
        return user
      end

      user.save
      user
    end
  end
end
