module Carts
  # Recurring maintenance job (scheduled in config/recurring.yml): purges the
  # carts that expired after six months without activity. Quiet by design.
  class PurgeExpiredJob < ApplicationJob
    queue_as :default

    def perform
      PurgeExpired.call
    end
  end
end
