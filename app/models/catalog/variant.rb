module Catalog
  class Variant < ApplicationRecord
    self.table_name = "variants"

    NAME_MAX_LENGTH = 100

    belongs_to :product, inverse_of: :variants

    validates :name,
              presence: true,
              length: { maximum: NAME_MAX_LENGTH },
              uniqueness: { scope: :product_id }

    validates :stock, presence: true
    validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    # Optional price override in cents: nil means "use the product price",
    # any integer (including 0) replaces it.
    validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    def available?
      stock.positive?
    end

    def effective_price_cents
      price_cents.nil? ? product.price_cents : price_cents
    end
  end
end
