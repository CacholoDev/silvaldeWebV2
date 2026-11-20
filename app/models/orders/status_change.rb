module Orders
  # One row per state change of an order: where it came from, where it went,
  # who moved it (nil = the system, e.g. a pay-in-store order being born
  # confirmed) and when. A forced move through the admin master key (which
  # may move any state by hand but never cancel an already delivered or
  # picked-up order) is flagged as manual. The services record these rows;
  # see docs/roadmap.md.
  class StatusChange < ApplicationRecord
    self.table_name = "order_status_changes"

    belongs_to :order, inverse_of: :status_changes
    belongs_to :user, class_name: "Users::User", optional: true

    validates :to_state, presence: true
    validates :to_state, inclusion: { in: Orders::Order::STATES }, allow_nil: true

    validates :from_state, inclusion: { in: Orders::Order::STATES }, allow_nil: true

    # The system moved it: no user is behind the change.
    def automatic?
      user_id.nil?
    end
  end
end
