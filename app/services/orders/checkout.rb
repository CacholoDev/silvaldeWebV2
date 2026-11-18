module Orders
  # Converts a cart into an order — the use case behind "place order".
  #
  # One transaction, all or nothing: locks the variants, checks and decrements
  # the stock, creates the order with its lines at the prices frozen at
  # purchase, records its birth in the status history and empties the cart.
  # If anything fails (invalid contact data, a line without enough stock)
  # nothing is persisted and the returned order carries the errors.
  #
  # Returns the Order: persisted on success, an unsaved order with errors on
  # failure. Controllers render that; nothing here raises for expected
  # failures. Unexpected errors do propagate (house rule: no silent rescues).
  class Checkout
    def self.call(cart:, contact_name:, contact_email:, contact_phone: nil,
                  pickup_store:, payment_method:, user: nil)
      order = Order.new(
        contact_name: contact_name, contact_email: contact_email,
        contact_phone: contact_phone, pickup_store: pickup_store,
        payment_method: payment_method, user: user
      )
      lines = cart ? Carts::Search.items_for(cart).to_a : []

      if lines.empty?
        order.errors.add(:base, :cart_empty)
        return order
      end

      # requires_new: true gives the checkout its own transaction (a savepoint
      # when nested) so its rollback undoes its writes even when some other
      # transaction wraps the call — plain `transaction` would join the outer
      # one and swallow the Rollback without undoing anything.
      ActiveRecord::Base.transaction(requires_new: true) do
        missing = deduct_stock(lines)

        if missing.any?
          missing.each { |variant| order.errors.add(:base, :out_of_stock, variant: variant.name) }
          raise ActiveRecord::Rollback
        end

        lines.each do |line|
          order.order_items.build(
            variant: line.variant, quantity: line.quantity,
            unit_price_cents: line.variant.effective_price_cents
          )
        end

        raise ActiveRecord::Rollback unless order.save

        StatusChange.create!(order: order, from_state: nil, to_state: order.state)
        cart.cart_items.destroy_all
      end

      order
    end

    # Checks and decrements the stock of every line under its lock; returns
    # the variants without enough stock (in which case the caller rolls
    # everything back).
    def self.deduct_stock(lines)
      missing = []

      # A fixed lock order (variant id) so two checkouts sharing lines never
      # deadlock waiting for each other. with_lock reloads the row under FOR
      # UPDATE, so the check always sees what concurrent checkouts committed:
      # the last unit is never sold twice.
      lines.sort_by(&:variant_id).each do |line|
        line.variant.with_lock do
          if line.variant.stock < line.quantity
            missing << line.variant
          else
            line.variant.update!(stock: line.variant.stock - line.quantity)
          end
        end
      end

      missing
    end
  end
end
