module Auth
  # Recurring maintenance job (scheduled in config/recurring.yml): deletes
  # expired sessions and stale password reset tokens. Quiet by design.
  class PurgeExpiredJob < ApplicationJob
    queue_as :default

    def perform
      PurgeExpired.call
    end
  end
end
