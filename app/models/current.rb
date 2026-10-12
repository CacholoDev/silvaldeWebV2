class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session

  def user_signed_in?
    user.present?
  end
end
