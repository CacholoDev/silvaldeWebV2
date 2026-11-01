class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true, index: false
      t.references :variant, null: false, foreign_key: true, index: false
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false

      t.timestamps
    end

    # One line per variant per cart: the same variant never appears twice.
    add_index :cart_items, [ :cart_id, :variant_id ], unique: true
  end
end
