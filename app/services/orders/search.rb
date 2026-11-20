module Orders
  class Search
    def self.orders_for(user)
      Order.where(user: user).order(created_at: :desc)
    end

    def self.items_for(order)
      OrderItem.where(order: order)
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
