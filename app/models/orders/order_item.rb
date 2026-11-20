module Orders
  # A line of an order: one variant, a quantity and the unit price frozen at
  # the moment the order was placed (a later catalog price change never
  # rewrites it). Mirrors Carts::CartItem, but for a confirmed purchase.
  class OrderItem < ApplicationRecord
    self.table_name = "order_items"

    # Upper bound so crafted input cannot overflow the DB integer column.
    # The CHECK constraint in the migration enforces it at the DB level too.
    MAX_QUANTITY = 999

    belongs_to :order, inverse_of: :order_items
    belongs_to :variant, class_name: "Catalog::Variant"

    validates :quantity, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1,
                                         less_than_or_equal_to: MAX_QUANTITY }, allow_nil: true

    validates :unit_price_cents, presence: true
    validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    # One line per variant per order (the unique index enforces it too).
    validates :variant_id, uniqueness: { scope: :order_id }

    # Subtotal of this line: the frozen unit price times the quantity.
    def subtotal_cents
      quantity * unit_price_cents
    end
  end
end
