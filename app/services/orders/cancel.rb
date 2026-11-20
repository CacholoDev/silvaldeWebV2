module Orders
  # Cancels an order before it is prepared or shipped and puts its stock back
  # on the shelf — the use case behind "cancel order".
  #
  # One transaction, all or nothing: locks the order, returns the stock of
  # every line under its own lock, moves the state machine to cancelled and
  # records the move in the status history. If anything fails midway nothing
  # is persisted, not even when the caller swallows the error.
  #
  # Cancelling is only legal from pending or confirmed; anything else raises
  # AASM::InvalidTransition. The refusal is loud on purpose (no caller
  # can ignore it): callers that show the action check order.may_cancel?
  # first. Returns the Order, now cancelled.
  class Cancel
    def self.call(order:, user: nil)
      ActiveRecord::Base.transaction(requires_new: true) do
        # with_lock reloads the order under FOR UPDATE: a stale, concurrent
        # cancellation sees state "cancelled" and AASM refuses it, so the
        # stock is never returned twice.
        order.with_lock do
          from_state = order.state
          order.cancel!
          restore_stock(order)
          StatusChange.create!(order: order, from_state: from_state, to_state: "cancelled",
                               user: user, manual: false)
        end
      end

      order
    end

    # Puts the stock of every line back under its lock, in the same fixed
    # order as Orders::Checkout.deduct_stock (variant id): a cancellation
    # racing a checkout over shared variants can never deadlock waiting for
    # each other.
    def self.restore_stock(order)
      Orders::Search.items_for(order).sort_by(&:variant_id).each do |item|
        item.variant.with_lock do
          item.variant.update!(stock: item.variant.stock + item.quantity)
        end
      end
    end
  end
end
