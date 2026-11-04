module Carts
  # A line of a cart: one variant, a quantity and the unit price frozen at the
  # moment it was added (a later catalog price change never rewrites it).
  class CartItem < ApplicationRecord
    self.table_name = "cart_items"

    # Upper bound so crafted input cannot overflow the DB integer column.
    MAX_QUANTITY = 999

    # touch: true keeps the cart's last activity fresh for the expiry rules.
    belongs_to :cart, inverse_of: :cart_items, touch: true
    belongs_to :variant, class_name: "Catalog::Variant"

    validates :quantity, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1,
                                         less_than_or_equal_to: MAX_QUANTITY }, allow_nil: true

    validates :unit_price_cents, presence: true
    validates :unit_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    # One line per variant per cart (the unique index enforces it too).
    validates :variant_id, uniqueness: { scope: :cart_id }

    # Subtotal of this line: the frozen unit price times the quantity.
    def subtotal_cents
      quantity * unit_price_cents
    end
  end
end
