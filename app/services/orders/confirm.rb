module Orders
  # "The payment landed" — the shop reports the bank transfer/Bizum arrived
  # and the order can be prepared (a pay-in-store order is born confirmed and
  # never needs this): pending -> confirmed.
  #
  # One transaction: locks the order (a stale, concurrent caller sees the
  # fresh state and AASM refuses a repeat), moves the state machine and
  # records the move in the status history. An order outside pending raises
  # AASM::InvalidTransition and nothing is touched. Returns the Order.
  class Confirm
    def self.call(order:, user: nil)
      ActiveRecord::Base.transaction(requires_new: true) do
        order.with_lock do
          from_state = order.state
          order.confirm!
          StatusChange.create!(order: order, from_state: from_state, to_state: "confirmed",
                               user: user, manual: false)
        end
      end

      order
    end
  end
end
