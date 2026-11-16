class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true, index: false
      t.references :variant, null: false, foreign_key: true, index: false
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false

      t.timestamps
    end

    # One line per variant per order: the same variant never appears twice.
    add_index :order_items, [ :order_id, :variant_id ], unique: true

    # Defence in depth: the model validations are the first line, but the
    # database also refuses out-of-range quantities and negative prices.
    # 999 matches Orders::OrderItem::MAX_QUANTITY.
    add_check_constraint :order_items, "quantity >= 1 AND quantity <= 999",
                         name: "order_items_quantity_range"
    add_check_constraint :order_items, "unit_price_cents >= 0",
                         name: "order_items_unit_price_cents_non_negative"
  end
end
