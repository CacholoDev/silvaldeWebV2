class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :ip_address, :user_agent

  def user_signed_in?
    user.present?
  end
end
