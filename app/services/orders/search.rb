module Orders
  class Search
    def self.orders_for(user)
      Order.where(user: user).order(created_at: :desc)
    end

    def self.items_for(order)
      OrderItem.where(order: order)
    end

    # Total of the order in cents, computed from its lines (the prices are
    # frozen in the lines themselves).
    def self.total_cents(order)
      items_for(order).sum { |item| item.subtotal_cents }
    end

    def self.find_order_by_number(number)
      return nil if number.blank?

      Order.find_by(number: number)
    end

    def self.find_order_by_signed_token(token)
      return nil if token.blank?

      Order.find_signed(token)
    end
  end
end
