module Orders
  # "Handed over" — the customer picked the package up in the shop:
  # ready_for_pickup -> picked_up. The money is separate: payment_status
  # still tells whether the order is paid (a pay-in-store customer pays at
  # this very counter and the shop confirms it in v0.6.0).
  #
  # One transaction: locks the order (a stale, concurrent caller sees the
  # fresh state and AASM refuses a repeat), moves the state machine and
  # records the move in the status history. Any other state raises
  # AASM::InvalidTransition and nothing is touched. Returns the Order.
  class MarkPickedUp
    def self.call(order:, user: nil)
      ActiveRecord::Base.transaction(requires_new: true) do
        order.with_lock do
          from_state = order.state
          order.mark_picked_up!
          StatusChange.create!(order: order, from_state: from_state, to_state: "picked_up",
                               user: user, manual: false)
        end
      end

      order
    end
  end
end
