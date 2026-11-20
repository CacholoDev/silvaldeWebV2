module Orders
  # "The package is packed" — a confirmed pickup order is ready and waiting
  # in the shop: confirmed -> ready_for_pickup. The AASM guard keeps shipping
  # orders out (they travel the shipped/delivered branch of v0.7.0).
  #
  # One transaction: locks the order (a stale, concurrent caller sees the
  # fresh state and AASM refuses a repeat), moves the state machine and
  # records the move in the status history. Any other state raises
  # AASM::InvalidTransition and nothing is touched. Returns the Order.
  class MarkReady
    def self.call(order:, user: nil)
      ActiveRecord::Base.transaction(requires_new: true) do
        order.with_lock do
          from_state = order.state
          order.mark_ready!
          StatusChange.create!(order: order, from_state: from_state, to_state: "ready_for_pickup",
                               user: user, manual: false)
        end
      end

      order
    end
  end
end
